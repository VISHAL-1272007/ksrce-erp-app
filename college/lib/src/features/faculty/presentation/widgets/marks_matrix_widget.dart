import 'package:flutter/material.dart';
import '../../../../core/data_service.dart';
import '../../../../core/marks_service.dart';

class MarksMatrixWidget extends StatefulWidget {
  final String configId;
  final String courseCode;

  const MarksMatrixWidget({Key? key, required this.configId, required this.courseCode}) : super(key: key);

  @override
  State<MarksMatrixWidget> createState() => _MarksMatrixWidgetState();
}

class _MarksMatrixWidgetState extends State<MarksMatrixWidget> {
  final DataService _ds = DataService();
  final MarksService _ms = MarksService();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _rules = [];
  Map<String, Map<String, TextEditingController>> _controllers = {};
  Map<String, List<String>> _choiceGroups = {};
  // Per-student validation errors: studentId -> (ruleId -> error message)
  Map<String, Map<String, String>> _fieldErrors = {};
  // Row-level errors (general)
  Map<String, List<String>> _rowErrors = {};

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    // get students for course from DataService (students list may include enrollments)
    final allStudents = _ds.students;
    _students = allStudents.where((s) {
      final courses = (s['courseIds'] as List?)?.cast<String>() ?? [];
      return courses.contains(widget.courseCode);
    }).toList();

    _rules = await _ms.loadQuestionRulesForConfig(widget.configId);
    // Build controllers
    for (final st in _students) {
      final sid = st['studentId']?.toString() ?? '';
      _controllers[sid] = {};
      _fieldErrors[sid] = {};
      _rowErrors[sid] = [];
      for (final r in _rules) {
        final rid = r['rule_id']?.toString() ?? '';
        _controllers[sid]![rid] = TextEditingController();
      }
    }

    // Build simple choiceGroups from rules' choice_group field
    for (final r in _rules) {
      final cg = r['choice_group']?.toString();
      final rid = r['rule_id']?.toString() ?? '';
      if (cg != null && cg.isNotEmpty) {
        _choiceGroups.putIfAbsent(cg, () => []).add(rid);
      }
    }

