import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:safe_alert/models/emergency_contact.dart';
import 'package:safe_alert/providers/app_providers.dart';
import 'package:safe_alert/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _serverUrlController = TextEditingController();
  bool _shareLocation = true;
  String _language = 'English';
  List<EmergencyContact> _contacts = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);
    _nameController.text = await storage.getUserName();
    _serverUrlController.text = await storage.getServerUrl();
    _shareLocation = await storage.getShareLocation();
    _language = await storage.getLanguage();
    _contacts = await storage.getContacts();
    setState(() => _loaded = true);
  }

  Future<void> _saveSettings() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setUserName(_nameController.text.trim());
    await storage.setServerUrl(_serverUrlController.text.trim());
    await storage.setShareLocation(_shareLocation);
    await storage.setLanguage(_language);

    // Update API base URL
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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed),
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
          // Profile section
          _SectionHeader(title: 'Profile', icon: Icons.person),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.badge,
                      color: AppTheme.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppTheme.primaryDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Server configuration
          _SectionHeader(title: 'Server', icon: Icons.dns),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _serverUrlController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'FastAPI Server URL',
                  hintText: 'http://10.0.2.2:8000',
                  hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.4)),
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.link,
                      color: AppTheme.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppTheme.primaryDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
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
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  value: _shareLocation,
                  activeColor: AppTheme.accentOrange,
                  onChanged: (val) =>
                      setState(() => _shareLocation = val),
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
                    items: ['English', 'Spanish', 'French', 'Hindi', 'Arabic']
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
              icon: const Icon(Icons.add_circle,
                  color: AppTheme.accentOrange),
            ),
          ),
          if (_contacts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No emergency contacts added yet',
                    style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.6)),
                  ),
                ),
              ),
            )
          else
            ..._contacts.map((contact) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.accentOrange.withOpacity(0.2),
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(contact.name,
                        style:
                            const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(
                      '${contact.phone}${contact.relationship.isNotEmpty ? ' • ${contact.relationship}' : ''}',
                      style:
                          const TextStyle(color: AppTheme.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.accentRed),
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
