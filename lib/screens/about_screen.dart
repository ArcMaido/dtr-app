import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_utils.dart';
import '../widgets/app_bottom_navigation.dart';
import 'calendar_screen.dart';
import 'export_screen.dart';
import 'home_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _guideItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.mist,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.pine, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pine,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.moss,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Guide'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1, -1),
            end: Alignment(1, 1),
            colors: [Color(0xFFF8FBFF), Color(0xFFE8F3FF)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'How To Use DTR App',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.pine,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use this page as your quick reference for every major function in the app.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.moss,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _guideItem(
              icon: Icons.home_outlined,
              title: 'Home Dashboard',
              description:
                  'View Worked Hours, Total Rendered Hours, Goal, Remaining time, Global Shift, and Excluded Time. Tap Edit buttons to update settings quickly.',
            ),
            _guideItem(
              icon: Icons.login,
              title: 'Time In / Time Out',
              description:
                  'Use Set Time-In and Set Time-Out for quick logging. Tap Time In or Time Out cards to manually edit today\'s values when needed.',
            ),
            _guideItem(
              icon: Icons.sticky_note_2_outlined,
              title: 'Notes',
              description:
                  'Use Notes on Home or inside Calendar to record what you did, a reason for the day, or any reminder tied to that specific date.',
            ),
            _guideItem(
              icon: Icons.shortcut_outlined,
              title: 'Shortcuts',
              description:
                  'Use Morning or Afternoon shortcuts to apply half-day schedules in one tap.',
            ),
            _guideItem(
              icon: Icons.calendar_month_outlined,
              title: 'Calendar',
              description:
                  'Open Calendar to review records per day, edit a specific date, and see monthly rendered totals.',
            ),
            _guideItem(
              icon: Icons.ios_share_outlined,
              title: 'Export',
              description:
                  'Choose a date range and export your records as CSV or PDF. You can also preview records before exporting.',
            ),
            _guideItem(
              icon: Icons.settings_outlined,
              title: 'Global Shift Time',
              description:
                  'Set your default working hours used for day templates and quick setup.',
            ),
            _guideItem(
              icon: Icons.remove_circle_outline,
              title: 'Excluded Time',
              description:
                  'Set lunch break or excluded time so rendered hours are computed more accurately.',
            ),
            _guideItem(
              icon: Icons.delete_forever_outlined,
              title: 'Clear Data',
              description:
                  'Use Clear All Data in Export only if needed. This action permanently removes all saved records.',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3,
        onDestinationSelected: (index) async {
          if (index == 0) {
            await Navigator.pushReplacement(
              context,
              NavigationUtils.noAnimationRoute(const HomeScreen()),
            );
          } else if (index == 1) {
            await Navigator.pushReplacement(
              context,
              NavigationUtils.noAnimationRoute(const CalendarScreen()),
            );
          } else if (index == 2) {
            await Navigator.pushReplacement(
              context,
              NavigationUtils.noAnimationRoute(const ExportScreen()),
            );
          }
        },
      ),
    );
  }
}
