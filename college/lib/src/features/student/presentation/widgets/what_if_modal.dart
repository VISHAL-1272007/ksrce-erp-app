import 'package:flutter/material.dart';
import '../../../../core/data_service.dart';

class WhatIfModal extends StatefulWidget {
  final String courseId;
  final String studentId;
  final List<Map<String, dynamic>> assessments;

  const WhatIfModal({Key? key, required this.courseId, required this.studentId, required this.assessments}) : super(key: key);

  @override
  State<WhatIfModal> createState() => _WhatIfModalState();
}

class _WhatIfModalState extends State<WhatIfModal> {
  final Map<String, TextEditingController> _controllers = {};
  Map<String, double> _hypo = {};
  double _simPct = 0.0;

  @override
  void initState() {
    super.initState();
    for (final a in widget.assessments) {
      final id = a['assessmentId']?.toString() ?? '';
      _controllers[id] = TextEditingController();
    }
    _recalculate();
  }

  void _recalculate() {
    _hypo.clear();
    for (final entry in _controllers.entries) {
      final v = double.tryParse(entry.value.text);
      if (v != null) _hypo[entry.key] = v;
    }
    final ds = DataService();
    setState(() {
      _simPct = ds.simulateCoursePctFromAssessments(widget.assessments, _hypo);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    final current = ds.calculateCurrentCoursePctFromAssessments(widget.assessments);
    return AlertDialog(
      title: Text('What‑If Simulator'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${current.toStringAsFixed(2)}%'),
            const SizedBox(height: 8),
            ...widget.assessments.map((a) {
              final id = a['assessmentId']?.toString() ?? '';
              final max = (a['maxMarks'] ?? 0).toString();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(child: Text(a['assessmentId']?.toString() ?? '')), 
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _controllers[id],
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'Marks / $max'),
                        onChanged: (_) => _recalculate(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            Text('Simulated final: ${_simPct.toStringAsFixed(2)}%'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
