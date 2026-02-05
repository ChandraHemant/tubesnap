import 'package:flutter/material.dart';
import '../core/utils/responsive.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateToHome();
  }

  void _initAnimations() {
    // Logo Animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Text Animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Progress Animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start animations sequence
    _logoController.forward().then((_) {
      _textController.forward();
      _progressController.forward();
    });
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.surface,
              theme.colorScheme.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background decorations
            _buildBackgroundDecorations(theme, responsive),

            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value,
                          child: _buildLogo(theme, responsive),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: responsive.rs(32)),

                  // Animated Text
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          // App Name
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'TubeSnap',
                              style: TextStyle(
                                fontSize: responsive.sp(36),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: responsive.rs(8)),

                          // Tagline
                          Text(
                            'Fast Video Downloader',
                            style: TextStyle(
                              fontSize: responsive.sp(14),
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.rs(48)),

                  // Progress Indicator
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return SizedBox(
                        width: responsive.rs(200),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(responsive.rs(10)),
                              child: LinearProgressIndicator(
                                value: _progressValue.value,
                                backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation(
                                  Color.lerp(
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                    _progressValue.value,
                                  ),
                                ),
                                minHeight: responsive.rs(6),
                              ),
                            ),
                            SizedBox(height: responsive.rs(12)),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: responsive.sp(12),
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom Version
            Positioned(
              bottom: responsive.rs(32),
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: responsive.sp(12),
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    SizedBox(height: responsive.rs(4)),
                    Text(
                      'Made with ❤️ in India',
                      style: TextStyle(
                        fontSize: responsive.sp(11),
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme, Responsive responsive) {
    return Container(
      width: responsive.rs(120),
      height: responsive.rs(120),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(responsive.rs(32)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          Container(
            width: responsive.rs(80),
            height: responsive.rs(80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          // Icon
          Icon(
            Icons.play_circle_filled_rounded,
            color: Colors.white,
            size: responsive.iconSize(mobile: 64, desktop: 72),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations(ThemeData theme, Responsive responsive) {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -responsive.rs(100),
          right: -responsive.rs(100),
          child: Container(
            width: responsive.rs(250),
            height: responsive.rs(250),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.primary.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // Bottom left circle
        Positioned(
          bottom: -responsive.rs(80),
          left: -responsive.rs(80),
          child: Container(
            width: responsive.rs(200),
            height: responsive.rs(200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.secondary.withOpacity(0.15),
                  theme.colorScheme.secondary.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),

        // Center decoration
        Positioned(
          top: responsive.hp(30),
          left: responsive.wp(10),
          child: Container(
            width: responsive.rs(60),
            height: responsive.rs(60),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.05),
            ),
          ),
        ),

        Positioned(
          bottom: responsive.hp(25),
          right: responsive.wp(15),
          child: Container(
            width: responsive.rs(40),
            height: responsive.rs(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondary.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }
}