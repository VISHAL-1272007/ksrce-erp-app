import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ksrce_erp/src/core/data_service.dart';
import 'package:ksrce_erp/src/core/persistence_service.dart';
import 'package:ksrce_erp/src/features/admin/presentation/pages/admin_departments_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<DataService> _buildLoadedDataService() async {
    final seed = {
      'students': <Map<String, dynamic>>[],
      'users': <Map<String, dynamic>>[],
      'courses': <Map<String, dynamic>>[],
      'attendance': <Map<String, dynamic>>[],
      'assignments': <Map<String, dynamic>>[],
      'results': <Map<String, dynamic>>[],
      'timetable': <Map<String, dynamic>>[],
      'notifications': <Map<String, dynamic>>[],
      'complaints': <Map<String, dynamic>>[],
      'departments': <Map<String, dynamic>>[
        {
          'departmentId': 'DEPT_CSE',
          'departmentCode': 'CSE',
          'departmentName': 'Computer Science',
          'hodId': '',
        }
      ],
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
      'ksrce_erp_data': jsonEncode(seed),
      'ksrce_erp_version': 3,
    });

    final ds = DataService();
    await ds.loadAllData();
    return ds;
  }

  testWidgets('department delete requires exact confirmation text', (tester) async {
    final ds = await _buildLoadedDataService();

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: ds,
        child: const MaterialApp(home: AdminDepartmentsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Computer Science'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Department'));
    await tester.pumpAndSettle();

    final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'Delete Permanently');
    ElevatedButton deleteBtn = tester.widget<ElevatedButton>(deleteBtnFinder);
    expect(deleteBtn.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'wrong text');
    await tester.pumpAndSettle();
    deleteBtn = tester.widget<ElevatedButton>(deleteBtnFinder);
    expect(deleteBtn.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'computer science i assure to remove');
    await tester.pumpAndSettle();
    deleteBtn = tester.widget<ElevatedButton>(deleteBtnFinder);
    expect(deleteBtn.onPressed, isNotNull);

    await tester.tap(deleteBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('Computer Science'), findsNothing);
    expect(find.textContaining('deleted permanently'), findsOneWidget);

    await PersistenceService.flush();
  });
}
