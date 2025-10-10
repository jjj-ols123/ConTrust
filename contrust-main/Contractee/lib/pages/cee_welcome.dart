import 'dart:ui';

import 'package:backend/utils/be_pagetransition.dart';
import 'package:contractee/pages/cee_home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Stack(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: PageView(
              controller: _pageController,
              children: [ 
                buildPage(
                  color: Colors.yellow[700]!,
                  title: "Welcome",
                  description:
                      "Contrust is a platform for creating contracts between contractors and contractees.",
                ),
                buildPage(
                  color: Colors.yellow[700]!,
                  title: "Connect",
                  description: "Easily find and connect with reliable contractors.",
                ),
                buildPage(
                  color: Colors.yellow[700]!,
                  title: "Design",
                  description: "Use AI to pick a color of your choice to your wall.",
                  context: context,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: Colors.black,
                  dotColor: Colors.black38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPage({
    required Color color,
    required String title,
    required String description,
    BuildContext? context,
  }) {
    return Container(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (context != null && title == "Design")
              ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isFirstOpen', false);

                 // ignore: use_build_context_synchronously
                 transitionBuilder(context, HomePage(), replace: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Let's Go!",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
