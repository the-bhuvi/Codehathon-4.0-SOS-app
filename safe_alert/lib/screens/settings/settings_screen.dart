import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:safe_alert/models/emergency_contact.dart';
import 'package:safe_alert/models/user_profile.dart';
import 'package:safe_alert/providers/app_providers.dart';
import 'package:safe_alert/theme/app_theme.dart';
import 'package:safe_alert/services/shake_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Profile fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  String _bloodGroup = '';

  // Settings
  final _serverUrlController = TextEditingController();
  bool _shareLocation = true;
  String _language = 'English';
  bool _shakePanicEnabled = true;
  bool _autoRecordEnabled = false;
  bool _autoSmsEnabled = true;
  String _shakeSensitivity = 'medium';
  bool _shakeServiceRunning = false;

  List<EmergencyContact> _contacts = [];
  bool _loaded = false;

  static const List<String> _bloodGroups = [
    '', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
  ];

  static const List<String> _languages = [
    'English', 'Hindi', 'Tamil', 'Telugu', 'Kannada', 'Malayalam',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);
    final profile = await storage.getUserProfile();

    _nameController.text = profile.fullName;
    _phoneController.text = profile.phone;
    _emergencyContactNameController.text = profile.emergencyContactName;
    _emergencyContactPhoneController.text = profile.emergencyContactPhone;
    _medicalConditionsController.text = profile.medicalConditions;
    _bloodGroup = profile.bloodGroup;

    _serverUrlController.text = await storage.getServerUrl();
    _shareLocation = await storage.getShareLocation();
    _language = await storage.getLanguage();
    _shakePanicEnabled = await storage.getShakePanicEnabled();
    _autoRecordEnabled = await storage.getAutoRecordEnabled();
    _autoSmsEnabled = await storage.getAutoSmsEnabled();
    _shakeSensitivity = await storage.getShakeSensitivity();
    _contacts = await storage.getContacts();
    _shakeServiceRunning = await ShakeBackgroundService.isRunning();

    // Validate language is in our list
    if (!_languages.contains(_language)) _language = 'English';

    setState(() => _loaded = true);
  }

  Future<void> _saveSettings() async {
    final storage = ref.read(storageServiceProvider);

    // Save profile
    final profile = UserProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      emergencyContactName: _emergencyContactNameController.text.trim(),
      emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
      bloodGroup: _bloodGroup,
      medicalConditions: _medicalConditionsController.text.trim(),
    );
    await storage.saveUserProfile(profile);

    // Save other settings
    await storage.setServerUrl(_serverUrlController.text.trim());
    await storage.setShareLocation(_shareLocation);
    await storage.setLanguage(_language);
    await storage.setShakePanicEnabled(_shakePanicEnabled);
    await storage.setAutoRecordEnabled(_autoRecordEnabled);
    await storage.setAutoSmsEnabled(_autoSmsEnabled);
    await storage.setShakeSensitivity(_shakeSensitivity);

    // Start or stop background shake service based on toggle
    if (_shakePanicEnabled) {
      await _startShakeService();
    } else {
      await ShakeBackgroundService.stop();
      setState(() => _shakeServiceRunning = false);
    }

    ref.read(apiServiceProvider).updateBaseUrl(_serverUrlController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: AppTheme.safeGreen,
        ),
      );
    }
  }

  Future<void> _startShakeService() async {
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://zzatwehdudhztqyblrpa.supabase.co',
    );
    const supabaseKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6YXR3ZWhkdWRoenRxeWJscnBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxMTg1MjUsImV4cCI6MjA4ODY5NDUyNX0.j8MedoZykf7QMaMUKzLBcIJILY8C7tx2uceboZDBeVk',
    );

    final started = await ShakeBackgroundService.start(
      supabaseUrl: supabaseUrl,
      supabaseKey: supabaseKey,
    );
    setState(() => _shakeServiceRunning = started);
  }

  void _addContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Add Emergency Contact',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameCtrl, 'Name', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(phoneCtrl, 'Phone Number', Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(relCtrl, 'Relationship', Icons.group),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                final contact = EmergencyContact(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  relationship: relCtrl.text.trim(),
                );
                final storage = ref.read(storageServiceProvider);
                await storage.addContact(contact);
                setState(() => _contacts.add(contact));
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        filled: true,
        fillColor: AppTheme.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _medicalConditionsController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.accentRed)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save, color: AppTheme.accentOrange),
            label: const Text('Save',
                style: TextStyle(color: AppTheme.accentOrange)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency Profile section (Feature 4)
          _SectionHeader(title: 'Emergency Profile', icon: Icons.person),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField(_nameController, 'Full Name', Icons.badge),
                  const SizedBox(height: 12),
                  _buildTextField(_phoneController, 'Phone Number', Icons.phone,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _buildTextField(_emergencyContactNameController,
                      'Emergency Contact Name', Icons.contact_emergency),
                  const SizedBox(height: 12),
                  _buildTextField(_emergencyContactPhoneController,
                      'Emergency Contact Phone', Icons.phone_forwarded,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  // Blood group dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bloodtype, color: AppTheme.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _bloodGroups.contains(_bloodGroup) ? _bloodGroup : '',
                            isExpanded: true,
                            dropdownColor: AppTheme.cardDark,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            underline: const SizedBox(),
                            hint: const Text('Blood Group',
                                style: TextStyle(color: AppTheme.textSecondary)),
                            items: _bloodGroups.map((bg) => DropdownMenuItem(
                              value: bg,
                              child: Text(bg.isEmpty ? 'Select Blood Group' : bg),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _bloodGroup = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_medicalConditionsController,
                      'Medical Conditions (optional)', Icons.medical_information,
                      maxLines: 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Panic Mode settings (Features 5 & 6)
          _SectionHeader(title: 'Panic Mode', icon: Icons.vibration),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Background Shake Alert',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Text(
                      _shakeServiceRunning
                          ? 'Active – works even when app is closed'
                          : 'Shake phone to trigger SOS in background',
                      style: TextStyle(
                          color: _shakeServiceRunning ? AppTheme.safeGreen : AppTheme.textSecondary,
                          fontSize: 12)),
                  value: _shakePanicEnabled,
                  activeColor: AppTheme.accentOrange,
                  onChanged: (val) => setState(() => _shakePanicEnabled = val),
                ),
                if (_shakePanicEnabled) ...[
                  const Divider(height: 1, color: AppTheme.primaryDark),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        const Text('Sensitivity',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                        const Spacer(),
                        ToggleButtons(
                          isSelected: [
                            _shakeSensitivity == 'low',
                            _shakeSensitivity == 'medium',
                            _shakeSensitivity == 'high',
                          ],
                          onPressed: (index) {
                            setState(() {
                              _shakeSensitivity = ['low', 'medium', 'high'][index];
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: AppTheme.accentOrange,
                          color: AppTheme.textSecondary,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          constraints: const BoxConstraints(minWidth: 56, minHeight: 32),
                          children: const [
                            Text('Low'),
                            Text('Med'),
                            Text('High'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.primaryDark),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shake phone 3 times within 2 seconds to trigger SOS automatically, even when the app is closed.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 1, color: AppTheme.primaryDark),
                SwitchListTile(
                  title: const Text('Auto Camera Recording',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: const Text('Record video when panic mode triggers',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  value: _autoRecordEnabled,
                  activeColor: AppTheme.accentOrange,
                  onChanged: (val) => setState(() => _autoRecordEnabled = val),
                ),
                const Divider(height: 1, color: AppTheme.primaryDark),
                SwitchListTile(
                  title: const Text('Auto SMS to Contacts',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: const Text('Automatically send SMS to emergency contacts on SOS',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  value: _autoSmsEnabled,
                  activeColor: AppTheme.accentOrange,
                  onChanged: (val) => setState(() => _autoSmsEnabled = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Server configuration
          _SectionHeader(title: 'Server', icon: Icons.dns),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildTextField(
                _serverUrlController,
                'FastAPI Server URL',
                Icons.link,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Preferences
          _SectionHeader(title: 'Preferences', icon: Icons.tune),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Share Live Location',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: const Text('During active SOS',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  value: _shareLocation,
                  activeColor: AppTheme.accentOrange,
                  onChanged: (val) => setState(() => _shareLocation = val),
                ),
                const Divider(height: 1, color: AppTheme.primaryDark),
                ListTile(
                  title: const Text('Preferred Language',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  trailing: DropdownButton<String>(
                    value: _language,
                    dropdownColor: AppTheme.cardDark,
                    style: const TextStyle(color: AppTheme.accentOrange),
                    underline: const SizedBox(),
                    items: _languages
                        .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _language = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Emergency Contacts
          _SectionHeader(
            title: 'Emergency Contacts',
            icon: Icons.contacts,
            trailing: IconButton(
              onPressed: _addContactDialog,
              icon: const Icon(Icons.add_circle, color: AppTheme.accentOrange),
            ),
          ),
          if (_contacts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No emergency contacts added yet',
                    style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
                  ),
                ),
              ),
            )
          else
            ..._contacts.map((contact) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accentOrange.withOpacity(0.2),
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(contact.name,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(
                      '${contact.phone}${contact.relationship.isNotEmpty ? ' • ${contact.relationship}' : ''}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
                      onPressed: () async {
                        final storage = ref.read(storageServiceProvider);
                        await storage.removeContact(contact.id);
                        setState(() =>
                            _contacts.removeWhere((c) => c.id == contact.id));
                      },
                    ),
                  ),
                )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentOrange, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.accentOrange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
