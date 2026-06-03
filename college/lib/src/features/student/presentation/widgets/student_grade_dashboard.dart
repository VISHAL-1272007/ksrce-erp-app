import 'package:flutter/material.dart';
import '../../../../core/data_service.dart';
import 'what_if_modal.dart';

class StudentGradeDashboard extends StatelessWidget {
  final String studentId;
  const StudentGradeDashboard({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    // Find courses for student
    final courses = ds.courses.where((c) {
      final enrolled = (c['studentIds'] as List?)?.cast<String>() ?? [];
      return enrolled.contains(studentId);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Grades'),
        const SizedBox(height: 8),
        ...courses.map((course) {
          final cid = course['courseId']?.toString() ?? '';
          // Build assessments from results/exams
          final assessments = ds.results.where((r) => r['courseId'] == cid && r['studentId'] == studentId).map((r) => Map<String, dynamic>.from(r)).toList();
          final pct = ds.calculateCurrentCoursePctFromAssessments(assessments);
          return Card(
            child: ListTile(
              title: Text(course['name'] ?? course['courseId'] ?? cid),
              subtitle: Text('Current: ${pct.toStringAsFixed(2)}%'),
              trailing: TextButton(
                child: const Text('What‑If'),
                onPressed: () async {
                  await showDialog(context: context, builder: (_) => WhatIfModal(courseId: cid, studentId: studentId, assessments: assessments));
                },
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
