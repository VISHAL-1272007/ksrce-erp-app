import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ksrce_erp/src/core/data_service.dart';
import 'package:ksrce_erp/src/core/persistence_service.dart';
import 'package:ksrce_erp/src/features/admin/presentation/pages/admin_faculty_management_page.dart';
import 'package:ksrce_erp/src/features/admin/presentation/pages/admin_student_management_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<DataService> _buildLoadedDataService() async {
    final emptySeed = {
      'students': <Map<String, dynamic>>[],
      'users': <Map<String, dynamic>>[],
      'courses': <Map<String, dynamic>>[],
      'attendance': <Map<String, dynamic>>[],
      'assignments': <Map<String, dynamic>>[],
      'results': <Map<String, dynamic>>[],
      'timetable': <Map<String, dynamic>>[],
      'notifications': <Map<String, dynamic>>[],
      'complaints': <Map<String, dynamic>>[],
      'departments': <Map<String, dynamic>>[],
      'faculty': <Map<String, dynamic>>[],
      'classes': <Map<String, dynamic>>[],
      'mentorAssignments': <Map<String, dynamic>>[],
      'exams': <Map<String, dynamic>>[],
      'fees': <Map<String, dynamic>>[],
      'certificates': <Map<String, dynamic>>[],
      'events': <Map<String, dynamic>>[],
      'eventRegistrations': <Map<String, dynamic>>[],
      'leave': <Map<String, dynamic>>[],
      'leaveBalance': <Map<String, dynamic>>[],
      'library': <Map<String, dynamic>>[],
      'placements': <Map<String, dynamic>>[],
      'placementApplications': <Map<String, dynamic>>[],
      'syllabus': <Map<String, dynamic>>[],
      'research': <Map<String, dynamic>>[],
      'facultyTimetable': <Map<String, dynamic>>[],
      'courseOutcomes': <Map<String, dynamic>>[],
      'courseDiary': <Map<String, dynamic>>[],
      'profileEditRequests': <Map<String, dynamic>>[],
      'settings': <String, dynamic>{},
    };

    SharedPreferences.setMockInitialValues({
      'ksrce_erp_data': jsonEncode(emptySeed),
      'ksrce_erp_version': 3,
    });

    final ds = DataService();
    if (!ds.isLoaded) {
      await ds.loadAllData();
    }

    // Reset mutable lists between tests for singleton safety.
    ds.departments.clear();
    ds.faculty.clear();
    ds.students.clear();
    ds.users.clear();
    ds.courses.clear();
    ds.classes.clear();
    ds.mentorAssignments.clear();

    return ds;
  }

  testWidgets('faculty delete requires exact confirmation text', (tester) async {
    final ds = await _buildLoadedDataService();
    ds.departments.add({
      'departmentId': 'DEPT_CSE',
      'departmentCode': 'CSE',
      'departmentName': 'Computer Science',
      'hodId': '',
    });
    ds.faculty.add({
      'facultyId': 'FAC001',
      'name': 'Dr Test Faculty',
      'departmentId': 'DEPT_CSE',
      'designation': 'Professor',
      'isHOD': false,
      'isClassAdviser': false,
      'adviserFor': null,
      'menteeIds': <String>[],
      'courseIds': <String>[],
    });
    ds.users.add({'id': 'FAC001', 'role': 'faculty', 'password': 'x'});

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: ds,
        child: const MaterialApp(home: AdminFacultyManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dr Test Faculty'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Faculty'));
    await tester.pumpAndSettle();

    final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'Delete Permanently');
    final confirmFieldFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Type confirmation text',
    );
    ElevatedButton deleteBtn = tester.widget(deleteBtnFinder);
    expect(deleteBtn.onPressed, isNull);

    await tester.enterText(confirmFieldFinder, 'wrong');
    await tester.pumpAndSettle();
    deleteBtn = tester.widget(deleteBtnFinder);
    expect(deleteBtn.onPressed, isNull);

    await tester.enterText(confirmFieldFinder, 'dr test faculty i assure to remove');
    await tester.pumpAndSettle();
    deleteBtn = tester.widget(deleteBtnFinder);
    expect(deleteBtn.onPressed, isNotNull);

    await tester.tap(deleteBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('Dr Test Faculty'), findsNothing);
    await PersistenceService.flush();
  });

  testWidgets('student delete requires exact confirmation text', (tester) async {
    final ds = await _buildLoadedDataService();
    ds.departments.add({
      'departmentId': 'DEPT_CSE',
      'departmentCode': 'CSE',
      'departmentName': 'Computer Science',
      'hodId': '',
    });
    ds.students.add({
      'studentId': 'STU001',
      'name': 'Student Test',
      'departmentId': 'DEPT_CSE',
      'year': 1,
      'section': 'A',
      'enrolledCourses': <String>[],
      'mentorId': null,
      'classAdviserId': null,
    });
    ds.users.add({'id': 'STU001', 'role': 'student', 'password': 'x'});

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: ds,
        child: const MaterialApp(home: AdminStudentManagementPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student Test'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Student'));
    await tester.pumpAndSettle();

    final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'Delete Permanently');
    final confirmFieldFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Type confirmation text',
    );
    ElevatedButton deleteBtn = tester.widget(deleteBtnFinder);
    expect(deleteBtn.onPressed, isNull);

    await tester.enterText(confirmFieldFinder, 'wrong');
    await tester.pumpAndSettle();
    deleteBtn = tester.widget(deleteBtnFinder);
    expect(deleteBtn.onPressed, isNull);

    await tester.enterText(confirmFieldFinder, 'student test i assure to remove');
    await tester.pumpAndSettle();
    deleteBtn = tester.widget(deleteBtnFinder);
    expect(deleteBtn.onPressed, isNotNull);

    await tester.tap(deleteBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('Student Test'), findsNothing);
    await PersistenceService.flush();
  });
}
