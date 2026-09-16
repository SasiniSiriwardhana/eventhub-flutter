import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  final LocalStorageService _storage = LocalStorageService();

  late TextEditingController _baseUrlController;
  bool _isTestingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    final customUrl = _storage.getCustomBaseUrl();
    _baseUrlController = TextEditingController(
      text: customUrl ?? _apiService.baseUrl,
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    final testUrl = _baseUrlController.text.trim();
    _apiService.updateBaseUrl(testUrl);

    try {
      await _apiService.get('/events');
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = 'SUCCESS: Connected to json-server backend!';
      });
      await _storage.setCustomBaseUrl(testUrl);
    } catch (e) {
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = 'FAILED: Could not reach $testUrl. Check host and port.';
      });
    }
  }

  void _resetToDefault() {
    final def = AppConstants.defaultBaseUrl;
    _baseUrlController.text = def;
    _apiService.updateBaseUrl(def);
    _storage.setCustomBaseUrl(def);
    setState(() {
      _connectionStatus = 'Reset to platform default: $def';
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section: Appearance
          const Text(
            'APPEARANCE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  subtitle: const Text('Follow system theme settings'),
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (mode) {
                    if (mode != null) themeProvider.setThemeMode(mode);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Light Mode'),
                  secondary: const Icon(Icons.light_mode_outlined),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (mode) {
                    if (mode != null) themeProvider.setThemeMode(mode);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (mode) {
                    if (mode != null) themeProvider.setThemeMode(mode);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Section: API Backend Configuration
          const Text(
            'BACKEND API CONFIGURATION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure the mock json-server endpoint. Useful when testing on physical devices using your local network IP (e.g. http://192.168.1.100:3000).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          CustomTextField(
            controller: _baseUrlController,
            label: 'API Base URL',
            hint: 'http://10.0.2.2:3000',
            prefixIcon: Icons.dns_outlined,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Test & Save',
                  isLoading: _isTestingConnection,
                  onPressed: _testConnection,
                  height: 44,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 44),
                ),
                onPressed: _resetToDefault,
                child: const Text('Reset', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),

          if (_connectionStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _connectionStatus!.startsWith('SUCCESS')
                    ? AppTheme.successColor.withOpacity(0.12)
                    : AppTheme.errorColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _connectionStatus!.startsWith('SUCCESS')
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
              child: Text(
                _connectionStatus!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _connectionStatus!.startsWith('SUCCESS')
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
