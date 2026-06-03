import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsDashboard extends StatefulWidget {
  final String? userRole;
  const AnalyticsDashboard({super.key, this.userRole});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  String _selectedPeriod = 'semester';

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, ds, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                expandedHeight: 140,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.analytics,
                                  color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Analytics & Insights',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark)),
                                  Text('Performance metrics & trends',
                                      style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Period selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPeriodButton('semester', 'This Semester'),
                        _buildPeriodButton('year', 'This Year'),
                        _buildPeriodButton('overall', 'Overall'),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: 16)),

              // Key metrics cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Overall GPA',
                              '3.85',
                              'out of 4.0',
                              Icons.grade,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Attendance',
                              '92%',
                              'Present',
                              Icons.event_available,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Pass Rate',
                              '100%',
                              'All courses',
                              Icons.check_circle,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Assignments',
                              '18/20',
                              'Submitted',
                              Icons.assignment,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: 20)),

              // Charts
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSectionTitle('Grade Distribution'),
                      const SizedBox(height: 16),
                      _buildGradeDistribution(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Attendance Trend'),
                      const SizedBox(height: 16),
                      _buildAttendanceTrend(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Course Performance'),
                      const SizedBox(height: 16),
                      _buildCoursePerformance(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Pass Rate by Department'),
                      const SizedBox(height: 16),
                      _buildPassRateByDept(),
                    ],
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  )),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              )),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 11,
              )),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution() {
    final grades = [
      {'grade': 'A+', 'count': 5, 'color': Colors.green},
      {'grade': 'A', 'count': 3, 'color': Colors.lightGreen},
      {'grade': 'B+', 'count': 4, 'color': Colors.blue},
      {'grade': 'B', 'count': 2, 'color': Colors.orange},
      {'grade': 'C+', 'count': 1, 'color': Colors.red},
    ];

    final maxCount = grades.map((g) => g['count'] as int).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ...grades.map((item) {
            final percentage = ((item['count'] as int) / maxCount) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['grade'].toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                      Text('${item['count']} courses',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          item['color'] as Color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAttendanceTrend() {
    final months = [
      {'month': 'Jan', 'attendance': 75},
      {'month': 'Feb', 'attendance': 80},
      {'month': 'Mar', 'attendance': 82},
      {'month': 'Apr', 'attendance': 85},
      {'month': 'May', 'attendance': 88},
      {'month': 'Jun', 'attendance': 90},
      {'month': 'Jul', 'attendance': 92},
      {'month': 'Aug', 'attendance': 91},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                // Background grid lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (_) {
                    return Divider(
                      color: Colors.grey[300],
                      height: 1,
                    );
                  }),
                ),
                // Chart
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: months.map((m) {
                    final att = m['attendance'] as int;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (att / 100) * 160,
                          width: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          m['month'].toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Attendance Percentage',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
              Text('Current: 92%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoursePerformance() {
    final courses = [
      {'name': 'Data Structures', 'score': 92},
      {'name': 'Algorithms', 'score': 88},
      {'name': 'Database', 'score': 95},
      {'name': 'Web Dev', 'score': 90},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: courses
            .map((course) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(course['name'].toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              )),
                          Text('${course['score']}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (course['score'] as int) / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPassRateByDept() {
    final depts = [
      {'dept': 'CSE', 'passRate': 95},
      {'dept': 'ECE', 'passRate': 88},
      {'dept': 'MECH', 'passRate': 85},
      {'dept': 'CIVIL', 'passRate': 90},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: depts
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['dept'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (item['passRate'] as int) / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              (item['passRate'] as int) >= 90
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item['passRate']}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedPeriod = value);
        },
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
      ),
    );
  }
}
