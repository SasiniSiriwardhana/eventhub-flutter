import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _imageController;
  final TextEditingController _passwordController = TextEditingController();

  String? _previewImageUrl;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _imageController = TextEditingController(text: user?.profileImage ?? '');
    _previewImageUrl = user?.profileImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _imageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await auth.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      profileImage: _imageController.text.trim().isNotEmpty
          ? _imageController.text.trim()
          : null,
      newPassword: _changePassword && _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to update profile.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Preview with edit helper
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: (_previewImageUrl != null &&
                                    _previewImageUrl!.isNotEmpty)
                                ? _previewImageUrl!
                                : AppConstants.placeholderAvatar,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (ctx, url, err) => const Icon(
                              Icons.person,
                              size: 46,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Live Avatar Preview',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  validator: AppValidators.validateName,
                ),
                const SizedBox(height: 18),

                // Phone
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number (10 digits)',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: AppValidators.validatePhone,
                ),
                const SizedBox(height: 18),

                // Profile Image URL
                CustomTextField(
                  controller: _imageController,
                  label: 'Profile Picture URL',
                  hint: 'https://images.unsplash.com/...',
                  prefixIcon: Icons.link_rounded,
                  validator: (val) => AppValidators.validateUrl(val, optional: true),
                  onChanged: (val) {
                    setState(() {
                      _previewImageUrl = val.trim();
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Change Password Section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceElevated : Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _changePassword,
                        onChanged: (val) {
                          setState(() {
                            _changePassword = val ?? false;
                          });
                        },
                        title: const Text(
                          'Change Account Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Check to enter a new security password',
                          style: TextStyle(fontSize: 11),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_changePassword) ...[
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'New Password',
                          hint: 'Min 6 chars (letter & number)',
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (val) {
                            if (_changePassword) {
                              return AppValidators.validatePassword(val);
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                CustomButton(
                  text: 'Save Changes',
                  isLoading: auth.isLoading,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
