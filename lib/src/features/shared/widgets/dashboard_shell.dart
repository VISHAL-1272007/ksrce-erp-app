import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/data_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';

class NavItem {
  final String title;
  final IconData icon;
  final String route;
  final List<NavItem>? children;
  NavItem({required this.title, required this.icon, required this.route, this.children});
}

class DashboardShell extends StatefulWidget {
  final Widget child;
  final String role; // 'student', 'faculty', 'hod', or 'admin'
  final String currentRoute;
  const DashboardShell({super.key, required this.child, required this.role, required this.currentRoute});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  bool _isSidebarCollapsed = false;
  final Map<String, bool> _expandedGroups = {};

  List<NavItem> get _navItems {
    if (widget.role == 'student') {
      return [
        NavItem(title: 'Dashboard', icon: Icons.dashboard, route: '/student/dashboard'),
        NavItem(title: 'Portal Home', icon: Icons.apps, route: '/student/portal'),
        NavItem(title: 'Profile', icon: Icons.person, route: '/student/profile'),
        NavItem(title: 'Academics', icon: Icons.school, route: '', children: [
          NavItem(title: 'My Courses', icon: Icons.book, route: '/student/courses'),
          NavItem(title: 'Timetable', icon: Icons.schedule, route: '/student/timetable'),
          NavItem(title: 'Syllabus', icon: Icons.description, route: '/student/syllabus'),
          NavItem(title: 'AI Tutor', icon: Icons.smart_toy, route: '/student/tutor'),
          NavItem(title: 'Smart Notes', icon: Icons.edit_document, route: '/student/notes'),
          NavItem(title: 'Workspace', icon: Icons.group_work, route: '/student/workspace'),
        ]),
        NavItem(title: 'Performance', icon: Icons.trending_up, route: '', children: [
          NavItem(title: 'Attendance', icon: Icons.fact_check, route: '/student/attendance'),
          NavItem(title: 'Results', icon: Icons.assessment, route: '/student/results'),
          NavItem(title: 'Assignments', icon: Icons.assignment, route: '/student/assignments'),
        ]),
        NavItem(title: 'Exam Schedule', icon: Icons.event_note, route: '/student/exams'),
        NavItem(title: 'Fee Details', icon: Icons.payment, route: '/student/fees'),
        NavItem(title: 'Library', icon: Icons.local_library, route: '/student/library'),
        NavItem(title: 'Notifications', icon: Icons.notifications, route: '/student/notifications'),
        NavItem(title: 'Services', icon: Icons.miscellaneous_services, route: '', children: [
          NavItem(title: 'Complaints', icon: Icons.report_problem, route: '/student/complaints'),
          NavItem(title: 'Leave Apply', icon: Icons.event_busy, route: '/student/leave'),
          NavItem(title: 'Certificates', icon: Icons.card_membership, route: '/student/certificates'),
        ]),
        NavItem(title: 'Placements', icon: Icons.work, route: '/student/placements'),
        NavItem(title: 'Events', icon: Icons.event, route: '/student/events'),
        NavItem(title: 'Files', icon: Icons.cloud_upload, route: '/student/files'),
        NavItem(title: 'Settings', icon: Icons.settings, route: '/student/settings'),
      ];
    } else if (widget.role == 'admin') {
      return [
        NavItem(title: 'Dashboard', icon: Icons.dashboard, route: '/admin/dashboard'),
        NavItem(title: 'Departments', icon: Icons.business, route: '/admin/departments'),
        NavItem(title: 'Management', icon: Icons.manage_accounts, route: '', children: [
          NavItem(title: 'Faculty Mgmt', icon: Icons.person_add, route: '/admin/faculty'),
          NavItem(title: 'Student Mgmt', icon: Icons.group_add, route: '/admin/students'),
          NavItem(title: 'Course Mgmt', icon: Icons.menu_book, route: '/admin/courses'),
          NavItem(title: 'Class Mgmt', icon: Icons.class_, route: '/admin/classes'),
        ]),
        NavItem(title: 'HOD Assignment', icon: Icons.supervisor_account, route: '/admin/hod-assignment'),
        NavItem(title: 'User Management', icon: Icons.people, route: '/admin/users'),
        NavItem(title: 'Profile Approvals', icon: Icons.verified_user, route: '/admin/profile-approvals'),
        NavItem(title: 'Reports', icon: Icons.analytics, route: '/admin/reports'),
        NavItem(title: 'Notifications', icon: Icons.notifications, route: '/admin/notifications'),
        NavItem(title: 'Files', icon: Icons.cloud_upload, route: '/admin/files'),
        NavItem(title: 'Settings', icon: Icons.settings, route: '/admin/settings'),
      ];
    } else if (widget.role == 'hod') {
      return [
        NavItem(title: 'Dashboard', icon: Icons.dashboard, route: '/hod/dashboard'),
        NavItem(title: 'Profile', icon: Icons.person, route: '/hod/profile'),
        NavItem(title: 'Department', icon: Icons.business, route: '', children: [
          NavItem(title: 'Faculty', icon: Icons.people, route: '/hod/faculty'),
          NavItem(title: 'Students', icon: Icons.school, route: '/hod/students'),
          NavItem(title: 'Courses', icon: Icons.menu_book, route: '/hod/courses'),
        ]),
        NavItem(title: 'Teaching', icon: Icons.school, route: '', children: [
          NavItem(title: 'My Courses', icon: Icons.book, route: '/hod/my-courses'),
          NavItem(title: 'Timetable', icon: Icons.schedule, route: '/hod/timetable'),
          NavItem(title: 'Syllabus', icon: Icons.description, route: '/hod/syllabus'),
          NavItem(title: 'Course Details', icon: Icons.list_alt, route: '/hod/course-details'),
          NavItem(title: 'Course Diary', icon: Icons.edit_calendar, route: '/hod/course-diary'),
        ]),
        NavItem(title: 'Management', icon: Icons.manage_accounts, route: '', children: [
          NavItem(title: 'Attendance', icon: Icons.fact_check, route: '/hod/attendance'),
          NavItem(title: 'Assignments', icon: Icons.assignment, route: '/hod/assignments'),
          NavItem(title: 'Grade Entry', icon: Icons.grading, route: '/hod/grades'),
          NavItem(title: 'Exams', icon: Icons.event_note, route: '/hod/exams'),
        ]),
        NavItem(title: 'Dept Admin', icon: Icons.assignment_ind, route: '', children: [
          NavItem(title: 'Class Advisers', icon: Icons.person_pin, route: '/hod/class-advisers'),
          NavItem(title: 'Mentors', icon: Icons.group, route: '/hod/mentors'),
        ]),
        NavItem(title: 'Leave Mgmt', icon: Icons.event_busy, route: '/hod/leave'),
        NavItem(title: 'Research', icon: Icons.science, route: '/hod/research'),
        NavItem(title: 'Notifications', icon: Icons.notifications, route: '/hod/notifications'),
        NavItem(title: 'Profile Approvals', icon: Icons.verified_user, route: '/hod/profile-approvals'),
        NavItem(title: 'Reports', icon: Icons.analytics, route: '/hod/reports'),
        NavItem(title: 'Events', icon: Icons.event, route: '/hod/events'),
        NavItem(title: 'Files', icon: Icons.cloud_upload, route: '/hod/files'),
        NavItem(title: 'Settings', icon: Icons.settings, route: '/hod/settings'),
      ];
    } else {
      return [
        NavItem(title: 'Dashboard', icon: Icons.dashboard, route: '/faculty/dashboard'),
        NavItem(title: 'Profile', icon: Icons.person, route: '/faculty/profile'),
        NavItem(title: 'Academics', icon: Icons.school, route: '', children: [
          NavItem(title: 'My Courses', icon: Icons.book, route: '/faculty/courses'),
          NavItem(title: 'Timetable', icon: Icons.schedule, route: '/faculty/timetable'),
          NavItem(title: 'Syllabus', icon: Icons.description, route: '/faculty/syllabus'),
          NavItem(title: 'Course Generator', icon: Icons.auto_awesome, route: '/faculty/generator'),
        ]),
        NavItem(title: 'Management', icon: Icons.manage_accounts, route: '', children: [
          NavItem(title: 'Attendance', icon: Icons.fact_check, route: '/faculty/attendance'),
          NavItem(title: 'Assignments', icon: Icons.assignment, route: '/faculty/assignments'),
          NavItem(title: 'AI Grade Entry', icon: Icons.grading, route: '/faculty/grades'),
          NavItem(title: 'Student List', icon: Icons.people, route: '/faculty/students'),
        ]),
        NavItem(title: 'Mentoring', icon: Icons.supervisor_account, route: '', children: [
          NavItem(title: 'My Mentees', icon: Icons.group, route: '/faculty/mentees'),
          NavItem(title: 'Class Adviser', icon: Icons.shield, route: '/faculty/adviser'),
        ]),
        NavItem(title: 'Exams', icon: Icons.event_note, route: '/faculty/exams'),
        NavItem(title: 'Leave Mgmt', icon: Icons.event_busy, route: '/faculty/leave'),
        NavItem(title: 'Course Details', icon: Icons.list_alt, route: '/faculty/course-details'),
        NavItem(title: 'Course Diary', icon: Icons.edit_calendar, route: '/faculty/course-diary'),
        NavItem(title: 'Research', icon: Icons.science, route: '/faculty/research'),
        NavItem(title: 'Notifications', icon: Icons.notifications, route: '/faculty/notifications'),
        NavItem(title: 'Profile Approvals', icon: Icons.verified_user, route: '/faculty/profile-approvals'),
        NavItem(title: 'Complaints', icon: Icons.report_problem, route: '/faculty/complaints'),
        NavItem(title: 'Reports', icon: Icons.analytics, route: '/faculty/reports'),
        NavItem(title: 'Events', icon: Icons.event, route: '/faculty/events'),
        NavItem(title: 'Files', icon: Icons.cloud_upload, route: '/faculty/files'),
        NavItem(title: 'Settings', icon: Icons.settings, route: '/faculty/settings'),
      ];
    }
  }

