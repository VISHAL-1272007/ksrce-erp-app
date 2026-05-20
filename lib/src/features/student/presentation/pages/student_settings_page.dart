import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class StudentSettingsPage extends StatefulWidget {
  const StudentSettingsPage({super.key});

  @override
  State<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<StudentSettingsPage> {
  late bool _emailNotif;
  late bool _smsNotif;
  late bool _pushNotif;
  late bool _assignmentReminder;
  late bool _feeReminder;
  bool _loaded = false;

  void _loadFromDs(DataService ds) {
    if (_loaded) return;
    final uid = ds.currentUserId ?? '';
    final s = ds.getUserSettings(uid);
    _emailNotif = s['emailNotif'] as bool? ?? true;
    _smsNotif = s['smsNotif'] as bool? ?? false;
    _pushNotif = s['pushNotif'] as bool? ?? true;
    _assignmentReminder = s['assignmentReminder'] as bool? ?? true;
    _feeReminder = s['feeReminder'] as bool? ?? true;
    _loaded = true;
  }

  void _persist(DataService ds) {
    final uid = ds.currentUserId ?? '';
    ds.updateUserSettings(uid, {
      'emailNotif': _emailNotif,
      'smsNotif': _smsNotif,
      'pushNotif': _pushNotif,
      'assignmentReminder': _assignmentReminder,
      'feeReminder': _feeReminder,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      _loadFromDs(ds);
      final student = ds.currentStudent ?? {};
      final uid = ds.currentUserId ?? '';
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.settings, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 24),
              _buildNotificationSettings(),
              const SizedBox(height: 24),
              _buildAccountInfo(student, uid),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Notification Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        _toggle('Email Notifications', _emailNotif, (v) { setState(() => _emailNotif = v); _persist(Provider.of<DataService>(context, listen: false)); }),
        _toggle('SMS Notifications', _smsNotif, (v) { setState(() => _smsNotif = v); _persist(Provider.of<DataService>(context, listen: false)); }),
        _toggle('Push Notifications', _pushNotif, (v) { setState(() => _pushNotif = v); _persist(Provider.of<DataService>(context, listen: false)); }),
        const Divider(color: AppColors.border, height: 24),
        _toggle('Assignment Reminders', _assignmentReminder, (v) { setState(() => _assignmentReminder = v); _persist(Provider.of<DataService>(context, listen: false)); }),
        _toggle('Fee Due Reminders', _feeReminder, (v) { setState(() => _feeReminder = v); _persist(Provider.of<DataService>(context, listen: false)); }),
      ]),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 14))),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
      ]),
    );
  }

  Widget _buildAccountInfo(Map<String, dynamic> student, String uid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Account Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 16),
        _infoRow('Student ID', uid),
        _infoRow('Name', student['name'] ?? '-'),
        _infoRow('Department', student['departmentId'] ?? '-'),
        _infoRow('Year', '${student['year'] ?? '-'}'),
        _infoRow('Section', student['section'] ?? '-'),
        _infoRow('Email', student['email'] ?? '-'),
        _infoRow('Phone', student['phone'] ?? '-'),
        _infoRow('CGPA', '${student['cgpa'] ?? '-'}'),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 140, child: Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
