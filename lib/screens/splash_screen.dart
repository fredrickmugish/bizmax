

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// The import below is commented out as it's not used in this specific widget anymore.
// If 'business_provider.dart' is used elsewhere in your app, keep the file,
// but for this SplashScreen, it's not necessary.
// import '../providers/business_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // You can change this background color if needed to match your branding.
      body: Center( // This Center widget ensures the Column is horizontally centered.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // This centers the children of the Column vertically.
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/white.png', // Path to your logo image
                width: kIsWeb ? 220 : 200, // Width for web and mobile
                height: kIsWeb ? 220 : 200, // Height for web and mobile
                // You can use fit: BoxFit.contain or BoxFit.cover depending on your image aspect ratio
              ),
            ),
          ],
        ),
      ),
    );
  }
}