  List<NavItem> get _visibleNavItems {
    final ds = Provider.of<DataService>(context, listen: false);
    return _navItems
        .map((item) {
          if (item.children != null && item.children!.isNotEmpty) {
            final children = item.children!
                .where((child) => child.route.isNotEmpty && ds.canViewRoute(child.route))
                .toList();
            if (children.isEmpty) return null;
            return NavItem(
              title: item.title,
              icon: item.icon,
              route: item.route,
              children: children,
            );
          }

          if (item.route.isEmpty || ds.canViewRoute(item.route)) {
            return item;
          }
          return null;
        })
        .whereType<NavItem>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    if (isMobile) {
      return Scaffold(
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
          ),
          child: widget.child,
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final portalName = widget.role == 'student' ? 'Student Portal'
        : widget.role == 'admin' ? 'Admin Portal'
        : widget.role == 'hod' ? 'HOD Portal'
        : 'Faculty Portal';
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
            ),
            child: const Icon(Icons.school_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(portalName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
      iconTheme: const IconThemeData(color: AppColors.textDark),
      actions: [
        _buildMasterKeyControl(compact: true),
        const SizedBox(width: 8),
        _buildMasterKeyControl(compact: true),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Builder(
            builder: (context) {
              final ds = Provider.of<DataService>(context, listen: false);
              final userId = ds.currentUserId ?? 'STU001';
              return StreamBuilder<int>(
                stream: NotificationService().getUnreadCountStream(userId),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, size: 20),
                        onPressed: () => context.go('/${widget.role}/notifications'),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                }
              );
            }
          ),
        ),
        _buildProfileMenu(),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildProfileMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: const CircleAvatar(
          radius: 15,
          backgroundColor: Colors.transparent,
          child: Icon(Icons.person_rounded, size: 17, color: Colors.white),
        ),
      ),
      color: AppColors.surface,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 8),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'profile', child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Profile', style: TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
        ])),
        PopupMenuItem(value: 'settings', child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.textLight.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.settings_outlined, color: AppColors.textMedium, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Settings', style: TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
        ])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.logout_rounded, color: AppColors.error, size: 16),
          ),
          const SizedBox(width: 10),
          Text('Logout', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
        ])),
      ],
      onSelected: (value) {
        if (value == 'logout') { context.go('/login'); }
        else if (value == 'profile') { context.go('/${widget.role}/profile'); }
        else if (value == 'settings') { context.go('/${widget.role}/settings'); }
      },
    );
  }

  Widget _buildMasterKeyControl({bool compact = false}) {
    return Builder(builder: (context) {
      final ds = Provider.of<DataService>(context, listen: false);
      final activeKey = ds.activeMasterKey;
      final label = activeKey == null ? 'MasterKey' : ds.getMasterKeyLabel(activeKey);
      final options = ds.getAvailableMasterKeys(role: widget.role);
      final route = '/${widget.role}/master-key';

      return PopupMenuButton<String>(
        tooltip: 'MasterKey',
        offset: const Offset(0, 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (value) async {
          if (value == 'hub') {
            context.go(route);
            return;
          }
          if (value == 'reset') {
            await ds.setActiveMasterKey(null);
            return;
          }
          await ds.setActiveMasterKey(value);
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'hub',
            child: Row(
              children: const [
                Icon(Icons.hub_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Open MasterKey Hub'),
              ],
            ),
          ),
          if (options.isNotEmpty) const PopupMenuDivider(),
          ...options.map((option) {
            final key = option['masterKey']?.toString() ?? '';
            final selected = key == activeKey;
            return PopupMenuItem<String>(
              value: key,
              child: Row(
                children: [
                  Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                      size: 18, color: selected ? AppColors.primary : AppColors.textLight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option['title']?.toString() ?? key,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (activeKey != null) const PopupMenuDivider(),
          if (activeKey != null)
            const PopupMenuItem<String>(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.clear_rounded, size: 18, color: AppColors.textMedium),
                  SizedBox(width: 10),
                  Text('Reset override'),
                ],
              ),
            ),
        ],
        child: Container(
          constraints: BoxConstraints(maxWidth: compact ? 210 : 280),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub_rounded, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textMedium),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Builder(builder: (context) {
            final ds = Provider.of<DataService>(context, listen: false);
            String displayName;
            String displayId;
            if (widget.role == 'student') {
              displayName = ds.currentStudent?['name']?.toString() ?? 'Student';
              displayId = ds.currentUserId ?? '';
            } else if (widget.role == 'admin') {
              displayName = 'Administrator';
              displayId = ds.currentUserId ?? 'ADM001';
            } else {
              displayName = ds.currentFaculty?['name']?.toString() ?? (widget.role == 'hod' ? 'Head of Department' : 'Faculty');
              displayId = ds.currentUserId ?? '';
            }
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF3B82F6),
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(displayId, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            );
          }),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: _visibleNavItems.map((item) => _buildDrawerItem(item)).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.go('/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error.withValues(alpha: 0.7), size: 18),
                    const SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: AppColors.error.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(NavItem item) {
    final isActive = widget.currentRoute == item.route;
    if (item.children != null && item.children!.isNotEmpty) {
      final isChildActive = item.children!.any((c) => widget.currentRoute == c.route);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: ExpansionTile(
          leading: Icon(item.icon, color: isChildActive ? AppColors.primary : AppColors.textLight, size: 19),
          title: Text(item.title, style: TextStyle(
            color: isChildActive ? AppColors.primary : AppColors.textDark,
            fontSize: 13,
            fontWeight: isChildActive ? FontWeight.w600 : FontWeight.w500,
          )),
          iconColor: AppColors.textMuted,
          collapsedIconColor: AppColors.textMuted,
          initiallyExpanded: isChildActive,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          children: item.children!.map((child) {
            final childActive = widget.currentRoute == child.route;
            return Padding(
              padding: const EdgeInsets.only(left: 24),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                dense: true,
                visualDensity: const VisualDensity(vertical: -2),
                leading: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: childActive ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.4),
                  ),
                ),
                minLeadingWidth: 14,
                title: Text(child.title, style: TextStyle(
                  color: childActive ? AppColors.primary : AppColors.textMedium,
                  fontSize: 13,
                  fontWeight: childActive ? FontWeight.w600 : FontWeight.w400,
                )),
                selected: childActive,
                selectedTileColor: AppColors.primary.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () { Navigator.pop(context); context.go(child.route); },
              ),
            );
          }).toList(),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        leading: Icon(item.icon, color: isActive ? AppColors.primary : AppColors.textLight, size: 19),
        title: Text(item.title, style: TextStyle(
          color: isActive ? AppColors.primary : AppColors.textDark,
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        )),
        selected: isActive,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () { Navigator.pop(context); context.go(item.route); },
      ),
    );
  }

  Widget _buildSidebar() {
    final sidebarWidth = _isSidebarCollapsed ? 72.0 : 264.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Brand Header ──
          Container(
            height: 68,
            padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 12 : 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                  ),
                  child: const Icon(Icons.school_rounded, size: 20, color: Colors.white),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KSRCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5)),
                        Text('ERP System', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                ],
                if (!_isSidebarCollapsed) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.menu_open_rounded, color: Colors.white70, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isSidebarCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_rounded, color: AppColors.textLight, size: 18),
                ),
              ),
            ),
          // ── Nav Items ──
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: _isSidebarCollapsed ? 8 : 10),
              children: [
                if (!_isSidebarCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 6, top: 2),
                    child: Text('NAVIGATION', style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    )),
                  ),
                ..._visibleNavItems.map((item) => _buildSidebarItem(item)),
              ],
            ),
          ),
          // ── Bottom Section ──
          Container(
            padding: EdgeInsets.all(_isSidebarCollapsed ? 8 : 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
            ),
            child: _isSidebarCollapsed
              ? Tooltip(
                  message: 'Logout',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go('/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.logout_rounded, color: AppColors.error.withValues(alpha: 0.7), size: 20),
                    ),
                  ),
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/login'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.error.withValues(alpha: 0.7), size: 18),
                        const SizedBox(width: 10),
                        Text('Logout', style: TextStyle(
                          color: AppColors.error.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        )),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(NavItem item) {
    final isActive = widget.currentRoute == item.route;
    final hasChildren = item.children != null && item.children!.isNotEmpty;
    final isChildActive = hasChildren && item.children!.any((c) => widget.currentRoute == c.route);
    final isExpanded = _expandedGroups[item.title] ?? isChildActive;

    if (_isSidebarCollapsed) {
      if (hasChildren) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: PopupMenuButton<String>(
            tooltip: item.title,
            position: PopupMenuPosition.over,
            color: AppColors.surface,
            offset: const Offset(60, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
            itemBuilder: (context) => item.children!.map((child) => PopupMenuItem(
              value: child.route,
              child: Row(children: [
                Icon(child.icon, size: 16, color: widget.currentRoute == child.route ? AppColors.primary : AppColors.textLight),
                const SizedBox(width: 10),
                Text(child.title, style: TextStyle(
                  color: widget.currentRoute == child.route ? AppColors.primary : AppColors.textDark,
                  fontSize: 13,
                  fontWeight: widget.currentRoute == child.route ? FontWeight.w600 : FontWeight.w400,
                )),
              ]),
            )).toList(),
            onSelected: (route) => context.go(route),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isChildActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: isChildActive ? AppColors.primary : AppColors.textLight, size: 20),
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Tooltip(
          message: item.title,
          preferBelow: false,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.go(item.route),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.15)) : null,
              ),
              child: Icon(item.icon, color: isActive ? AppColors.primary : AppColors.textLight, size: 20),
            ),
          ),
        ),
      );
    }

    // ── Expanded sidebar ──
    if (hasChildren) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _expandedGroups[item.title] = !isExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isChildActive ? AppColors.primary.withValues(alpha: 0.06) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: isChildActive ? AppColors.primary : AppColors.textLight, size: 19),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.title, style: TextStyle(
                      color: isChildActive ? AppColors.primary : AppColors.textDark,
                      fontSize: 13,
                      fontWeight: isChildActive ? FontWeight.w600 : FontWeight.w500,
                    ))),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(Icons.expand_more_rounded, color: AppColors.textMuted, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              sizeCurve: Curves.easeInOut,
              firstChild: Padding(
                padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1.5)),
                  ),
                  child: Column(
                    children: item.children!.map((child) {
                      final childActive = widget.currentRoute == child.route;
                      return Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => context.go(child.route),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: childActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: childActive ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(child.title, style: TextStyle(
                                  color: childActive ? AppColors.primary : AppColors.textMedium,
                                  fontSize: 13,
                                  fontWeight: childActive ? FontWeight.w600 : FontWeight.w400,
                                )),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(item.route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.15)) : null,
          ),
          child: Row(
            children: [
              Icon(item.icon, color: isActive ? AppColors.primary : AppColors.textLight, size: 19),
              const SizedBox(width: 12),
              Expanded(child: Text(item.title, style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textDark,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ))),
              if (isActive)
                Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final portalName = widget.role == 'student' ? 'Student Portal'
        : widget.role == 'admin' ? 'Admin Portal'
        : widget.role == 'hod' ? 'HOD Portal'
        : 'Faculty Portal';
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text(portalName, style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                )),
              ],
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textMedium, size: 20),
              onPressed: () => context.go('/${widget.role}/notifications'),
              splashRadius: 20,
            ),
          ),
          const SizedBox(width: 10),
          _buildProfileMenu(),
        ],
      ),
    );
  }
}

