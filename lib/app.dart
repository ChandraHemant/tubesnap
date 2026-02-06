import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/themes/app_themes.dart';
import 'config/routes.dart';
import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';
import 'providers/share_intent_provider.dart';
import 'providers/video_provider.dart';

class TubeSnapApp extends StatefulWidget {
  const TubeSnapApp({super.key});

  @override
  State<TubeSnapApp> createState() => _TubeSnapAppState();
}

class _TubeSnapAppState extends State<TubeSnapApp> {
  StreamSubscription<String>? _shareSub;
  String? _lastProcessedSharedUrl;
  void Function(String)? _directUrlHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final sp = Provider.of<ShareIntentProvider>(context, listen: false);
        final vp = Provider.of<VideoProvider>(context, listen: false);
        // Register a direct handler to catch intents immediately
        _directUrlHandler = (String url) {
          if (url.isNotEmpty && _lastProcessedSharedUrl != url) {
            _lastProcessedSharedUrl = url;
            if (kDebugMode) print('TubeSnapApp.urlHandler: received $url');
            scheduleMicrotask(() async {
              try {
                await vp.fetchVideo(url);
                try { sp.markAsProcessed(); } catch (_) {}
                if (kDebugMode) print('TubeSnapApp.urlHandler: fetched $url');
              } catch (e) {
                if (kDebugMode) print('TubeSnapApp.urlHandler: failed to fetch $url: $e');
              }
            });
          }
        };
        try { sp.addUrlHandler(_directUrlHandler!); } catch (_) {}

        _shareSub = sp.sharedUrlStream.listen((url) async {
          if (url.isNotEmpty && _lastProcessedSharedUrl != url) {
            _lastProcessedSharedUrl = url;
            if (kDebugMode) print('TubeSnapApp: received shared url $url');
            try {
              await vp.fetchVideo(url);
              sp.markAsProcessed();
              if (kDebugMode) print('TubeSnapApp: fetchVideo completed for $url');
            } catch (e) {
              if (kDebugMode) print('TubeSnapApp: failed to fetch shared url $url: $e');
            }
          }
        });

        // If an initial intent was already processed by the provider before we
        // subscribed to the stream, handle the pending shared URL now.
        if (sp.isPending && sp.sharedUrl != null && _lastProcessedSharedUrl != sp.sharedUrl) {
          final initialUrl = sp.sharedUrl!;
          _lastProcessedSharedUrl = initialUrl;
          if (kDebugMode) print('TubeSnapApp: handling pending initial shared url $initialUrl');
          vp.fetchVideo(initialUrl).then((_) {
            try {
              sp.markAsProcessed();
            } catch (_) {}
            if (kDebugMode) print('TubeSnapApp: handled pending initial shared url $initialUrl');
          }).catchError((e) {
            if (kDebugMode) print('TubeSnapApp: failed to handle pending initial shared url $initialUrl: $e');
          });
        }
      } catch (e) {
        if (kDebugMode) print('TubeSnapApp init: failed to subscribe to share stream: $e');
      }
    });
  }

  @override
  void dispose() {
    // Remove direct handler
    try { final sp = Provider.of<ShareIntentProvider>(context, listen: false); if (_directUrlHandler != null) sp.removeUrlHandler(_directUrlHandler!); } catch (_) {}
    _shareSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, langProvider, child) {
        return MaterialApp(
          title: 'TubeSnap',
          debugShowCheckedModeBanner: false,

          // Theme
          themeMode: themeProvider.themeMode,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,

          // Localization
          locale: langProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Routes
          onGenerateRoute: AppRoutes.generateRoute,

          // Initial Screen
          home: const SplashScreen(),
        );
      },
    );
  }
}