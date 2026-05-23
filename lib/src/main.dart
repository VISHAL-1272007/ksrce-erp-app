import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/data_service.dart';
import '../firebase_options.dart';
import 'features/auth/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/shared/widgets/dashboard_shell.dart';

import 'features/student/presentation/pages/student_dashboard_page.dart';
import 'features/student/presentation/pages/student_profile_page.dart';
import 'features/student/presentation/pages/student_courses_page.dart';
import 'features/student/presentation/pages/student_timetable_page.dart';
import 'features/student/presentation/pages/student_syllabus_page.dart';
import 'features/student/presentation/pages/student_attendance_page.dart';
import 'features/student/presentation/pages/student_results_page.dart';
import 'features/student/presentation/pages/student_assignments_page.dart';
import 'features/student/presentation/pages/student_exams_page.dart';
import 'features/student/presentation/pages/student_fees_page.dart';
import 'features/student/presentation/pages/student_library_page.dart';
import 'features/student/presentation/pages/student_notifications_page.dart';
import 'features/student/presentation/pages/student_complaints_page.dart';
import 'features/student/presentation/pages/student_leave_page.dart';
import 'features/student/presentation/pages/student_certificates_page.dart';
import 'features/student/presentation/pages/student_placements_page.dart';
import 'features/student/presentation/pages/student_events_page.dart';
import 'features/student/presentation/pages/student_settings_page.dart';
import 'features/student/presentation/pages/student_portal_page.dart';
import 'features/student/presentation/pages/student_tutor_page.dart';
import 'features/student/presentation/pages/student_notes_page.dart';
import 'features/student/presentation/pages/student_workspace_page.dart';
import 'features/faculty/presentation/pages/faculty_dashboard_page.dart';
import 'features/faculty/presentation/pages/faculty_profile_page.dart';
import 'features/faculty/presentation/pages/faculty_courses_page.dart';
import 'features/faculty/presentation/pages/faculty_timetable_page.dart';
import 'features/faculty/presentation/pages/faculty_syllabus_page.dart';
import 'features/faculty/presentation/pages/faculty_attendance_page.dart';
import 'features/faculty/presentation/pages/faculty_assignments_page.dart';
import 'features/faculty/presentation/pages/faculty_grades_page.dart';
import 'features/faculty/presentation/pages/faculty_students_page.dart';
import 'features/faculty/presentation/pages/faculty_exams_page.dart';
import 'features/faculty/presentation/pages/faculty_leave_page.dart';
import 'features/faculty/presentation/pages/faculty_research_page.dart';
import 'features/faculty/presentation/pages/faculty_notifications_page.dart';
import 'features/faculty/presentation/pages/faculty_complaints_page.dart';
import 'features/faculty/presentation/pages/faculty_reports_page.dart';
import 'features/faculty/presentation/pages/faculty_events_page.dart';
import 'features/faculty/presentation/pages/faculty_settings_page.dart';
import 'features/faculty/presentation/pages/faculty_course_details_page.dart';
import 'features/faculty/presentation/pages/faculty_course_diary_page.dart';
import 'features/faculty/presentation/pages/faculty_mentees_page.dart';
import 'features/faculty/presentation/pages/faculty_adviser_page.dart';
import 'features/faculty/presentation/pages/faculty_generator_page.dart';

import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/admin/presentation/pages/admin_user_management_page.dart';
import 'features/admin/presentation/pages/admin_reports_page.dart';
import 'features/admin/presentation/pages/admin_notifications_page.dart';
import 'features/admin/presentation/pages/admin_settings_page.dart';
import 'features/admin/presentation/pages/admin_departments_page.dart';
import 'features/admin/presentation/pages/admin_faculty_management_page.dart';
import 'features/admin/presentation/pages/admin_student_management_page.dart';
import 'features/admin/presentation/pages/admin_course_management_page.dart';
import 'features/admin/presentation/pages/admin_class_management_page.dart';
import 'features/admin/presentation/pages/admin_hod_assignment_page.dart';

