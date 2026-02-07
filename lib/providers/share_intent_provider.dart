import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_intent/receive_intent.dart';

class ShareIntentProvider extends ChangeNotifier {
  // Stream to broadcast newly received shared URLs
  final StreamController<String> _sharedUrlController = StreamController<String>.broadcast();

  Stream<String> get sharedUrlStream => _sharedUrlController.stream;

  // Immediate handlers for shared URLs (useful to avoid timing races)
  final List<void Function(String)> _onUrlHandlers = [];

  /// Register a direct handler that will be invoked when a shared URL is received.
  void addUrlHandler(void Function(String) handler) {
    _onUrlHandlers.add(handler);
    // If a URL is already pending, invoke the handler immediately (schedule to avoid sync reentry)
    if (_sharedUrl != null && _isPending) {
      final url = _sharedUrl!;
      scheduleMicrotask(() {
        try {
          handler(url);
        } catch (_) {}
      });
    }
  }

  /// Remove a previously registered handler.
  void removeUrlHandler(void Function(String) handler) {
    _onUrlHandlers.remove(handler);
  }

  String? _sharedUrl;
  /// Last received shared URL (kept until explicitly cleared). This allows UI
  /// screens that mount after processing to still read and show the received link
  /// in e.g. an input field. Use `clearSharedContent` to fully clear it.
  String? _lastReceivedSharedUrl;
  String? _sharedText;
  bool _isPending = false;
  bool _isProcessing = false;

  // Getters
  String? get sharedUrl => _sharedUrl;
  /// Returns the last received shared URL regardless of pending state.
  String? get lastSharedUrl => _lastReceivedSharedUrl;
  String? get sharedText => _sharedText;
  bool get isPending => _isPending;
  bool get isProcessing => _isProcessing;
  bool get hasSharedContent => _sharedUrl != null || _sharedText != null;

  ShareIntentProvider() {
    _initializeShareIntentListener();
  }

