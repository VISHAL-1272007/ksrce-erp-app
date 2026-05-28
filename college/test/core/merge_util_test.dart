import 'package:flutter_test/flutter_test.dart';
import 'package:ksrce_erp/src/core/merge_util.dart';

void main() {
  test('merge adds new remote results', () {
    final local = <Map<String, dynamic>>[];
    final remote = {
      'CSE101': {
        'MID': {
          'r1': {
            'studentId': 'S1',
            'obtainedMarks': 80,
            'maxMarks': 100
          }
        }
      }
    };
    final res = mergeRemoteResults(local, remote);
    expect(res['added'], 1);
    expect(local.length, 1);
    expect(local.first['resultId'], 'r1');
  });

  test('merge updates existing result by resultId', () {
    final local = [
      {'resultId': 'r1', 'studentId': 'S1', 'obtainedMarks': 70}
    ];
    final remote = {
      'CSE101': {
        'MID': {
          'r1': {'studentId': 'S1', 'obtainedMarks': 85}
        }
      }
    };
    final res = mergeRemoteResults(local, remote);
    expect(res['updated'], 1);
    expect(local.first['obtainedMarks'], 85);
  });

  test('merge dedupes by student+course+exam if resultId missing', () {
    final local = [
      {'resultId': null, 'studentId': 'S2', 'courseId': 'CSE101', 'examType': 'MID', 'obtainedMarks': 60}
    ];
    final remote = {
      'CSE101': {
        'MID': {
          'gen1': {'studentId': 'S2', 'obtainedMarks': 75}
        }
      }
    };
    final res = mergeRemoteResults(local, remote);
    expect(res['updated'], 1);
    expect(local.first['obtainedMarks'], 75);
  });
}