import 'features/hod/presentation/pages/hod_dashboard_page.dart';
import 'features/hod/presentation/pages/hod_faculty_page.dart';
import 'features/hod/presentation/pages/hod_students_page.dart';
import 'features/hod/presentation/pages/hod_courses_page.dart';
import 'features/hod/presentation/pages/hod_class_advisers_page.dart';
import 'features/hod/presentation/pages/hod_mentors_page.dart';
import 'features/hod/presentation/pages/hod_notifications_page.dart';
import 'features/hod/presentation/pages/hod_settings_page.dart';
import 'features/shared/presentation/pages/profile_edit_approvals_page.dart';
import 'features/shared/presentation/pages/master_key_hub_page.dart';
import 'features/shared/presentation/pages/file_manager_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
    );
  final dataService = DataService();
  // Don't block app startup - load data in background
  dataService.loadAllData();
  runApp(KsrceErpApp(dataService: dataService));
}

class KsrceErpApp extends StatelessWidget {
  final DataService dataService;
  const KsrceErpApp({super.key, required this.dataService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: dataService,
      child: MaterialApp.router(
        title: 'KSRCE ERP',
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

Widget _s(String route, Widget child) =>
    DashboardShell(role: 'student', currentRoute: route, child: child);
Widget _f(String route, Widget child) =>
    DashboardShell(role: 'faculty', currentRoute: route, child: child);
Widget _a(String route, Widget child) =>
    DashboardShell(role: 'admin', currentRoute: route, child: child);
Widget _h(String route, Widget child) =>
    DashboardShell(role: 'hod', currentRoute: route, child: child);

// Suspicious query params & patterns that indicate hacking attempts
bool _isSuspiciousUri(Uri uri) {
  // Any query parameters on our routes = suspicious (we don't use any)
  if (uri.queryParameters.isNotEmpty) return true;
  // Check for common attack patterns in the full URL
  final full = uri.toString().toLowerCase();
  final attackPatterns = [
    'select ',
    'union ',
    'drop ',
    'insert ',
    'delete ',
    'update ',
    ' or ',
    "' or ",
    '1=1',
    '--',
    '/*',
    '*/',
    'xp_',
    'exec(',
    '<script',
    'javascript:',
    'onerror',
    'onload',
    'eval(',
    '../',
    '..\\',
    '%2e%2e',
    '%00',
    'etc/passwd',
    'cmd.exe',
    'admin=true',
    'role=admin',
    'token=',
    'password=',
    'passwd=',
    'debug=',
    'test=',
    'hack',
    'exploit',
    'inject',
    'payload',
  ];
  for (final pattern in attackPatterns) {
    if (full.contains(pattern)) return true;
  }
  return false;
}

String? _portalFromPath(String path) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  const protected = {'student', 'faculty', 'admin', 'hod'};
  return protected.contains(segments.first) ? segments.first : null;
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    if (_isSuspiciousUri(state.uri)) {
      return '/hacker-welcome';
    }

    // Extract the path from state.uri.path (handles hash routes correctly)
    final path = state.uri.path;
    final portal = _portalFromPath(path);
    if (portal != null) {
      final ds = Provider.of<DataService>(context, listen: false);
      if (ds.currentUserId == null) {
        return '/login';
      }
      if (ds.currentRole != portal) {
        return ds.getHomeRouteForCurrentUser();
      }
      if (!ds.canViewRoute(path)) {
        return ds.getHomeRouteForCurrentUser();
      }
    }

    return null;
  },
  routes: [
    GoRoute(
        path: '/hacker-welcome', builder: (c, s) => const Scaffold(body: Center(child: Text('Unauthorized Access')))),
    GoRoute(path: '/', builder: (c, s) => const HomePage()),
    // Catch-all for unknown paths handled by errorBuilder below
    GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
    // Student routes
    GoRoute(
        path: '/student/dashboard',
        builder: (c, s) =>
            _s('/student/dashboard', const StudentDashboardPage())),
    GoRoute(
        path: '/student/tutor',
        builder: (c, s) => _s('/student/tutor', const StudentTutorPage())),
    GoRoute(
        path: '/student/notes',
        builder: (c, s) => _s('/student/notes', const StudentNotesPage())),
    GoRoute(
        path: '/student/workspace',
        builder: (c, s) => _s('/student/workspace', const StudentWorkspacePage())),
    GoRoute(
        path: '/student/portal',
        builder: (c, s) => _s('/student/portal', const StudentPortalPage())),
    GoRoute(
        path: '/student/profile',
        builder: (c, s) => _s('/student/profile', const StudentProfilePage())),
    GoRoute(
        path: '/student/courses',
        builder: (c, s) => _s('/student/courses', const StudentCoursesPage())),
    GoRoute(
        path: '/student/timetable',
        builder: (c, s) =>
            _s('/student/timetable', const StudentTimetablePage())),
    GoRoute(
        path: '/student/syllabus',
        builder: (c, s) =>
            _s('/student/syllabus', const StudentSyllabusPage())),
    GoRoute(
        path: '/student/attendance',
        builder: (c, s) =>
            _s('/student/attendance', const StudentAttendancePage())),
    GoRoute(
        path: '/student/results',
        builder: (c, s) => _s('/student/results', const StudentResultsPage())),
    GoRoute(
        path: '/student/assignments',
        builder: (c, s) =>
            _s('/student/assignments', const StudentAssignmentsPage())),
    GoRoute(
        path: '/student/exams',
        builder: (c, s) => _s('/student/exams', const StudentExamsPage())),
    GoRoute(
        path: '/student/fees',
        builder: (c, s) => _s('/student/fees', const StudentFeesPage())),
    GoRoute(
        path: '/student/library',
        builder: (c, s) => _s('/student/library', const StudentLibraryPage())),
    GoRoute(
        path: '/student/notifications',
        builder: (c, s) =>
            _s('/student/notifications', const StudentNotificationsPage())),
    GoRoute(
        path: '/student/complaints',
        builder: (c, s) =>
            _s('/student/complaints', const StudentComplaintsPage())),
    GoRoute(
        path: '/student/leave',
        builder: (c, s) => _s('/student/leave', const StudentLeavePage())),
    GoRoute(
        path: '/student/certificates',
        builder: (c, s) =>
            _s('/student/certificates', const StudentCertificatesPage())),
    GoRoute(
        path: '/student/placements',
        builder: (c, s) =>
            _s('/student/placements', const StudentPlacementsPage())),
    GoRoute(
        path: '/student/events',
        builder: (c, s) => _s('/student/events', const StudentEventsPage())),
    GoRoute(
        path: '/student/settings',
        builder: (c, s) =>
            _s('/student/settings', const StudentSettingsPage())),
    GoRoute(
        path: '/student/files',
        builder: (c, s) => _s('/student/files', const FileManagerPage())),
    // Faculty routes
    GoRoute(
        path: '/faculty/dashboard',
        builder: (c, s) =>
            _f('/faculty/dashboard', const FacultyDashboardPage())),
    GoRoute(
        path: '/faculty/generator',
        builder: (c, s) => _f('/faculty/generator', const FacultyGeneratorPage())),
    GoRoute(
        path: '/faculty/profile',
        builder: (c, s) => _f('/faculty/profile', const FacultyProfilePage())),
    GoRoute(
        path: '/faculty/courses',
        builder: (c, s) => _f('/faculty/courses', const FacultyCoursesPage())),
    GoRoute(
        path: '/faculty/timetable',
        builder: (c, s) =>
            _f('/faculty/timetable', const FacultyTimetablePage())),
    GoRoute(
        path: '/faculty/syllabus',
        builder: (c, s) =>
            _f('/faculty/syllabus', const FacultySyllabusPage())),
    GoRoute(
        path: '/faculty/attendance',
        builder: (c, s) =>
            _f('/faculty/attendance', const FacultyAttendancePage())),
    GoRoute(
        path: '/faculty/assignments',
        builder: (c, s) =>
            _f('/faculty/assignments', const FacultyAssignmentsPage())),
    GoRoute(
        path: '/faculty/grades',
        builder: (c, s) => _f('/faculty/grades', const FacultyGradesPage())),
    GoRoute(
        path: '/faculty/students',
        builder: (c, s) =>
            _f('/faculty/students', const FacultyStudentsPage())),
    GoRoute(
        path: '/faculty/exams',
        builder: (c, s) => _f('/faculty/exams', const FacultyExamsPage())),
    GoRoute(
        path: '/faculty/leave',
        builder: (c, s) => _f('/faculty/leave', const FacultyLeavePage())),
    GoRoute(
        path: '/faculty/research',
        builder: (c, s) =>
            _f('/faculty/research', const FacultyResearchPage())),
    GoRoute(
        path: '/faculty/notifications',
        builder: (c, s) =>
            _f('/faculty/notifications', const FacultyNotificationsPage())),
    GoRoute(
        path: '/faculty/complaints',
        builder: (c, s) =>
            _f('/faculty/complaints', const FacultyComplaintsPage())),
    GoRoute(
        path: '/faculty/reports',
        builder: (c, s) => _f('/faculty/reports', const FacultyReportsPage())),
    GoRoute(
        path: '/faculty/events',
        builder: (c, s) => _f('/faculty/events', const FacultyEventsPage())),
    GoRoute(
        path: '/faculty/course-details',
        builder: (c, s) =>
            _f('/faculty/course-details', const FacultyCourseDetailsPage())),
    GoRoute(
        path: '/faculty/course-diary',
        builder: (c, s) =>
            _f('/faculty/course-diary', const FacultyCourseDiaryPage())),
    GoRoute(
        path: '/faculty/profile-approvals',
        builder: (c, s) =>
            _f('/faculty/profile-approvals', const ProfileEditApprovalsPage())),
    GoRoute(
        path: '/faculty/mentees',
        builder: (c, s) => _f('/faculty/mentees', const FacultyMenteesPage())),
    GoRoute(
        path: '/faculty/adviser',
        builder: (c, s) => _f('/faculty/adviser', const FacultyAdviserPage())),
    GoRoute(
        path: '/faculty/settings',
        builder: (c, s) =>
            _f('/faculty/settings', const FacultySettingsPage())),
    GoRoute(
        path: '/faculty/files',
        builder: (c, s) => _f('/faculty/files', const FileManagerPage())),
    GoRoute(
        path: '/faculty/master-key',
        builder: (c, s) => _f('/faculty/master-key', const MasterKeyHubPage(role: 'faculty'))),
    // Admin routes
    GoRoute(
        path: '/admin/dashboard',
        builder: (c, s) => _a('/admin/dashboard', const AdminDashboardPage())),
    GoRoute(
        path: '/admin/departments',
        builder: (c, s) =>
            _a('/admin/departments', const AdminDepartmentsPage())),
    GoRoute(
        path: '/admin/faculty',
        builder: (c, s) =>
            _a('/admin/faculty', const AdminFacultyManagementPage())),
    GoRoute(
        path: '/admin/students',
        builder: (c, s) =>
            _a('/admin/students', const AdminStudentManagementPage())),
    GoRoute(
        path: '/admin/courses',
        builder: (c, s) =>
            _a('/admin/courses', const AdminCourseManagementPage())),
    GoRoute(
        path: '/admin/classes',
        builder: (c, s) =>
            _a('/admin/classes', const AdminClassManagementPage())),
    GoRoute(
        path: '/admin/hod-assignment',
        builder: (c, s) =>
            _a('/admin/hod-assignment', const AdminHodAssignmentPage())),
    GoRoute(
        path: '/admin/users',
        builder: (c, s) => _a('/admin/users', const AdminUserManagementPage())),
    GoRoute(
        path: '/admin/reports',
        builder: (c, s) => _a('/admin/reports', const AdminReportsPage())),
    GoRoute(
        path: '/admin/notifications',
        builder: (c, s) =>
            _a('/admin/notifications', const AdminNotificationsPage())),
    GoRoute(
        path: '/admin/profile-approvals',
        builder: (c, s) =>
            _a('/admin/profile-approvals', const ProfileEditApprovalsPage())),
    GoRoute(
        path: '/admin/settings',
        builder: (c, s) => _a('/admin/settings', const AdminSettingsPage())),
    GoRoute(
        path: '/admin/files',
        builder: (c, s) => _a('/admin/files', const FileManagerPage())),
    GoRoute(
        path: '/admin/master-key',
        builder: (c, s) => _a('/admin/master-key', const MasterKeyHubPage(role: 'admin'))),
    // HOD routes
    GoRoute(
        path: '/hod/dashboard',
        builder: (c, s) => _h('/hod/dashboard', const HodDashboardPage())),
    GoRoute(
        path: '/hod/profile',
        builder: (c, s) => _h('/hod/profile', const FacultyProfilePage())),
    GoRoute(
        path: '/hod/faculty',
        builder: (c, s) => _h('/hod/faculty', const HodFacultyPage())),
    GoRoute(
        path: '/hod/students',
        builder: (c, s) => _h('/hod/students', const HodStudentsPage())),
    GoRoute(
        path: '/hod/courses',
        builder: (c, s) => _h('/hod/courses', const HodCoursesPage())),
    // HOD teaching routes (reuse faculty pages — they use ds.currentUserId)
    GoRoute(
        path: '/hod/my-courses',
        builder: (c, s) => _h('/hod/my-courses', const FacultyCoursesPage())),
    GoRoute(
        path: '/hod/timetable',
        builder: (c, s) => _h('/hod/timetable', const FacultyTimetablePage())),
    GoRoute(
        path: '/hod/syllabus',
        builder: (c, s) => _h('/hod/syllabus', const FacultySyllabusPage())),
    GoRoute(
        path: '/hod/course-details',
        builder: (c, s) =>
            _h('/hod/course-details', const FacultyCourseDetailsPage())),
    GoRoute(
        path: '/hod/course-diary',
        builder: (c, s) =>
            _h('/hod/course-diary', const FacultyCourseDiaryPage())),
    GoRoute(
        path: '/hod/attendance',
        builder: (c, s) =>
            _h('/hod/attendance', const FacultyAttendancePage())),
    GoRoute(
        path: '/hod/assignments',
        builder: (c, s) =>
            _h('/hod/assignments', const FacultyAssignmentsPage())),
    GoRoute(
        path: '/hod/grades',
        builder: (c, s) => _h('/hod/grades', const FacultyGradesPage())),
    GoRoute(
        path: '/hod/exams',
        builder: (c, s) => _h('/hod/exams', const FacultyExamsPage())),
    GoRoute(
        path: '/hod/leave',
        builder: (c, s) => _h('/hod/leave', const FacultyLeavePage())),
    GoRoute(
        path: '/hod/research',
        builder: (c, s) => _h('/hod/research', const FacultyResearchPage())),
    GoRoute(
        path: '/hod/reports',
        builder: (c, s) => _h('/hod/reports', const FacultyReportsPage())),
    GoRoute(
        path: '/hod/events',
        builder: (c, s) => _h('/hod/events', const FacultyEventsPage())),
    GoRoute(
        path: '/hod/complaints',
        builder: (c, s) =>
            _h('/hod/complaints', const FacultyComplaintsPage())),
    GoRoute(
        path: '/hod/class-advisers',
        builder: (c, s) =>
            _h('/hod/class-advisers', const HodClassAdvisersPage())),
    GoRoute(
        path: '/hod/mentors',
        builder: (c, s) => _h('/hod/mentors', const HodMentorsPage())),
    GoRoute(
        path: '/hod/notifications',
        builder: (c, s) =>
            _h('/hod/notifications', const HodNotificationsPage())),
    GoRoute(
        path: '/hod/profile-approvals',
        builder: (c, s) =>
            _h('/hod/profile-approvals', const ProfileEditApprovalsPage())),
    GoRoute(
        path: '/hod/settings',
        builder: (c, s) => _h('/hod/settings', const HodSettingsPage())),
    GoRoute(
        path: '/hod/files',
        builder: (c, s) => _h('/hod/files', const FileManagerPage())),
    GoRoute(
        path: '/hod/master-key',
        builder: (c, s) => _h('/hod/master-key', const MasterKeyHubPage(role: 'hod'))),
  ],
  errorBuilder: (context, state) => const Scaffold(body: Center(child: Text('Page Not Found'))),
);
