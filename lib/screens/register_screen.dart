// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/error_handler.dart';
import '../screens/main_navigation_screen.dart';
import '../services/api_exception.dart'; // Added this import

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedBusinessType = 'Duka la Jumla';

  final List<Map<String, String>> _businessTypes = [
    {'value': 'Duka la Jumla', 'label': 'Duka la Jumla'},
    {'value': 'Duka la Rejareja', 'label': 'Duka la Rejareja'},
    {'value': 'Pharmacy', 'label': 'Pharmacy'},
    {'value': 'Hoteli/Mgahawa', 'label': 'Hoteli/Mgahawa'},
    {'value': 'Salon/Spa', 'label': 'Salon/Spa'},
    {'value': 'Stationery', 'label': 'Stationery'},
    {'value': 'Hardware', 'label': 'Hardware'},
    {'value': 'Huduma za Teknolojia', 'label': 'Huduma za Teknolojia'},
    {'value': 'Kilimo', 'label': 'Kilimo'},
    {'value': 'Nyingine', 'label': 'Nyingine'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sajili Akaunti'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset('assets/images/blue.png', width: 100, height: 100),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Namba ya Simu',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tafadhali ingiza namba ya simu';
                        }
                        if (value.length < 9 || value.length > 15) {
                          return 'Namba ya simu si sahihi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Jina Kamili',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tafadhali ingiza jina lako';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _businessNameController,
                      label: 'Jina la Biashara',
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tafadhali ingiza jina la biashara';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Eneo la Biashara',
                      icon: Icons.location_on,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tafadhali ingiza eneo la biashara';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: AppLocalizations.of(context)!.password,
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tafadhali ingiza neno la siri';
                        }
                        if (value.length < 6) {
                          return 'Neno la siri linatakiwa kuwa na angalau herufi 6';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: AppLocalizations.of(context)!.confirmNewPassword,
                      icon: Icons.lock_reset,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tafadhali thibitisha neno la siri';
                        }
                        if (value != _passwordController.text) {
                          return 'Neno la siri halifanani';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Jisajili'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedBusinessType,
      decoration: InputDecoration(
        labelText: 'Aina ya Biashara',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
        isCollapsed: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      items: _businessTypes.map((type) {
        return DropdownMenuItem(value: type['value'], child: Text(type['label']!));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBusinessType = value!;
        });
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.register(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        passwordConfirmation: _confirmPasswordController.text.trim(),
        businessName: _businessNameController.text.trim(),
        businessType: _selectedBusinessType,
        businessAddress: _addressController.text.trim(),
      );
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Umefanikiwa kujisajili!');
        Navigator.of(context).pop(); // Go back to the LoginScreen
      }
    } on ApiException catch (e) {
      if (mounted) {
        ErrorHandler.handleError(context, e);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handleError(context, 'Hitilafu imetokea: ${e.toString()}');
      }
    }
  }
}
