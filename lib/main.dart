import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'ui/theme.dart';
import 'ui/widgets/sidebar.dart';
import 'ui/screens/dashboard.dart';
import 'ui/screens/subject_detail.dart';
import 'ui/screens/anonymous_inbox.dart';
import 'ui/screens/onboarding.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const AttendanceTrackerApp(),
    ),
  );
}

class AttendanceTrackerApp extends StatelessWidget {
  const AttendanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        Widget homeScreen;
        if (appState.isLoading) {
          homeScreen = Scaffold(
            body: Container(
              decoration: AppTheme.backgroundDecoration(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    const SizedBox(height: 16.0),
                    Text(
                      'Securing environment and synchronizing local records...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (!appState.hasSeenOnboarding) {
          homeScreen = const OnboardingScreen();
        } else {
          homeScreen = const MainShell();
        }

        return MaterialApp(
          title: 'Attendance Tracker',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: homeScreen,
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentNavIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentNavIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Bootloader display
    if (appState.isLoading) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.backgroundDecoration(),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 16.0),
                Text(
                  'Securing environment and synchronizing local records...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If selectedSubject changes from outside (e.g. Dashboard card click), jump to page 1
    if (appState.selectedSubject != null && _currentNavIndex != 1) {
      _currentNavIndex = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(1);
        }
      });
    }

    final pageView = PageView(
      controller: _pageController,
      physics: const RapidPageScrollPhysics(),
      onPageChanged: (index) {
        if (index != 1 && appState.selectedSubject != null) {
          appState.setSelectedSubject(null);
        }
        setState(() => _currentNavIndex = index);
      },
      children: [
        DashboardScreen(
          onNavigate: (index) {
            appState.setSelectedSubject(null);
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeInOut,
              );
            }
            setState(() => _currentNavIndex = index);
          },
        ),
        const SubjectDetailScreen(),
        const AnonymousInboxScreen(),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isLargeScreen = constraints.maxWidth > 700;

            if (isLargeScreen) {
              // Large Screen / Web Companion Double Column Layout
              return Row(
                children: [
                  Sidebar(
                    currentIndex: appState.selectedSubject != null
                        ? 1
                        : _currentNavIndex,
                    onIndexChanged: (index) {
                      appState.setSelectedSubject(null);
                      if (_pageController.hasClients) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeInOut,
                        );
                      }
                      setState(() => _currentNavIndex = index);
                    },
                  ),
                  Expanded(child: SafeArea(bottom: false, child: pageView)),
                ],
              );
            }

            // Mobile Layout (Sidebar renders as BottomNavigationBar)
            return Column(
              children: [
                Expanded(child: SafeArea(bottom: false, child: pageView)),
                Sidebar(
                  currentIndex: appState.selectedSubject != null
                      ? 1
                      : _currentNavIndex,
                  onIndexChanged: (index) {
                    appState.setSelectedSubject(null);
                    if (_pageController.hasClients) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeInOut,
                      );
                    }
                    setState(() => _currentNavIndex = index);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RapidPageScrollPhysics extends PageScrollPhysics {
  const RapidPageScrollPhysics({super.parent});

  @override
  RapidPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return RapidPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.2, stiffness: 400.0, damping: 18.0);
}