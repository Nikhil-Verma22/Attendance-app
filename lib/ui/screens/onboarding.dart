import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  final bool showCloseOnly;

  const OnboardingScreen({
    super.key,
    this.showCloseOnly = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      imagePath: 'assets/preview/screen_1.webp',
      title: 'explore dashboard',
      description: 'Get a comprehensive view of all registered subjects, warning stats, target standards, and quick access actions in a single interactive dashboard.',
    ),
    OnboardingSlide(
      imagePath: 'assets/preview/screen_2.webp',
      title: 'safety standard',
      description: 'Set and track your safe attendance thresholds. Identify at-risk subjects immediately and keep your attendance above the required limits.',
    ),
    OnboardingSlide(
      imagePath: 'assets/preview/screen_3.webp',
      title: 'mark your attendance',
      description: 'Easily log conducted sessions, specify attendance status (present/absent), and record remarks for full historical clarity.',
    ),
    OnboardingSlide(
      imagePath: 'assets/preview/screen_4.webp',
      title: 'add proofs for convenience',
      description: 'Take camera snapshots or upload images from your gallery to use as secure, encrypted proof of class attendance.',
    ),
    OnboardingSlide(
      imagePath: 'assets/preview/screen_5.webp',
      title: 'assign your proof accumulated in hurry',
      description: 'Quickly capture proof pictures on the fly and organize them later by attaching them to specific class sessions from your Anonymous Inbox.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinish();
    }
  }

  void _onBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onFinish() {
    if (widget.showCloseOnly) {
      Navigator.of(context).pop();
    } else {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Icon & App Name
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.asset(
                            'assets/icon/icon_2.jpeg',
                            width: 32.0,
                            height: 32.0,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 32.0,
                                height: 32.0,
                                color: AppTheme.primary,
                                child: Icon(Icons.stars_rounded, color: AppTheme.white, size: 20.0),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'Attendance Guide',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    // Skip / Close Button
                    if (widget.showCloseOnly)
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                        onPressed: _onFinish,
                      )
                    else if (_currentPage < _slides.length - 1)
                      TextButton(
                        onPressed: _onFinish,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // PageView Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _buildSlideContent(slide, index + 1);
                  },
                ),
              ),

              // Bottom control area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Slide Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => _buildIndicator(index == _currentPage),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Navigation Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        Visibility(
                          visible: _currentPage > 0,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: TextButton(
                            onPressed: _onBack,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_back_rounded, color: AppTheme.primary, size: 18.0),
                                const SizedBox(width: 8.0),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Next / Finish Button
                        ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            elevation: 4.0,
                          ),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: Row(
                              children: [
                                Text(
                                  _currentPage == _slides.length - 1
                                      ? (widget.showCloseOnly ? 'Got It' : 'Get Started')
                                      : 'Next',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.0,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Icon(
                                  _currentPage == _slides.length - 1
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 16.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideContent(OnboardingSlide slide, int pageNumber) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;
        final bool isSmallScreen = maxHeight < 500;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Screen Mockup Frame containing the preview image
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: isSmallScreen ? 12.0 : 24.0,
                    top: isSmallScreen ? 8.0 : 16.0,
                  ),
                  decoration: AppTheme.cardDecoration(
                    color: AppTheme.cardBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24.0),
                    shadowOpacity: 0.15,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.0),
                    child: Image.asset(
                      slide.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.cardBg,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_rounded, size: 48.0, color: AppTheme.error),
                                const SizedBox(height: 12.0),
                                Text(
                                  'Preview image not found',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.0),
                                ),
                                Text(
                                  slide.imagePath,
                                  style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 11.0),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Title and Description at the bottom of the screens
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Number Badge + Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      '$pageNumber - ${slide.title}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.0,
                        letterSpacing: 0.5,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8.0 : 16.0),
                  Text(
                    slide.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: isSmallScreen ? 12.0 : 14.0,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8.0 : 16.0),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : AppTheme.neutralBorder,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

class OnboardingSlide {
  final String imagePath;
  final String title;
  final String description;

  OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}
