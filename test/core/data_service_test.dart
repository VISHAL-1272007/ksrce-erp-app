import 'package:flutter_test/flutter_test.dart';
import 'package:ksrce_erp/src/core/data_service.dart';
import 'package:ksrce_erp/src/core/security_service.dart';

void main() {
  late DataService ds;

  setUp(() {
    ds = DataService();

    // Reset singleton state used by these tests.
    ds.departments.clear();
    ds.faculty.clear();
    ds.students.clear();
    ds.courses.clear();
    ds.classes.clear();
    ds.users.clear();
  });

  group('Department CRUD', () {
    test('addDepartment assigns departmentId from code', () {
      ds.addDepartment({
        'departmentName': 'Computer Science and Engineering',
        'departmentCode': 'CSE',
        'hodId': '',
      });

      expect(ds.departments.length, 1);
      expect(ds.departments.first['departmentId'], 'DEPT_CSE');
      expect(ds.departments.first['departmentName'], 'Computer Science and Engineering');
    });

    test('updateDepartment updates matching department', () {
      ds.departments.add({
        'departmentId': 'DEPT_CSE',
        'departmentName': 'Computer Science',
        'departmentCode': 'CSE',
      });

      ds.updateDepartment('DEPT_CSE', {'departmentName': 'Computer Science and Engineering'});

      expect(ds.departments.first['departmentName'], 'Computer Science and Engineering');
    });

    test('deleteDepartment cascades related faculty, students, courses, classes', () {
      ds.departments.addAll([
        {'departmentId': 'DEPT_CSE', 'departmentName': 'Computer Science', 'departmentCode': 'CSE'},
        {'departmentId': 'DEPT_EEE', 'departmentName': 'Electrical', 'departmentCode': 'EEE'},
      ]);

      ds.faculty.addAll([
        {'facultyId': 'FAC001', 'departmentId': 'DEPT_CSE', 'name': 'A'},
        {'facultyId': 'FAC999', 'departmentId': 'DEPT_EEE', 'name': 'B'},
      ]);
      ds.students.addAll([
        {'studentId': 'STU001', 'departmentId': 'DEPT_CSE', 'name': 'S1'},
        {'studentId': 'STU999', 'departmentId': 'DEPT_EEE', 'name': 'S2'},
      ]);
      ds.courses.addAll([
        {'courseId': 'CSE101', 'departmentId': 'DEPT_CSE'},
        {'courseId': 'EEE101', 'departmentId': 'DEPT_EEE'},
      ]);
      ds.classes.addAll([
        {'classId': 'CSE_1_A', 'departmentId': 'DEPT_CSE'},
        {'classId': 'EEE_1_A', 'departmentId': 'DEPT_EEE'},
      ]);

      ds.deleteDepartment('DEPT_CSE');

      expect(ds.departments.any((d) => d['departmentId'] == 'DEPT_CSE'), isFalse);
      expect(ds.faculty.any((f) => f['departmentId'] == 'DEPT_CSE'), isFalse);
      expect(ds.students.any((s) => s['departmentId'] == 'DEPT_CSE'), isFalse);
      expect(ds.courses.any((c) => c['departmentId'] == 'DEPT_CSE'), isFalse);
      expect(ds.classes.any((c) => c['departmentId'] == 'DEPT_CSE'), isFalse);

      expect(ds.departments.any((d) => d['departmentId'] == 'DEPT_EEE'), isTrue);
      expect(ds.faculty.any((f) => f['departmentId'] == 'DEPT_EEE'), isTrue);
      expect(ds.students.any((s) => s['departmentId'] == 'DEPT_EEE'), isTrue);
      expect(ds.courses.any((c) => c['departmentId'] == 'DEPT_EEE'), isTrue);
      expect(ds.classes.any((c) => c['departmentId'] == 'DEPT_EEE'), isTrue);
    });
  });

  group('User creation side effects', () {
    test('addFaculty creates faculty user with hashed default password', () {
      ds.addFaculty({
        'name': 'Dr. Test Faculty',
        'departmentId': 'DEPT_CSE',
      });

      expect(ds.faculty.length, 1);
      expect(ds.users.length, 1);

      final createdFaculty = ds.faculty.first;
      final createdUser = ds.users.first;
      final facultyId = createdFaculty['facultyId'] as String;
      final expectedDefault = 'ksrce@${facultyId.toLowerCase()}';

      expect(createdUser['id'], facultyId);
      expect(createdUser['role'], 'faculty');
      expect(SecurityService.verifyPassword(expectedDefault, facultyId, createdUser['password'] as String), isTrue);
    });

    test('addStudent creates student user and initializes defaults', () {
      ds.addStudent({
        'name': 'Student One',
        'departmentId': 'DEPT_CSE',
        'year': 1,
        'section': 'A',
      });

      expect(ds.students.length, 1);
      expect(ds.users.length, 1);

      final createdStudent = ds.students.first;
      final createdUser = ds.users.first;
      final studentId = createdStudent['studentId'] as String;
      final expectedDefault = 'ksrce@${studentId.toLowerCase()}';

      expect(createdUser['id'], studentId);
      expect(createdUser['role'], 'student');
      expect(createdStudent['enrolledCourses'], isA<List<dynamic>>());
      expect(createdStudent['mentorId'], isNull);
      expect(SecurityService.verifyPassword(expectedDefault, studentId, createdUser['password'] as String), isTrue);
    });

    test('deleteUserById removes admin user and returns true', () {
      ds.users.add({
        'id': 'ADM001',
        'role': 'admin',
        'password': 'hash',
      });

      final deleted = ds.deleteUserById('ADM001');

      expect(deleted, isTrue);
      expect(ds.users.any((u) => u['id'] == 'ADM001'), isFalse);
    });

    test('deleteUserById routes student deletion through cascades', () {
      ds.students.add({'studentId': 'STU001', 'name': 'Student One'});
      ds.users.add({'id': 'STU001', 'role': 'student', 'password': 'hash'});
      ds.classes.add({'classId': 'CSE_1_A', 'studentIds': <String>['STU001']});
      ds.mentorAssignments.add({'mentorId': 'FAC001', 'menteeIds': <String>['STU001']});
      ds.faculty.add({'facultyId': 'FAC001', 'menteeIds': <String>['STU001']});

      final deleted = ds.deleteUserById('STU001');

      expect(deleted, isTrue);
      expect(ds.students.any((s) => s['studentId'] == 'STU001'), isFalse);
      expect(ds.users.any((u) => u['id'] == 'STU001'), isFalse);
      expect((ds.classes.first['studentIds'] as List<dynamic>).contains('STU001'), isFalse);
      expect((ds.mentorAssignments.first['menteeIds'] as List<dynamic>).contains('STU001'), isFalse);
      expect((ds.faculty.first['menteeIds'] as List<dynamic>).contains('STU001'), isFalse);
    });

    test('canViewRoute allows tutor for student STU001', () {
      final hashed = SecurityService.hashPassword('ksrce@stu001', 'STU001');
      ds.users.add({'id': 'STU001', 'role': 'student', 'password': hashed});
      ds.students.add({'studentId': 'STU001', 'name': 'Vishal'});
      final err = ds.loginSecure('STU001', 'ksrce@stu001');
      expect(err, isNull);
      expect(ds.canViewRoute('/student/tutor'), isTrue);
    });
  });
}
