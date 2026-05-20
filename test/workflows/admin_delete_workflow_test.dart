import 'package:flutter_test/flutter_test.dart';
import 'package:ksrce_erp/src/core/data_service.dart';

void main() {
  late DataService ds;

  setUp(() {
    ds = DataService();
    ds.departments.clear();
    ds.faculty.clear();
    ds.students.clear();
    ds.courses.clear();
    ds.classes.clear();
    ds.users.clear();
    ds.mentorAssignments.clear();
  });

  test('admin delete workflow keeps data consistent across user and department deletes', () {
    ds.departments.addAll([
      {
        'departmentId': 'DEPT_CSE',
        'departmentCode': 'CSE',
        'departmentName': 'Computer Science',
        'hodId': 'FAC001',
      },
      {
        'departmentId': 'DEPT_EEE',
        'departmentCode': 'EEE',
        'departmentName': 'Electrical',
        'hodId': '',
      },
    ]);

    ds.faculty.addAll([
      {
        'facultyId': 'FAC001',
        'name': 'Dr. CSE HOD',
        'departmentId': 'DEPT_CSE',
        'isHOD': true,
        'isClassAdviser': true,
        'adviserFor': 'CSE_1_A',
        'menteeIds': <String>['STU001'],
        'courseIds': <String>['CSE101'],
      },
      {
        'facultyId': 'FAC999',
        'name': 'Dr. EEE Faculty',
        'departmentId': 'DEPT_EEE',
        'isHOD': false,
        'isClassAdviser': false,
        'adviserFor': null,
        'menteeIds': <String>[],
        'courseIds': <String>['EEE101'],
      },
    ]);

    ds.students.addAll([
      {
        'studentId': 'STU001',
        'name': 'Student One',
        'departmentId': 'DEPT_CSE',
        'mentorId': 'FAC001',
        'classAdviserId': 'FAC001',
        'enrolledCourses': <String>['CSE101'],
      },
      {
        'studentId': 'STU999',
        'name': 'Student EEE',
        'departmentId': 'DEPT_EEE',
        'mentorId': null,
        'classAdviserId': null,
        'enrolledCourses': <String>['EEE101'],
      },
    ]);

    ds.users.addAll([
      {'id': 'FAC001', 'role': 'faculty', 'password': 'x'},
      {'id': 'FAC999', 'role': 'faculty', 'password': 'x'},
      {'id': 'STU001', 'role': 'student', 'password': 'x'},
      {'id': 'STU999', 'role': 'student', 'password': 'x'},
      {'id': 'ADM001', 'role': 'admin', 'password': 'x'},
    ]);

    ds.courses.addAll([
      {'courseId': 'CSE101', 'departmentId': 'DEPT_CSE'},
      {'courseId': 'EEE101', 'departmentId': 'DEPT_EEE'},
    ]);

    ds.classes.addAll([
      {
        'classId': 'CSE_1_A',
        'departmentId': 'DEPT_CSE',
        'classAdviserId': 'FAC001',
        'studentIds': <String>['STU001'],
      },
      {
        'classId': 'EEE_1_A',
        'departmentId': 'DEPT_EEE',
        'classAdviserId': null,
        'studentIds': <String>['STU999'],
      },
    ]);

    ds.mentorAssignments.addAll([
      {
        'mentorId': 'FAC001',
        'departmentId': 'DEPT_CSE',
        'menteeIds': <String>['STU001'],
      },
      {
        'mentorId': 'FAC999',
        'departmentId': 'DEPT_EEE',
        'menteeIds': <String>['STU999'],
      },
    ]);

    // Step A: remove one student user.
    final removedStudent = ds.deleteUserById('STU001');
    expect(removedStudent, isTrue);
    expect(ds.students.any((s) => s['studentId'] == 'STU001'), isFalse);
    expect(ds.users.any((u) => u['id'] == 'STU001'), isFalse);
    expect((ds.classes.firstWhere((c) => c['classId'] == 'CSE_1_A')['studentIds'] as List<dynamic>).contains('STU001'), isFalse);

    // Step B: remove one admin user (should not touch students/faculty).
    final removedAdmin = ds.deleteUserById('ADM001');
    expect(removedAdmin, isTrue);
    expect(ds.users.any((u) => u['id'] == 'ADM001'), isFalse);
    expect(ds.faculty.any((f) => f['facultyId'] == 'FAC999'), isTrue);
    expect(ds.students.any((s) => s['studentId'] == 'STU999'), isTrue);

    // Step C: remove CSE department and verify cascade.
    ds.deleteDepartment('DEPT_CSE');
    expect(ds.departments.any((d) => d['departmentId'] == 'DEPT_CSE'), isFalse);
    expect(ds.faculty.any((f) => f['departmentId'] == 'DEPT_CSE'), isFalse);
    expect(ds.students.any((s) => s['departmentId'] == 'DEPT_CSE'), isFalse);
    expect(ds.courses.any((c) => c['departmentId'] == 'DEPT_CSE'), isFalse);
    expect(ds.classes.any((c) => c['departmentId'] == 'DEPT_CSE'), isFalse);

    // EEE data remains intact.
    expect(ds.departments.any((d) => d['departmentId'] == 'DEPT_EEE'), isTrue);
    expect(ds.faculty.any((f) => f['departmentId'] == 'DEPT_EEE'), isTrue);
    expect(ds.students.any((s) => s['departmentId'] == 'DEPT_EEE'), isTrue);
    expect(ds.courses.any((c) => c['departmentId'] == 'DEPT_EEE'), isTrue);
    expect(ds.classes.any((c) => c['departmentId'] == 'DEPT_EEE'), isTrue);
  });
}
