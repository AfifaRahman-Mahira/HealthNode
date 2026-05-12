import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Controller to manage the continuous pulsing animation
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    
    // Set up a repeating animation for a dynamic "Pulse" effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // This makes the icon pulse continuously

    // Navigation timer to proceed to LoginScreen after 3.5 seconds
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder: (context, anim, secondaryAnim) => const LoginScreen(),
            transitionsBuilder: (context, anim, secondaryAnim, child) {
              // Smoothly fade out the splash screen into the login screen
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Proper cleanup of the animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // Gradient theme to match HealthNode branding
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Pulse Effect for the Logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  // Pulsing effect: slightly growing and shrinking
                  scale: 1.0 + (_controller.value * 0.12),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.15),
                          blurRadius: 30 * _controller.value,
                          spreadRadius: 5 * _controller.value,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      size: 110,
                      color: Colors.cyanAccent,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            // Text branding section
            const Text(
              "HealthNode",
              style: TextStyle(
                fontSize: 44,
                letterSpacing: 2.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(blurRadius: 15, color: Colors.cyanAccent, offset: Offset(0, 0)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Smart Health Management System",
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 80),
            // High-quality loading bar
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                color: Colors.cyanAccent,
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}