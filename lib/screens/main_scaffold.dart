import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../services/network_monitor_service.dart';
import '../widgets/offline_banner.dart';

/// Main application shell providing the bottom navigation bar and elevated center scan button.
///
/// Features 5-slot layout:
/// - Tab 0: Home (`/home`)
/// - Tab 1: History (`/history`)
/// - Center: Elevated circular Scan button with white ring (`/scan`)
/// - Tab 2: Search (`/search`)
/// - Tab 3: Profile (`/profile`)
/// - Integrates seamlessly with [StatefulNavigationShell] to preserve state across tab switches.
class MainScaffold extends StatelessWidget {
  /// The navigation shell managing tab branch state.
  final StatefulNavigationShell navigationShell;

  /// Optional injected [NetworkMonitorService] for connectivity monitoring.
  final NetworkMonitorService? networkMonitorService;

  const MainScaffold({
    super.key,
    required this.navigationShell,
    this.networkMonitorService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          OfflineBanner(networkMonitorService: networkMonitorService),
          Expanded(child: navigationShell),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildCenterScanButton(context),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: context.surfaceColor,
        elevation: 8.0,
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        height: 64.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0: Home
            _buildNavItem(
              context: context,
              index: 0,
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => _onTabSelected(0),
            ),

            // Tab 1: History
            _buildNavItem(
              context: context,
              index: 1,
              icon: Icons.history_rounded,
              label: 'History',
              onTap: () => _onTabSelected(1),
            ),

            // Space placeholder for the center docked Scan button
            const SizedBox(width: 48),

            // Tab 2: My Crop
            _buildNavItem(
              context: context,
              index: 2,
              icon: Icons.grass_rounded,
              label: 'My Crop',
              onTap: () => _onTabSelected(2),
            ),

            // Tab 3: Profile
            _buildNavItem(
              context: context,
              index: 3,
              icon: Icons.person_rounded,
              label: 'Profile',
              onTap: () => _onTabSelected(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterScanButton(BuildContext context) {
    return Container(
      width: 60.0,
      height: 60.0,
      margin: const EdgeInsets.only(top: 18.0),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF141D14) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(90),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppRoutes.scan),
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withAlpha(50),
            child: const Tooltip(
              message: 'Scan Leaf',
              child: Center(
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 26.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isSelected = navigationShell.currentIndex == index;
    final isDark = context.isDarkMode;
    final color = isSelected
        ? (isDark ? AppColors.primaryLight : AppColors.primary)
        : (isDark ? const Color(0xFFA0ABA0) : AppColors.textSecondary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24.0,
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
