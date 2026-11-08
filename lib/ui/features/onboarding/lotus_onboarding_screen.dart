import 'package:flutter/material.dart';
import '../streak/lotus_bloom_widget.dart';

class LotusOnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const LotusOnboardingScreen({super.key, required this.onFinish});

  @override
  State<LotusOnboardingScreen> createState() => _LotusOnboardingScreenState();
}

class _LotusOnboardingScreenState extends State<LotusOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      stage: LotusStage.bud,
      title: 'BUD',
      description:
          'Your health journey begins here. Build a mindful daily medication habit one simple, on-time dose at a time.',
    ),
    _OnboardingPageData(
      stage: LotusStage.blooming,
      title: 'BLOOMING',
      description:
          'Consistency creates vitality. Your routine takes root and unfurls into steady, reliable well-being.',
    ),
    _OnboardingPageData(
      stage: LotusStage.blossom,
      title: 'BLOSSOM',
      description:
          'Flourishing health in full radiance. Celebrate your adherence streaks and enjoy a longer, healthier life.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1834),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Top Stepper Dots (Matching Image 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color(0xFFE879F9)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            const Spacer(),

            // Page View with Lotus Bloom Graphics
            SizedBox(
              height: 420,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LotusBloomWidget(
                        stage: page.stage,
                        size: 210,
                        animate: true,
                      ),
                      const SizedBox(height: 36),
                      Text(
                        page.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Spacer(),

            // Bottom Navigation & Get Started Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress line indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 12,
                        height: 3,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFFE879F9)
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // Button: Next or Get Started
                  if (_currentPage == _pages.length - 1)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC026D3), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                      ),
                      onPressed: widget.onFinish,
                      child: const Text(
                        'GET STARTED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Color(0xFFF472B6),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white70),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final LotusStage stage;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.stage,
    required this.title,
    required this.description,
  });
}
