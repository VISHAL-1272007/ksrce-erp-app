import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/data_service.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../../../core/theme/app_colors.dart';

class MasterKeyHubPage extends StatelessWidget {
  final String role;
  const MasterKeyHubPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final options = ds.getAvailableMasterKeys(role: role);
      final activeKey = ds.activeMasterKey;
      final linkedKey = ds.currentMasterKey;
      final activeNode = activeKey == null ? null : ds.getMasterKeyNode(activeKey);
      final activeLabel = activeKey == null ? 'No MasterKey selected' : ds.getMasterKeyLabel(activeKey);
      final linkedLabel = linkedKey == null ? '—' : ds.getMasterKeyLabel(linkedKey);
      final isMobile = MediaQuery.of(context).size.width < 720;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, activeLabel, linkedLabel),
              const SizedBox(height: 16),
              _buildActiveCard(context, ds, activeKey, activeNode, activeLabel, linkedLabel),
              const SizedBox(height: 16),
              _buildQuickActions(context, ds),
              const SizedBox(height: 24),
              const Text(
                'Available MasterKeys',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              if (options.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppCardStyles.elevated,
                  child: const Text(
                    'No MasterKeys available for this portal.',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                )
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: options.map((option) {
                    final key = option['masterKey']?.toString() ?? '';
                    final selected = key == activeKey;
                    return SizedBox(
                      width: isMobile ? double.infinity : 360,
                      child: _MasterKeyCard(
                        title: option['title']?.toString() ?? key,
                        masterKey: key,
                        studentCount: option['studentCount'] as int? ?? 0,
                        facultyCount: option['facultyCount'] as int? ?? 0,
                        selected: selected,
                        onSelect: () async {
                          await ds.setActiveMasterKey(key);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('MasterKey switched to ${ds.getMasterKeyLabel(key)}')),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context, String activeLabel, String linkedLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFE0F2FE)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.hub_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MasterKey Hub',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                SizedBox(height: 4),
                Text(
                  'Pick the academic context you want every portal page to follow.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Active context',
                  style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 280,
                child: Text(
                  activeLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Linked key: $linkedLabel',
                style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(
    BuildContext context,
    DataService ds,
    String? activeKey,
    Map<String, dynamic>? activeNode,
    String activeLabel,
    String linkedLabel,
  ) {
    final studentCount = activeNode == null ? 0 : (activeNode['studentIds'] as List?)?.length ?? 0;
    final facultyCount = activeNode == null ? 0 : (activeNode['facultyIds'] as List?)?.length ?? 0;
    final hodName = activeNode?['hodName']?.toString() ?? '—';
    final deptName = activeNode == null ? '—' : ds.getMasterKeyLabel(activeKey ?? '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current selection',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metaChip(Icons.link_rounded, activeLabel),
              _metaChip(Icons.groups_rounded, '$studentCount students'),
              _metaChip(Icons.badge_rounded, '$facultyCount faculty'),
              _metaChip(Icons.person_pin_rounded, 'HOD: $hodName'),
              _metaChip(Icons.account_tree_rounded, deptName),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: ds.currentMasterKey == null
                    ? null
                    : () async {
                        await ds.setActiveMasterKey(ds.currentMasterKey);
                      },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Use linked key'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: activeKey == null
                    ? null
                    : () async {
                        await ds.setActiveMasterKey(null);
                      },
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Reset override'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Linked key: $linkedLabel',
            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, DataService ds) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back'),
          ),
          OutlinedButton.icon(
            onPressed: () => ds.setActiveMasterKey(ds.currentMasterKey),
            icon: const Icon(Icons.link_rounded),
            label: const Text('Restore linked MasterKey'),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MasterKeyCard extends StatelessWidget {
  final String title;
  final String masterKey;
  final int studentCount;
  final int facultyCount;
  final bool selected;
  final VoidCallback onSelect;

  const _MasterKeyCard({
    required this.title,
    required this.masterKey,
    required this.studentCount,
    required this.facultyCount,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border),
        boxShadow: selected
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Selected',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(masterKey, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(Icons.groups_rounded, '$studentCount students'),
              _pill(Icons.badge_rounded, '$facultyCount faculty'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected ? null : onSelect,
              child: Text(selected ? 'Current context' : 'Switch to this key'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMedium),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
