/// Lightweight grade calculation utilities for the What‑If simulator.

double calculateCurrentCoursePct(List<Map<String, dynamic>> assessments) {
  double pct = 0.0;
  for (final a in assessments) {
    final weight = (a['weight'] as num?)?.toDouble() ?? 0.0;
    final maxMarks = (a['maxMarks'] as num?)?.toDouble() ?? 0.0;
    final obtained = a['obtainedMarks'] as num?;
    if (obtained != null && maxMarks > 0) {
      pct += (obtained.toDouble() / maxMarks) * weight;
    }
  }
  return pct;
}

double simulateCoursePct(List<Map<String, dynamic>> assessments, Map<String, double> hypothetical) {
  double pct = 0.0;
  for (final a in assessments) {
    final id = a['assessmentId']?.toString() ?? '';
    final weight = (a['weight'] as num?)?.toDouble() ?? 0.0;
    final maxMarks = (a['maxMarks'] as num?)?.toDouble() ?? 0.0;
    final obtained = a['obtainedMarks'] as num?;
    double value;
    if (obtained != null) {
      value = obtained.toDouble();
    } else if (hypothetical.containsKey(id)) {
      value = hypothetical[id]!.clamp(0.0, maxMarks);
    } else {
      // no marks yet
      continue;
    }
    if (maxMarks > 0) pct += (value / maxMarks) * weight;
  }
  return pct;
}

/// Compute required marks per remaining assessment to reach [targetPct].
/// Returns a map: { 'possible': bool, 'perAssessment': {id: requiredMarks}, 'neededContribution': double }
Map<String, dynamic> requiredMarksForTarget(List<Map<String, dynamic>> assessments, double targetPct,
    {String strategy = 'even'}) {
  final current = calculateCurrentCoursePct(assessments);
  final remaining = <Map<String, dynamic>>[];
  for (final a in assessments) {
    if (a['obtainedMarks'] == null) remaining.add(a);
  }

  final needed = targetPct - current;
  if (needed <= 0) return {'possible': true, 'perAssessment': {}, 'neededContribution': 0.0};
  final remainingWeight = remaining.fold<double>(0.0, (s, a) => s + ((a['weight'] as num?)?.toDouble() ?? 0.0));
  if (remainingWeight <= 0) return {'possible': false, 'reason': 'no remaining weight', 'neededContribution': needed};

  final per = <String, double>{};
  if (strategy == 'even') {
    for (final a in remaining) {
      final id = a['assessmentId']?.toString() ?? '';
      final w = (a['weight'] as num?)?.toDouble() ?? 0.0;
      final maxMarks = (a['maxMarks'] as num?)?.toDouble() ?? 0.0;
      final contrib = needed * (w / remainingWeight);
      final requiredMarks = (contrib / w) * maxMarks;
      per[id] = double.parse(requiredMarks.isFinite ? requiredMarks.toStringAsFixed(2) : '1e9');
    }
  } else {
    // single: compute minimum marks needed on each assessment if focusing all effort there
    for (final a in remaining) {
      final id = a['assessmentId']?.toString() ?? '';
      final w = (a['weight'] as num?)?.toDouble() ?? 0.0;
      final maxMarks = (a['maxMarks'] as num?)?.toDouble() ?? 0.0;
      final requiredMarks = (needed / w) * maxMarks;
      per[id] = double.parse(requiredMarks.isFinite ? requiredMarks.toStringAsFixed(2) : '1e9');
    }
  }

  // check feasibility
  var possible = false;
  for (final a in remaining) {
    final id = a['assessmentId']?.toString() ?? '';
    final maxMarks = (a['maxMarks'] as num?)?.toDouble() ?? 0.0;
    if ((per[id] ?? double.infinity) <= maxMarks) possible = true;
  }

  return {'possible': possible, 'perAssessment': per, 'neededContribution': needed};
}