  /// Initialize share intent listener
  Future<void> _initializeShareIntentListener() async {
    try {
      // Get initial intent if app was launched with share
      final receivedIntent = await ReceiveIntent.getInitialIntent();
      if (receivedIntent != null) {
        _processIntent(receivedIntent);
      }

      // Listen for subsequent intents
      ReceiveIntent.receivedIntentStream.listen(
        (receivedIntent) {
          _processIntent(receivedIntent);
        },
        onError: (err) {
          if (kDebugMode) {
            print('Error receiving intent: $err');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize share intent listener: $e');
      }
    }
  }

  /// Process received intent (robust to multiple platform shapes)
  void _processIntent(dynamic receivedIntent) {
    if (receivedIntent == null) return;

    String? action;
    String? text;
    String? data;

    // Try a variety of ways to extract common intent fields. We wrap each in try/catch
    // because the underlying platform Intent proxy may not expose the same members.
    try {
      action = (receivedIntent.action is String) ? receivedIntent.action as String : null;
    } catch (_) {}

    try {
      // Common property that some wrappers expose
      final t = receivedIntent.text;
      if (t is String && t.isNotEmpty) text = t;
    } catch (_) {}

    try {
      final d = receivedIntent.data;
      if (d is String && d.isNotEmpty) data = d;
    } catch (_) {}

    try {
      final ds = receivedIntent.dataString;
      if (ds is String && ds.isNotEmpty) data = data ?? ds;
    } catch (_) {}

    // Some platforms expose extras as a Map or Bundle-like object
    try {
      final extras = receivedIntent.extras;
      if (extras != null) {
        if (extras is Map && extras.isNotEmpty) {
          // Android often places shared text under Intent.EXTRA_TEXT ("android.intent.extra.TEXT")
          if (extras.containsKey('android.intent.extra.TEXT')) {
            final v = extras['android.intent.extra.TEXT'];
            if (v is String && v.isNotEmpty) text = text ?? v;
          }
          if (extras.containsKey('text')) {
            final v = extras['text'];
            if (v is String && v.isNotEmpty) text = text ?? v;
          }
          // EXTRA_STREAM might contain a Uri string
          if (extras.containsKey('android.intent.extra.STREAM')) {
            final stream = extras['android.intent.extra.STREAM'];
            if (stream is String && stream.isNotEmpty) data = data ?? stream;
          }
        }
      }
    } catch (_) {}

    // Try the Android Intent method getStringExtra
    try {
      if (receivedIntent.getStringExtra != null) {
        try {
          final extraText = receivedIntent.getStringExtra('android.intent.extra.TEXT');
          if (extraText is String && extraText.isNotEmpty) text = text ?? extraText;
        } catch (_) {}
      }
    } catch (_) {}

    // Try clipData (Intent.clipData) -> itemAt(0) -> text or uri
    try {
      final clip = receivedIntent.clipData ?? receivedIntent.clip;
      if (clip != null) {
        try {
          // many wrappers expose getItemAt(index) or getItem
          dynamic item;
          if (clip.getItemAt != null) {
            item = clip.getItemAt(0);
          } else if (clip.getItem != null) {
            item = clip.getItem(0);
          } else if (clip.itemCount != null && clip.itemCount > 0) {
            try {
              item = clip.getItemAt(0);
            } catch (_) {}
          }

          if (item != null) {
            try {
              final itemText = item.text;
              if (itemText is String && itemText.isNotEmpty) text = text ?? itemText;
            } catch (_) {}
            try {
              final uri = item.uri ?? item.getUri?.call();
              if (uri is String && uri.isNotEmpty) data = data ?? uri;
            } catch (_) {}
          }
        } catch (_) {}
      }
    } catch (_) {}

    // EXTRA_STREAM fallback
    try {
      if (receivedIntent.getParcelableExtra != null) {
        try {
          final streamExtra = receivedIntent.getParcelableExtra('android.intent.extra.STREAM');
          if (streamExtra is String && streamExtra.isNotEmpty) data = data ?? streamExtra;
        } catch (_) {}
      }
    } catch (_) {}

    // Fallback: try getStringExtra with common extra names
    try {
      final alt = receivedIntent.getStringExtra('text');
      if (alt is String && alt.isNotEmpty) text = text ?? alt;
    } catch (_) {}

    // As a last resort, try toString() to see if there's a URL embedded
    if ((text == null || text.isEmpty) && (data == null || data.isEmpty)) {
      try {
        final s = receivedIntent.toString();
        if (s.isNotEmpty) {
          // attempt to extract URL
          final maybe = _extractUrlFromText(s);
          if (maybe != null) text = maybe;
        }
      } catch (_) {}
    }

    // Prefer text over data for shared links/content
    String? url = text ?? data;

    // Normalize / trim the extracted url to avoid issues with whitespace/newlines
    if (url != null) {
      url = url.trim();
      // If url starts with intent: or similar wrapper, try to extract http(s) substring
      final httpIndex = url.indexOf('http');
      if (httpIndex > 0) {
        url = url.substring(httpIndex);
      }
    }

    if (kDebugMode) {
      // Helpful debug logging when intents arrive so we can iterate if more shapes appear
      print('ShareIntentProvider._processIntent: action=$action, extractedText=${text ?? 'null'}, extractedData=${data ?? 'null'}, chosenUrl=${url ?? 'null'}, intentType=${receivedIntent.runtimeType}');
    }

    if (url != null && _isValidYoutubeUrl(url)) {
      _sharedUrl = url;
      _lastReceivedSharedUrl = url;
      _sharedText = text;
      _isPending = true;
      _isProcessing = false;
      // emit to stream for immediate listeners
      try {
        _sharedUrlController.add(url);
      } catch (_) {}
      // Call any direct handlers (schedule to avoid reentrancy)
      if (_onUrlHandlers.isNotEmpty) {
        scheduleMicrotask(() {
          for (final h in List<void Function(String)>.from(_onUrlHandlers)) {
            try {
              h(url!);
            } catch (_) {}
          }
        });
      }
      notifyListeners();
    }
  }

  /// Extract URL from text
  String? _extractUrlFromText(String text) {
    // Match YouTube URLs
    final urlRegex = RegExp(
      r'(?:https?://)?(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]{11})',
    );
    final match = urlRegex.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }

    // If it starts with http, return as is
    if (text.startsWith('http')) {
      return text;
    }

    return null;
  }

  /// Validate if URL is a YouTube URL
  bool _isValidYoutubeUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('m.youtube.com') ||
        url.contains('music.youtube.com');
  }

  /// Mark share intent as processed
  void markAsProcessed() {
    // Mark as processed but keep last received URL available for UI prefill.
    _isPending = false;
    _isProcessing = false;
    notifyListeners();
  }

  /// Set processing state
  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  /// Clear shared content
  void clearSharedContent() {
    _sharedUrl = null;
    _sharedText = null;
    _lastReceivedSharedUrl = null;
    _isPending = false;
    _isProcessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sharedUrlController.close();
    super.dispose();
  }
}
