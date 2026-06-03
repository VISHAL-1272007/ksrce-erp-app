import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = Provider.of<DataService>(context);
    final totalStudents = ds.students.length;
    final totalCourses = ds.courses.length;
    final pendingComplaints = ds.complaints.where((c) => c['status'] == 'pending').length;
    final activeUsers = ds.users.length;
    final pendingApprovals = ds.getPendingApprovalCount(ds.currentUserId ?? 'ADM001', 'admin');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(isMobile),
            const SizedBox(height: 24),
            _buildFeatureBanner(isMobile, context),
            const SizedBox(height: 20),
            _buildStatsGrid(isMobile, totalStudents, activeUsers, totalCourses, pendingComplaints, pendingApprovals, context),
            const SizedBox(height: 28),
            if (isMobile) ...[
              _buildQuickActions(context, isMobile),
              const SizedBox(height: 20),
              _buildRecentActivity(ds),
            ] else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: _buildQuickActions(context, isMobile)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildRecentActivity(ds)),
              ]),
          ],
        );
      }),
    );
  }

  Widget _buildWelcomeHeader(bool isMobile) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
        ),
        boxShadow: AppCardStyles.coloredShadow(const Color(0xFF3B82F6)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.15)),
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6).withValues(alpha: 0.05)))),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E40AF).withValues(alpha: 0.2), width: 2),
              ),
              child: CircleAvatar(radius: isMobile ? 22 : 30, backgroundColor: const Color(0xFF1E40AF),
                child: Icon(Icons.admin_panel_settings_rounded, size: isMobile ? 22 : 28, color: Colors.white)),
            ),
            SizedBox(width: isMobile ? 14 : 22),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$greeting,', style: TextStyle(fontSize: isMobile ? 13 : 14, color: const Color(0xFF1E40AF).withValues(alpha: 0.7))),
              const SizedBox(height: 2),
              Text('Administrator', style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A5F), letterSpacing: -0.3)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E40AF).withValues(alpha: 0.12)),
                ),
                child: Text('System Admin  •  KSRCE', style: TextStyle(color: const Color(0xFF1E40AF).withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            ])),
          ]),
        ],
      ),
    );
  }

  Widget _buildFeatureBanner(bool isMobile, BuildContext context) {
    final actions = [
      _BannerAction('Manage Users', Icons.people_rounded, '/admin/users', const Color(0xFF3B82F6)),
      _BannerAction('Reports', Icons.analytics_rounded, '/admin/reports', const Color(0xFFF97316)),
      _BannerAction('Departments', Icons.business_rounded, '/admin/departments', const Color(0xFF10B981)),
      _BannerAction('Approvals', Icons.verified_user_rounded, '/admin/profile-approvals', const Color(0xFF8B5CF6)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF0F9FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E40AF).withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: const Color(0xFF1E40AF).withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                _AdminBadge(label: 'New', color: Color(0xFFF97316)),
                SizedBox(width: 10),
                Expanded(child: Text('Admin Control Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark))),
                _AdminBadge(label: 'Enabled', color: Color(0xFF10B981)),
              ]),
              const SizedBox(height: 8),
              const Text('Fast access to key administrative modules and reporting tools.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: actions.map((a) => _featureChip(context, a)).toList()),
            ])
          : Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF1E40AF).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1E40AF), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Admin Control Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  SizedBox(width: 10),
                  _AdminBadge(label: 'New', color: Color(0xFFF97316)),
                  SizedBox(width: 8),
                  _AdminBadge(label: 'Enabled', color: Color(0xFF10B981)),
                ]),
                SizedBox(height: 4),
                Text('Quick access to user management, reports, departments, and approvals.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
              ])),
              const SizedBox(width: 12),
              Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.end, children: actions.map((a) => _featureChip(context, a)).toList()),
            ]),
    );
  }

  Widget _featureChip(BuildContext context, _BannerAction action) {
    return InkWell(
      onTap: () => context.go(action.route),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [action.tone.withValues(alpha: 0.14), action.tone.withValues(alpha: 0.06)]),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: action.tone.withValues(alpha: 0.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(action.icon, size: 14, color: action.tone),
          const SizedBox(width: 6),
          Text(action.label, style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildStatsGrid(bool isMobile, int totalStudents, int activeUsers, int totalCourses, int pendingComplaints, int pendingApprovals, BuildContext context) {
    final cards = [
      _AdminStat('Students', '$totalStudents', Icons.people_rounded, const Color(0xFF3B82F6), '/admin/students'),
      _AdminStat('Users', '$activeUsers', Icons.person_rounded, const Color(0xFF10B981), '/admin/users'),
      _AdminStat('Courses', '$totalCourses', Icons.menu_book_rounded, const Color(0xFF8B5CF6), '/admin/courses'),
      _AdminStat('Complaints', '$pendingComplaints', Icons.warning_amber_rounded, const Color(0xFFF43F5E), '/admin/reports'),
      _AdminStat('Approvals', '$pendingApprovals', Icons.verified_user_rounded, const Color(0xFFF97316), '/admin/profile-approvals'),
    ];
    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.3,
        children: cards.map((c) => _statCard(c, context)).toList(),
      );
    }
    return Row(children: cards.asMap().entries.map((e) => Expanded(child: Padding(
      padding: EdgeInsets.only(left: e.key > 0 ? 14 : 0), child: _statCard(e.value, context),
    ))).toList());
  }

  Widget _statCard(_AdminStat s, BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(s.route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppCardStyles.statCard(s.color),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: s.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(s.icon, color: s.color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(s.value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.1, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(s.label, style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isMobile) {
    final actions = [
      _QA('Upload Students', Icons.upload_file_rounded, const Color(0xFF3B82F6), '/admin/users'),
      _QA('Manage Users', Icons.people_rounded, const Color(0xFF10B981), '/admin/users'),
      _QA('View Reports', Icons.analytics_rounded, const Color(0xFFF97316), '/admin/reports'),
      _QA('Notifications', Icons.campaign_rounded, const Color(0xFF8B5CF6), '/admin/notifications'),
      _QA('Departments', Icons.business_rounded, const Color(0xFF06B6D4), '/admin/departments'),
      _QA('Settings', Icons.settings_rounded, const Color(0xFF64748B), '/admin/settings'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Quick Actions', icon: Icons.bolt_rounded),
        GridView.count(
          crossAxisCount: isMobile ? 2 : 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: isMobile ? 1.6 : 2.2,
          children: actions.map((a) => _QuickActionTile(action: a)).toList(),
        ),
      ]),
    );
  }

  Widget _buildRecentActivity(DataService ds) {
    final recent = ds.notifications.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Recent Activity', icon: Icons.history_rounded),
        if (recent.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Column(children: [
            Icon(Icons.inbox_rounded, size: 36, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            const Text('No recent activity', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          ])))
        else
          ...recent.asMap().entries.map((entry) {
            final n = entry.value;
            final i = entry.key;
            final isRead = n['isRead'] == true;
            final colors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFF97316), const Color(0xFF8B5CF6), const Color(0xFFF43F5E)];
            final c = colors[i % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRead ? AppColors.surfaceVariant.withValues(alpha: 0.3) : c.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: isRead ? null : Border.all(color: c.withValues(alpha: 0.1)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Icon(isRead ? Icons.check_circle_rounded : Icons.notifications_active_rounded, color: c, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['title'] as String? ?? '', style: TextStyle(
                      color: AppColors.textDark, fontSize: 13,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                    )),
                    const SizedBox(height: 3),
                    Text(n['date'] as String? ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ])),
                ]),
              ),
            );
          }),
      ]),
    );
  }
}

class _AdminStat {
  final String label, value, route;
  final IconData icon;
  final Color color;
  const _AdminStat(this.label, this.value, this.icon, this.color, this.route);
}

class _QA {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QA(this.label, this.icon, this.color, this.route);
}

class _BannerAction {
  final String label;
  final IconData icon;
  final String route;
  final Color tone;
  const _BannerAction(this.label, this.icon, this.route, [this.tone = const Color(0xFF1E40AF)]);
}

class _AdminBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _AdminBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.18))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  final _QA action;
  const _QuickActionTile({required this.action});
  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(a.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? a.color.withValues(alpha: 0.1) : a.color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hovered ? a.color.withValues(alpha: 0.25) : a.color.withValues(alpha: 0.08)),
          ),
          child: Row(children: [
            Icon(a.icon, size: 18, color: a.color),
            const SizedBox(width: 8),
            Flexible(child: Text(a.label, style: TextStyle(
              color: _hovered ? a.color : AppColors.textDark,
              fontSize: 12, fontWeight: FontWeight.w600,
            ), overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}
