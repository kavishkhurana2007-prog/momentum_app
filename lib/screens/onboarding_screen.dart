import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


class OnboardingPageModel {
  final IconData icon;
  final String title;
  final String description;

  OnboardingPageModel({
    required this.icon,
    required this.title,
    required this.description,
  });
}


final List<OnboardingPageModel> onboardingPages = [
  OnboardingPageModel(
    icon: Icons.checklist_rtl_rounded,
    title: 'Welcome!',
    description: 'Track your habits, manage your to-dos, and organize your life, all in one place.',
  ),
  OnboardingPageModel(
    icon: Icons.auto_awesome_rounded,
    title: 'AI-Powered Planning',
    description: 'Let our smart algorithm suggest the perfect schedule to help you achieve your daily goals.',
  ),
  OnboardingPageModel(
    icon: Icons.insights_rounded,
    title: 'Visualize Your Progress',
    description: 'Use beautiful charts and detailed history to stay motivated and understand your patterns.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == onboardingPages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingPages.length,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = onboardingPages[index];
                    return _OnboardingPageContent(
                      icon: page.icon,
                      title: page.title,
                      description: page.description,
                    );
                  },
                ),
              ),

              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: onboardingPages.length,
                    effect: WormEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: theme.colorScheme.primary,
                      dotColor: theme.colorScheme.surfaceVariant,
                    ),
                  ),
                  
                  
                  FilledButton(
                    onPressed: () {
                      if (isLastPage) {
                        widget.onDone();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(isLastPage ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _OnboardingPageContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPageContent({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 120, color: theme.colorScheme.primary),
        const SizedBox(height: 40),
        Text(
          title,
          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

