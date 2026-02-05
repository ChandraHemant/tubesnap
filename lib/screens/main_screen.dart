import 'package:flutter/material.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DownloadsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    // Desktop/Tablet Layout with Side Navigation
    if (responsive.isDesktop || (responsive.isTablet && responsive.isLandscape)) {
      return Scaffold(
        body: Row(
          children: [
            // Side Navigation Rail
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              extended: responsive.isDesktop,
              minExtendedWidth: 200,
              backgroundColor: theme.colorScheme.surface,
              leading: Padding(
                padding: EdgeInsets.symmetric(vertical: responsive.rs(20)),
                child: _buildLogo(theme, responsive),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: Text(context.tr('nav.home')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.download_outlined),
                  selectedIcon: const Icon(Icons.download_rounded),
                  label: Text(context.tr('nav.downloads')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings_rounded),
                  label: Text(context.tr('nav.settings')),
                ),
              ],
            ),

            // Divider
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.colorScheme.outline,
            ),

            // Content
            Expanded(
              child: _screens[_currentIndex],
            ),
          ],
        ),
      );
    }

    // Mobile/Tablet Portrait Layout with Bottom Navigation
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(theme, responsive),
    );
  }

  Widget _buildLogo(ThemeData theme, Responsive responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.rs(12)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(responsive.rs(16)),
      ),
      child: Icon(
        Icons.play_circle_filled_rounded,
        color: Colors.white,
        size: responsive.iconSize(mobile: 28, desktop: 32),
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme, Responsive responsive) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.rs(16),
            vertical: responsive.rs(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                theme, responsive, 0,
                Icons.home_outlined, Icons.home_rounded,
                context.tr('nav.home'),
              ),
              _buildNavItem(
                theme, responsive, 1,
                Icons.download_outlined, Icons.download_rounded,
                context.tr('nav.downloads'),
              ),
              _buildNavItem(
                theme, responsive, 2,
                Icons.settings_outlined, Icons.settings_rounded,
                context.tr('nav.settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      ThemeData theme,
      Responsive responsive,
      int index,
      IconData icon,
      IconData activeIcon,
      String label,
      ) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(responsive.rs(16)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.rs(isSelected ? 20 : 16),
          vertical: responsive.rs(10),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(responsive.rs(16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              size: responsive.iconSize(mobile: 22),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Padding(
                padding: EdgeInsets.only(left: responsive.rs(8)),
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: responsive.sp(13),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}