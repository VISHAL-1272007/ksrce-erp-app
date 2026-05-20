import 'dart:async';
import 'dart:math';
import 'persistence_service.dart';
import 'firebase_service.dart';

class MarksService {
  static final MarksService _instance = MarksService._internal();
  factory MarksService() => _instance;
  MarksService._internal();

  final _rand = Random.secure();

  String _generateId() => '${DateTime.now().millisecondsSinceEpoch}_${_rand.nextInt(1 << 31)}';

  Future<List<Map<String, dynamic>>> loadExamConfigurations() async {
    final all = PersistenceService.loadLocal() ?? {};
    final configs = (all['exam_configurations'] as List?) ?? [];
    return configs.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>?> getExamConfig(String configId) async {
    final configs = await loadExamConfigurations();
    return configs.firstWhere((c) => c['config_id'] == configId, orElse: () => <String, dynamic>{}).cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> loadQuestionRulesForConfig(String configId) async {
    final all = PersistenceService.loadLocal() ?? {};
    final rules = (all['question_rules'] as List?) ?? [];
    return rules.where((r) => r['config_id'] == configId).map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> loadMarksForConfigAndStudent(String configId, String studentId) async {
    final all = PersistenceService.loadLocal() ?? {};
    final marks = (all['student_marks_matrix'] as List?) ?? [];
    return marks.where((m) => m['config_id'] == configId && m['student_id'] == studentId).map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> saveMark(String configId, String studentId, String ruleId, double? marks) async {
    // Prepare mark object
    final markObj = {
      'mark_id': _generateId(),
      'config_id': configId,
      'student_id': studentId,
      'rule_id': ruleId,
      'marks_obtained': marks,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Write to RTDB at /student_marks_matrix/{configId}/{studentId}/{ruleId}
    final path = '/student_marks_matrix/$configId/$studentId/$ruleId';
    try {
      await FirebaseService.instance.set(path, markObj);
    } catch (e) {
      // fallback to local persistence if RTDB write fails
      final full = PersistenceService.loadLocal() ?? {};
      final marksList = (full['student_marks_matrix'] as List?) ?? [];
      final idx = marksList.indexWhere((m) => m['config_id'] == configId && m['student_id'] == studentId && m['rule_id'] == ruleId);
      if (idx != -1) {
        marksList[idx] = {
          ...Map<String, dynamic>.from(marksList[idx]),
          'marks_obtained': marks,
          'updated_at': DateTime.now().toIso8601String(),
        };
      } else {
        marksList.add(markObj);
      }
      full['student_marks_matrix'] = marksList;
      await PersistenceService.saveAll(full);
      rethrow;
    }
  }

  /// Compute total for a student for a given config_id using question rules and marks.
  /// Assumes question rules include 'max_score' and marks list contains 'marks_obtained'.
  double computeTotalFromRulesAndMarks(List<Map<String, dynamic>> rules, List<Map<String, dynamic>> marks) {
    double total = 0.0;
    for (final r in rules) {
      final rid = r['rule_id']?.toString();
      final max = (r['max_score'] as num?)?.toDouble() ?? 0.0;
      final m = marks.firstWhere((mm) => mm['rule_id'] == rid, orElse: () => <String, dynamic>{});
      final obtained = (m['marks_obtained'] as num?)?.toDouble();
      if (obtained != null) {
        // clamp
        final clamped = obtained.clamp(0.0, max);
        total += clamped;
      }
    }
    return double.parse(total.toStringAsFixed(2));
  }

  /// Validate row inputs given grouped choice rules.
  /// choiceGroups: Map<groupId, List<ruleId>>
  Map<String, dynamic> validateRowInputs(List<Map<String, dynamic>> rules, List<Map<String, dynamic>> marks,
      Map<String, List<String>> choiceGroups) {
    final errors = <String>[];
    // Build map of ruleId->marks
    final mMap = <String, double>{};
    for (final m in marks) {
      final rid = m['rule_id']?.toString();
      final v = (m['marks_obtained'] as num?)?.toDouble();
      if (rid != null && v != null) mMap[rid] = v;
    }

    // Validate per rule max
    for (final r in rules) {
      final rid = r['rule_id']?.toString();
      final max = (r['max_score'] as num?)?.toDouble() ?? 0.0;
      final min = (r['min_score'] as num?)?.toDouble() ?? 0.0;
      if (rid != null && mMap.containsKey(rid)) {
        if (mMap[rid]! > max) errors.add('Marks for ${r['question_no']} exceed max (${mMap[rid]} > $max)');
        if (mMap[rid]! < min) errors.add('Marks for ${r['question_no']} are below minimum (${mMap[rid]} < $min)');
      }
    }

    // Validate choice groups
    choiceGroups.forEach((groupId, ruleIds) {
      final filled = ruleIds.where((rid) => mMap.containsKey(rid) && (mMap[rid] ?? 0) > 0).toList();
      // Example rules: Q6 -> at most 1 filled; Q7/Q8 -> at most 2 filled
      if (groupId.contains('Q6')) {
        if (filled.length > 1) errors.add('Only one option allowed for $groupId');
      }
      if (groupId.contains('Q7') || groupId.contains('Q8')) {
        if (filled.length > 2) errors.add('At most two options allowed for $groupId');
      }
    });

    return {'ok': errors.isEmpty, 'errors': errors};
  }

}
