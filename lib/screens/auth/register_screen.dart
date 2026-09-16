import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = AppConstants.roleUser;
  bool _confirmOrganizerCheckbox = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == AppConstants.roleOrganizer && !_confirmOrganizerCheckbox) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that you are an event organizer.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join EventHub',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Discover upcoming experiences or host your own',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Role Selector Tabs (User vs Organizer)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceElevated : Colors.grey[200],
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRole = AppConstants.roleUser;
                                  _confirmOrganizerCheckbox = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedRole == AppConstants.roleUser
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                child: Center(
                                  child: Text(
                                    'Standard User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _selectedRole == AppConstants.roleUser
                                          ? Colors.white
                                          : theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRole = AppConstants.roleOrganizer;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedRole == AppConstants.roleOrganizer
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                child: Center(
                                  child: Text(
                                    'Event Organizer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _selectedRole == AppConstants.roleOrganizer
                                          ? Colors.white
                                          : theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Name
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Jane Doe',
                      prefixIcon: Icons.person_outline,
                      validator: AppValidators.validateName,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'jane@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: AppValidators.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // Phone (10 digits)
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number (10 digits)',
                      hint: '9876543210',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: AppValidators.validatePhone,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Min 6 chars (letter & number)',
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                      validator: AppValidators.validatePassword,
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter password',
                      isPassword: true,
                      prefixIcon: Icons.lock_reset_outlined,
                      validator: (val) => AppValidators.validateConfirmPassword(
                        val,
                        _passwordController.text,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Organizer confirmation checkbox (if Organizer role selected)
                    if (_selectedRole == AppConstants.roleOrganizer) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: AppTheme.accentColor.withOpacity(0.4),
                          ),
                        ),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _confirmOrganizerCheckbox,
                          onChanged: (val) {
                            setState(() {
                              _confirmOrganizerCheckbox = val ?? false;
                            });
                          },
                          title: const Text(
                            'I confirm I am an event organizer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Enables publishing and managing events with attendee tracking.',
                            style: TextStyle(fontSize: 11),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
                    CustomButton(
                      text: 'Create Account',
                      isLoading: auth.isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 20),

                    // Sign In Redirect
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
