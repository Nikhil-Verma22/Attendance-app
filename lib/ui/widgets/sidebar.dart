import 'package:flutter/material.dart';
import '../theme.dart';

class Sidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Determine screen height and layout responsiveness
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isLargeScreen = MediaQuery.of(context).size.width > 700;

    if (!isLargeScreen) {
      // Bottom navigation layout for mobile screens
      return Container(
        decoration: AppTheme.cardDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          shadowOpacity: 0.1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Center(
                  child: _buildBottomItem(context, 0, Icons.dashboard_rounded, 'Dashboard'),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildBottomItem(context, 1, Icons.calendar_month_rounded, 'Calendar'),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildBottomItem(context, 2, Icons.mark_as_unread_rounded, 'Inbox'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Classic premium vertical sidebar for larger screens (web companion/tablet)
    return Container(
      width: 86.0,
      height: screenHeight - 48.0,
      margin: const EdgeInsets.all(24.0),
      decoration: AppTheme.cardDecoration(
        color: AppTheme.cardBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          // Logo/Brand Icon at the top
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 12.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppTheme.white,
              size: 26.0,
            ),
          ),
          const Spacer(),
          // Mid items
          _buildSidebarItem(context, 0, Icons.grid_view_rounded, 'Dashboard'),
          const SizedBox(height: 16.0),
          _buildSidebarItem(context, 1, Icons.calendar_today_rounded, 'Calendar'),
          const SizedBox(height: 16.0),
          _buildSidebarItem(context, 2, Icons.mark_as_unread_rounded, 'Inbox'),
          const Spacer(),
          // Profile Indicator (as seen at bottom of reference UI)
          Container(
            width: 42.0,
            height: 42.0,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1.5),
            ),
            child: const Center(
              child: Text(
                'ST', // Student
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    int index,
    IconData icon,
    String tooltip,
  ) {
    final bool isSelected = currentIndex == index;
    
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onIndexChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52.0,
          height: 52.0,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.transparent,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isSelected ? AppTheme.transparent : AppTheme.neutralBorder.withOpacity(0.5),
              width: 1.0,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppTheme.white : AppTheme.textSecondary,
            size: 22.0,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final bool isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onIndexChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.transparent,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          size: 20.0,
        ),
      ),
    );
  }
}
