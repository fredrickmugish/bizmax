import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:rahisisha/screens/register_screen.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../utils/error_handler.dart';
import '../screens/main_navigation_screen.dart';
import 'dart:async';

import 'package:rahisisha/screens/reset_password_screen.dart'; // Import the new screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Onboarding carousel fields
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  final List<Map<String, dynamic>> _onboardingPages = [
    {
      'icon': Icons.trending_up,
      'title': 'Epuka Hasara',
      'subtitle': 'Fuatilia mauzo na matumizi kwa urahisi, ongeza faida yako.'
    },
    {
      'icon': Icons.people_alt,
      'title': 'Simamia Wauzaji',
      'subtitle': 'Fuatilia mauzo ya wauzaji wako.'
    },
    {
      'icon': Icons.bar_chart,
      'title': 'Fanya Maamuzi Sahihi',
      'subtitle': 'Pata takwimu na ripoti za biashara papo hapo.'
    },
    {
      'icon': Icons.notifications_active,
      'title': 'Usikose Mauzo',
      'subtitle': 'Pata arifa bidhaa zinapokwisha na ongeza mauzo.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _onboardingPages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AuthProvider authProvider, BuildContext scaffoldContext) async {
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await authProvider.login(
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted && authProvider.isAuthenticated) {
        Navigator.of(scaffoldContext).pushAndRemoveUntil( // Use scaffoldContext for navigation
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ErrorHandler.handleError(scaffoldContext, e); // Use scaffoldContext
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handleError(scaffoldContext, 'Hitilafu imetokea: ${e.toString()}'); // Use scaffoldContext
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.forgotPassword),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.phoneNumber,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.sendCode),
              onPressed: () async {
                if (phoneController.text.trim().isEmpty) {
                  ErrorHandler.handleError(dialogContext, 'Tafadhali ingiza namba ya simu.');
                  return;
                }
                try {
                  await Provider.of<AuthProvider>(dialogContext, listen: false).forgotPassword(
                    phone: phoneController.text.trim(),
                  );
                  if (mounted) {
                    // Dismiss the dialog first
                    Navigator.of(dialogContext).pop();
                    // Then navigate to the reset password screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ResetPasswordScreen(phone: phoneController.text.trim()),
                      ),
                    );
                  }
                } on ApiException catch (e) {
                  if (mounted) {
                    ErrorHandler.handleError(dialogContext, e);
                  }
                } catch (e) {
                  if (mounted) {
                    ErrorHandler.handleError(dialogContext, 'Hitilafu imetokea: ${e.toString()}');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Builder( // Added Builder here
            builder: (scaffoldContext) => SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: SizedBox(
                        width: constraints.maxWidth > 600 ? 400 : constraints.maxWidth * 0.9, // Max width 400, or 90% of screen width
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/blue.png', width: 100, height: 100),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 220,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: PageView.builder(
                                      controller: _pageController,
                                      itemCount: _onboardingPages.length,
                                      onPageChanged: (index) {
                                        if (mounted) {
                                          setState(() { _currentPage = index; });
                                        }
                                      },
                                      itemBuilder: (context, index) {
                                        final page = _onboardingPages[index];
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(page['icon'], size: 60, color: Colors.blue),
                                            const SizedBox(height: 8),
                                            Text(page['title'] ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                                            const SizedBox(height: 4),
                                            Text(page['subtitle'] ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(_onboardingPages.length, (index) {
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: _currentPage == index ? 12 : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _currentPage == index ? Colors.blue : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: AppLocalizations.of(context)!.phoneNumber,
                                      prefixIcon: const Icon(Icons.phone),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      fillColor: Colors.grey.shade50,
                                      filled: true,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty || value.length < 9) {
                                        return 'Tafadhali ingiza namba sahihi ya simu';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: AppLocalizations.of(context)!.password,
                                      prefixIcon: const Icon(Icons.lock),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      fillColor: Colors.grey.shade50,
                                      filled: true,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty || value.length < 6) {
                                        return 'Neno la siri linatakiwa kuwa na angalau herufi 6';
                                      }
                                      return null;
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _showForgotPasswordDialog(scaffoldContext), // Use scaffoldContext
                                      child: Text(AppLocalizations.of(context)!.forgotPassword),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: authProvider.isLoading ? null : () => _handleSubmit(authProvider, scaffoldContext), // Pass scaffoldContext
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: authProvider.isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : Text(AppLocalizations.of(context)!.login),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  RichText(
                                    text: TextSpan(
                                      text: 'Huna akaunti? ',
                                      style: const TextStyle(color: Colors.black54),
                                      children: [
                                        TextSpan(
                                          text: 'Jisajili',
                                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}