    setState(() {});
  }

  void _onInputChanged(String studentId, String ruleId) {
    final group = _rules.firstWhere((r) => r['rule_id'] == ruleId, orElse: () => {})['choice_group']?.toString();
    // apply validation rules similar to JS
    if (group != null && group.isNotEmpty) {
      final groupRules = _choiceGroups[group] ?? [];
      if (group.contains('Q6')) {
        // at most 1
        final filled = groupRules.where((rid) => _controllers[studentId]![rid]!.text.trim().isNotEmpty).toList();
        if (filled.length >= 1) {
          for (final rid in groupRules) {
            if (!filled.contains(rid)) _controllers[studentId]![rid]!.text = '';
          }
        }
      } else if (group.contains('Q7') || group.contains('Q8')) {
        final filled = groupRules.where((rid) => _controllers[studentId]![rid]!.text.trim().isNotEmpty).toList();
        if (filled.length >= 2) {
          for (final rid in groupRules) {
            if (!filled.contains(rid)) _controllers[studentId]![rid]!.text = '';
          }
        }
      }
    }
    // Recompute total and optionally persist
    setState(() {});
  }

  double _rowTotal(String studentId) {
    double total = 0.0;
    for (final r in _rules) {
      final rid = r['rule_id']?.toString() ?? '';
      final max = (r['max_score'] as num?)?.toDouble() ?? 0.0;
      final txt = _controllers[studentId]![rid]!.text.trim();
      if (txt.isNotEmpty) {
        final v = double.tryParse(txt) ?? 0.0;
        total += v.clamp(0.0, max);
      }
    }
    return double.parse(total.toStringAsFixed(2));
  }

  Future<void> _saveRow(String studentId) async {
    // collect marks
    final marks = <Map<String, dynamic>>[];
    for (final r in _rules) {
      final rid = r['rule_id']?.toString() ?? '';
      final txt = _controllers[studentId]![rid]!.text.trim();
      final v = txt.isEmpty ? null : double.tryParse(txt);
      marks.add({'rule_id': rid, 'marks_obtained': v});
      await _ms.saveMark(widget.configId, studentId, rid, v);
    }
    // Validate
    final validation = _ms.validateRowInputs(_rules, marks, _choiceGroups);
    // Clear previous errors
    _fieldErrors[studentId] = {};
    _rowErrors[studentId] = [];
    if (!(validation['ok'] as bool)) {
      final errs = (validation['errors'] as List).cast<String>();
      // Map errors to fields where possible (look for question_no in message)
      for (final e in errs) {
        var assigned = false;
        for (final r in _rules) {
          final qno = r['question_no']?.toString();
          if (qno != null && e.contains(qno)) {
            final rid = r['rule_id']?.toString() ?? '';
            _fieldErrors[studentId]![rid] = e;
            assigned = true;
            break;
          }
        }
        if (!assigned) _rowErrors[studentId]!.add(e);
      }
      setState(() {});
      // Also show a snackbar summary
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Validation failed: ${errs.join('; ')}'), backgroundColor: const Color(0xFFF43F5E)));
      return;
    }
    // compute total and persist into student master via DataService notifyUser (placeholder)
    final total = _ms.computeTotalFromRulesAndMarks(_rules, marks);
    // Try to get exam config to identify examType and maxMarks
    try {
      final cfg = await _ms.getExamConfig(widget.configId);
      final examType = cfg?['exam_type']?.toString() ?? 'CIA1';
      final maxMarks = (cfg?['max_marks'] as num?)?.toDouble() ?? 50.0;
      await DataService().upsertExamResultForStudent(studentId: studentId, courseCode: widget.courseCode, examType: examType, obtained: total, maxMarks: maxMarks);
      _ds.notifyUser(studentId, 'Marks saved', 'Total for ${widget.courseCode} ($examType): $total', type: 'success');
    } catch (e) {
      _ds.notifyUser(studentId, 'Marks saved (local)', 'Total for ${widget.courseCode}: $total', type: 'success');
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved. Total: $total')));
  }

  @override
  Widget build(BuildContext context) {
    if (_students.isEmpty || _rules.isEmpty) return const Center(child: CircularProgressIndicator());

    // Build table header
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          DataTable(
            columns: [
              const DataColumn(label: Text('Reg No')),
              const DataColumn(label: Text('Name')),
              ..._rules.map((r) => DataColumn(label: _headerCell(r))),
              const DataColumn(label: Text('Total')),
              const DataColumn(label: Text('Action')),
            ],
            rows: _students.map((s) {
              final sid = s['studentId']?.toString() ?? '';
              final cells = <DataCell>[];
              cells.add(DataCell(Text(s['regNo']?.toString() ?? sid)));
              cells.add(DataCell(Text(s['name']?.toString() ?? '')));
                for (final r in _rules) {
                final rid = r['rule_id']?.toString() ?? '';
                final ctrl = _controllers[sid]![rid]!;
                final fieldErr = _fieldErrors[sid]?[rid];
                cells.add(DataCell(SizedBox(
                  width: 80,
                  child: TextField(
                    controller: ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(border: const OutlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.all(8), errorText: fieldErr),
                    onChanged: (_) => _onInputChanged(sid, rid),
                  ),
                )));
              }
              final total = _rowTotal(sid);
              cells.add(DataCell(Text(total.toStringAsFixed(2))));
              cells.add(DataCell(Column(children: [
                if ((_rowErrors[sid] ?? []).isNotEmpty) ...[
                  for (final e in _rowErrors[sid]!) Text(e, style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 11)),
                  const SizedBox(height: 6),
                ],
                ElevatedButton(onPressed: () => _saveRow(sid), child: const Text('Save')),
              ])));
              return DataRow(cells: cells);
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _headerCell(Map<String, dynamic> r) {
    final q = r['question_no']?.toString() ?? 'Q';
    final min = (r['min_score'] as num?)?.toDouble();
    final max = (r['max_score'] as num?)?.toDouble();
    final range = (min != null || max != null)
        ? '${(min ?? 0).toStringAsFixed(min == null ? 0 : (min % 1 == 0 ? 0 : 1))}–${(max ?? 0).toStringAsFixed(max == null ? 0 : (max % 1 == 0 ? 0 : 1))}'
        : '—';
    final group = r['choice_group']?.toString();
    final subtitle = group != null && group.isNotEmpty ? '$range • $group' : range;
    return SizedBox(
      width: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), height: 1.1)),
        ],
      ),
    );
  }
}
