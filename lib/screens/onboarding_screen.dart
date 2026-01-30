import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Healthy Daily Meals",
      "subtitle": "Discover a variety of balanced meals prepared fresh every day just for you.",
      "image": "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=500&auto=format",
    },
    {
      "title": "Save Your Time",
      "subtitle": "Stop worrying about what to cook. We handle the planning and delivery.",
      "image": "https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=500&auto=format",
    },
    {
      "title": "Flexible Subscriptions",
      "subtitle": "Pause or swap your meals anytime. You're in full control of your plan.",
      "image": "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&auto=format",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (value) => setState(() => _currentPage = value),
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) => Column(
                children: [
                  const Spacer(),
                  Image.network(
                    _onboardingData[index]["image"]!,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _onboardingData[index]["title"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _onboardingData[index]["subtitle"]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppTheme.primaryColor : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _onboardingData.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          );
                        }
                      },
                      child: Text(_currentPage == _onboardingData.length - 1 ? "Get Started" : "Next"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
