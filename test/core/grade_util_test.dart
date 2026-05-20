import 'package:flutter_test/flutter_test.dart';
import 'package:ksrce_erp/src/core/grade_util.dart';

void main() {
  test('calculate current pct with partial assessments', () {
    final assessments = [
      {'assessmentId': 'a1', 'weight': 40, 'maxMarks': 100, 'obtainedMarks': 80},
      {'assessmentId': 'a2', 'weight': 60, 'maxMarks': 100, 'obtainedMarks': null},
    ];
    final pct = calculateCurrentCoursePct(assessments);
    expect(pct, closeTo(32.0, 1e-6)); // 80% of 40 = 32
  });

  test('simulate final pct with hypothetical marks', () {
    final assessments = [
      {'assessmentId': 'a1', 'weight': 40, 'maxMarks': 100, 'obtainedMarks': 80},
      {'assessmentId': 'a2', 'weight': 60, 'maxMarks': 100, 'obtainedMarks': null},
    ];
    final sim = simulateCoursePct(assessments, {'a2': 90.0});
    // current 32 + 90% of 60 = 54 => total 86
    expect(sim, closeTo(86.0, 1e-6));
  });

  test('required marks even split', () {
    final assessments = [
      {'assessmentId': 'a1', 'weight': 50, 'maxMarks': 50, 'obtainedMarks': 25},
      {'assessmentId': 'a2', 'weight': 50, 'maxMarks': 50, 'obtainedMarks': null},
    ];
    // current: a1 = (25/50)*50 = 25
    // target 60 -> need 35 more contribution; remaining weight 50 -> need 35 from a2
    final res = requiredMarksForTarget(assessments, 60.0, strategy: 'even');
    expect(res['possible'], true);
    final per = res['perAssessment'] as Map<String, double>;
    // required marks on a2 should be 35% of its weight -> (35 / 50)*50 = 35
    expect(per['a2']!, closeTo(35.0, 0.5));
  });
}
