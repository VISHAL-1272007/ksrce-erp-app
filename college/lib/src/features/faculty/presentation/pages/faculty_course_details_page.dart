import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

/// Faculty page to enter, view, and manage Course Outcome (CO) details
/// for each assigned course. Each unit maps to COs (CO1–CO5+) with
/// Bloom's Taxonomy levels, PO mapping, textbooks, and references.
class FacultyCourseDetailsPage extends StatefulWidget {
  const FacultyCourseDetailsPage({super.key});

  @override
  State<FacultyCourseDetailsPage> createState() =>
      _FacultyCourseDetailsPageState();
}

class _FacultyCourseDetailsPageState extends State<FacultyCourseDetailsPage>
    with SingleTickerProviderStateMixin {
  String? _selectedCourseId;
  bool _showAddCOForm = false;
  bool _showUploadPanel = false;

  // Form controllers for adding a new CO
  final _coIdCtrl = TextEditingController();
  final _coDescCtrl = TextEditingController();
  String _selectedBlooms = 'Apply';
  String _selectedBloomsCode = 'L3';

  static const _bloomsLevels = {
    'Remember': 'L1',
    'Understand': 'L2',
    'Apply': 'L3',
    'Analyze': 'L4',
    'Evaluate': 'L5',
    'Create': 'L6',
  };

  @override
  void dispose() {
    _coIdCtrl.dispose();
    _coDescCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final courses = ds.getFacultyCourses(fid);
      if (_selectedCourseId == null && courses.isNotEmpty) {
        _selectedCourseId = courses.first['courseId'] as String?;
      }

      final coDetails = _selectedCourseId != null
          ? ds.getCourseOutcomeDetails(_selectedCourseId!)
          : null;
      final cos = _selectedCourseId != null
          ? ds.getCourseOutcomeCOs(_selectedCourseId!)
          : <Map<String, dynamic>>[];
      final unitMap = _selectedCourseId != null
          ? ds.getCourseUnitCOMapping(_selectedCourseId!)
          : <Map<String, dynamic>>[];
      final syllabi = _selectedCourseId != null
          ? ds.getCourseSyllabus(_selectedCourseId!)
          : <Map<String, dynamic>>[];

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Course Details & Outcomes',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark)),
                        Text(
                            'Enter course outcomes (CO), unit-CO mapping, textbooks & references',
                            style: TextStyle(
                                color: AppColors.textLight, fontSize: 13)),
                      ],
                    ),
                  ),
                  _actionButton(
                      Icons.upload_file, 'Upload', AppColors.secondary, () {
                    setState(() => _showUploadPanel = !_showUploadPanel);
                  }),
                ],
              ),

              const SizedBox(height: 20),

              // ── Course selector ────────────────────
              _buildCourseSelector(courses),

              // ── Upload panel ───────────────────────
              if (_showUploadPanel) ...[
                const SizedBox(height: 16),
                _buildUploadPanel(ds),
              ],

              const SizedBox(height: 24),

              // ── Course Info card ───────────────────
              if (coDetails != null) _buildCourseInfoCard(coDetails),
              if (coDetails == null && _selectedCourseId != null)
                _buildNoCourseDetails(),

              const SizedBox(height: 24),

              // ── Course Outcomes table ──────────────
              _buildCOSection(cos, ds),

              const SizedBox(height: 24),

              // ── Unit-CO Mapping ────────────────────
              _buildUnitCOMapping(unitMap, cos, syllabi),

              const SizedBox(height: 24),

              // ── CO-PO Matrix ───────────────────────
              if (cos.isNotEmpty && unitMap.isNotEmpty)
                _buildCOPOMatrix(cos, unitMap),

              const SizedBox(height: 24),

              // ── Textbooks & References ─────────────
              if (coDetails != null) _buildReferencesSection(coDetails),
            ],
          ),
        ),
      );
    });
  }

  // ── Course Selector Dropdown ───────────────────────────
  Widget _buildCourseSelector(List<Map<String, dynamic>> courses) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.elevated,
      child: Row(
        children: [
          const Icon(Icons.class_, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          const Text('Select Course: ',
              style: TextStyle(
                  color: AppColors.textDark, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButton<String>(
                value: _selectedCourseId,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textDark),
                underline: const SizedBox(),
                items: courses
                    .map((c) => DropdownMenuItem(
                          value: c['courseId'] as String?,
                          child: Text(
                              '${c['courseId']} - ${c['courseName'] ?? ''}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedCourseId = v;
                  _showAddCOForm = false;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload Panel ───────────────────────────────────────
  Widget _buildUploadPanel(DataService ds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload,
                  color: AppColors.secondary, size: 24),
              const SizedBox(width: 10),
              const Text('Upload Course Details',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _showUploadPanel = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload a CSV or JSON file with course details. Expected format:\n'
            '• CSV: coId, description, bloomsLevel, bloomsCode\n'
            '• JSON: Array of objects with coId, description, bloomsLevel, bloomsCode fields',
            style: TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _handleFileUpload(ds, 'csv'),
                icon: const Icon(Icons.table_chart, size: 18),
                label: const Text('Upload CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _handleFileUpload(ds, 'json'),
                icon: const Icon(Icons.code, size: 18),
                label: const Text('Upload JSON'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _downloadTemplate(),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download Template'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleFileUpload(DataService ds, String type) {
    // In a real app this would use file_picker package
    // For demo, we show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'File picker would open for $type upload. '
            'In production, use file_picker package to select and parse the file.'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _downloadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Template download: coId,description,bloomsLevel,bloomsCode\n'
            'Example: CO1,"Understand linear data structures",Apply,L3'),
        backgroundColor: AppColors.secondary,
        duration: Duration(seconds: 4),
      ),
    );
  }

  // ── No Course Details placeholder ──────────────────────
  Widget _buildNoCourseDetails() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppCardStyles.elevated,
      child: Column(
        children: [
          const Icon(Icons.add_circle_outline,
              color: AppColors.textLight, size: 48),
          const SizedBox(height: 12),
          const Text('No course details uploaded yet',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text(
              'Click "Upload" to import from file, or add COs manually below',
              style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final ds =
                  Provider.of<DataService>(context, listen: false);
              final fid = ds.currentUserId ?? '';
              final course = ds.courses.firstWhere(
                (c) => c['courseId'] == _selectedCourseId,
                orElse: () => <String, dynamic>{},
              );
              ds.addCourseOutcomeEntry({
                'courseId': _selectedCourseId,
                'courseName': course['courseName'] ?? '',
                'facultyId': fid,
                'departmentId': course['departmentId'] ?? '',
                'regulation': 'R2021',
                'courseType': 'core',
                'totalCredits': course['credits'] ?? 3,
                'lectureHours': 3,
                'tutorialHours': 0,
                'practicalHours': 0,
                'courseObjectives': [],
                'courseOutcomes': [],
                'unitCOMapping': [],
                'textbooks': [],
                'references': [],
                'onlineResources': [],
                'lastUpdated':
                    DateTime.now().toIso8601String().substring(0, 10),
              });
              setState(() => _showAddCOForm = true);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Initialize Course Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Course Info Card ───────────────────────────────────
  Widget _buildCourseInfoCard(Map<String, dynamic> details) {
    final objectives =
        (details['courseObjectives'] as List<dynamic>?)?.cast<String>() ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${details['courseId']} - ${details['courseName'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Regulation: ${details['regulation'] ?? '-'} | '
                      'Credits: ${details['totalCredits'] ?? '-'} | '
                      'L:${details['lectureHours'] ?? 0} T:${details['tutorialHours'] ?? 0} P:${details['practicalHours'] ?? 0}',
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Updated: ${details['lastUpdated'] ?? '-'}',
                  style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (objectives.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Course Objectives',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 8),
            ...objectives.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key + 1}. ',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Expanded(
                          child: Text(e.value,
                              style: const TextStyle(
                                  color: AppColors.textMedium,
                                  fontSize: 13))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ── Course Outcomes Section ────────────────────────────
  Widget _buildCOSection(
      List<Map<String, dynamic>> cos, DataService ds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Text('Course Outcomes (COs)',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const Spacer(),
              _actionButton(
                  Icons.add, 'Add CO', AppColors.primary, () {
                setState(() => _showAddCOForm = !_showAddCOForm);
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Bloom's Taxonomy legend
          _buildBloomsLegend(),
          const SizedBox(height: 16),

          // CO cards
          if (cos.isEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No course outcomes defined yet. Add COs above.',
                  style: TextStyle(color: AppColors.textLight)),
            )),
          ...cos.map((co) => _buildCOCard(co)),

          // Add CO form
          if (_showAddCOForm) ...[
            const SizedBox(height: 16),
            _buildAddCOForm(ds),
          ],
        ],
      ),
    );
  }

  Widget _buildBloomsLegend() {
    final colors = {
      'L1': Colors.grey.shade700,
      'L2': Colors.blue,
      'L3': Colors.teal,
      'L4': Colors.orange.shade800,
      'L5': Colors.deepPurple,
      'L6': Colors.red,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bloom's Taxonomy Levels",
              style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: _bloomsLevels.entries.map((e) {
              final color = colors[e.value] ?? Colors.grey;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(e.value,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  Text(e.key,
                      style: const TextStyle(
                          color: AppColors.textMedium, fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCOCard(Map<String, dynamic> co) {
    final bloomsCode = co['bloomsCode'] ?? 'L3';
    final colors = {
      'L1': Colors.grey.shade700,
      'L2': Colors.blue,
      'L3': Colors.teal,
      'L4': Colors.orange.shade800,
      'L5': Colors.deepPurple,
      'L6': Colors.red,
    };
    final color = colors[bloomsCode] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              co['coId'] ?? '',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  co['description'] ?? '',
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _tag(co['bloomsLevel'] ?? '', color),
                    const SizedBox(width: 8),
                    _tag(bloomsCode, color),
                    if (co['knowledgeLevel'] != null) ...[
                      const SizedBox(width: 8),
                      _tag(co['knowledgeLevel'], AppColors.textLight),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCOForm(DataService ds) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Course Outcome',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: _textField(_coIdCtrl, 'CO ID', 'e.g. CO6'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                    _coDescCtrl, 'Description', 'Describe the course outcome'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("Bloom's Level: ",
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButton<String>(
                  value: _selectedBlooms,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textDark),
                  underline: const SizedBox(),
                  items: _bloomsLevels.keys
                      .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text('$b (${_bloomsLevels[b]})')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedBlooms = v;
                        _selectedBloomsCode = _bloomsLevels[v]!;
                      });
                    }
                  },
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  if (_coIdCtrl.text.isEmpty || _coDescCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Please fill in CO ID and Description')),
                    );
                    return;
                  }
                  ds.updateCourseOutcome(_selectedCourseId!, _coIdCtrl.text, {
                    'coId': _coIdCtrl.text.toUpperCase(),
                    'description': _coDescCtrl.text,
                    'bloomsLevel': _selectedBlooms,
                    'bloomsCode': _selectedBloomsCode,
                    'knowledgeLevel': 'Procedural',
                  });
                  _coIdCtrl.clear();
                  _coDescCtrl.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course Outcome added successfully'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save CO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Unit-CO Mapping ────────────────────────────────────
  Widget _buildUnitCOMapping(
    List<Map<String, dynamic>> unitMap,
    List<Map<String, dynamic>> cos,
    List<Map<String, dynamic>> syllabi,
  ) {
    // Merge unit names from syllabus
    final units = syllabi.isNotEmpty
        ? ((syllabi.first['units'] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree,
                  color: AppColors.accent, size: 22),
              const SizedBox(width: 10),
              const Text('Unit-CO Mapping',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const Spacer(),
              Text('${unitMap.length} units mapped',
                  style: const TextStyle(
                      color: AppColors.textLight, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (unitMap.isEmpty && units.isEmpty)
            const Center(
                child: Text('No unit-CO mapping available',
                    style: TextStyle(color: AppColors.textLight))),
          // Build a table-like grid
          if (unitMap.isNotEmpty || units.isNotEmpty)
            Table(
              border: TableBorder.all(
                  color: AppColors.border, borderRadius: BorderRadius.circular(8)),
              columnWidths: const {
                0: FixedColumnWidth(80),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                  ),
                  children: const [
                    _TableHeader('Unit'),
                    _TableHeader('Title'),
                    _TableHeader('COs'),
                    _TableHeader('PO Mapping'),
                  ],
                ),
                ..._buildUnitRows(units, unitMap),
              ],
            ),
        ],
      ),
    );
  }

  List<TableRow> _buildUnitRows(
    List<Map<String, dynamic>> units,
    List<Map<String, dynamic>> mapping,
  ) {
    final maxLen = units.length > mapping.length ? units.length : mapping.length;
    final rows = <TableRow>[];
    for (int i = 0; i < maxLen; i++) {
      final unitNo = i + 1;
      final unitData = i < units.length ? units[i] : null;
      final mapData = mapping.where((m) => m['unitNo'] == unitNo).toList();
      final coList = mapData.isNotEmpty
          ? (mapData.first['coList'] as List<dynamic>? ?? []).join(', ')
          : '-';
      final poList = mapData.isNotEmpty
          ? (mapData.first['poMapping'] as List<dynamic>? ?? []).join(', ')
          : '-';
      final title =
          unitData?['title'] ?? unitData?['name'] ?? 'Unit $unitNo';
      rows.add(TableRow(
        children: [
          _TableCell('Unit $unitNo'),
          _TableCell(title.toString()),
          _TableCell(coList),
          _TableCell(poList),
        ],
      ));
    }
    return rows;
  }

  // ── CO-PO Matrix ───────────────────────────────────────
  Widget _buildCOPOMatrix(
    List<Map<String, dynamic>> cos,
    List<Map<String, dynamic>> unitMap,
  ) {
    // Collect all unique POs
    final allPOs = <String>{};
    for (final m in unitMap) {
      final pos = (m['poMapping'] as List<dynamic>?) ?? [];
      allPOs.addAll(pos.cast<String>());
    }
    final sortedPOs = allPOs.toList()..sort();
    if (sortedPOs.isEmpty) return const SizedBox.shrink();

    // Build matrix: CO vs PO
    final coIds = cos.map((c) => c['coId'] as String? ?? '').toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_on,
                  color: Colors.deepPurple, size: 22),
              const SizedBox(width: 10),
              const Text('CO-PO Attainment Matrix',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder.all(
                  color: AppColors.border, borderRadius: BorderRadius.circular(8)),
              defaultColumnWidth: const FixedColumnWidth(60),
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.08)),
                  children: [
                    const _TableHeader('CO \\ PO'),
                    ...sortedPOs.map((po) => _TableHeader(po)),
                  ],
                ),
                // Data rows
                ...coIds.map((coId) {
                  // Find which units this CO belongs to
                  final unitMaps = unitMap.where((m) {
                    final coList =
                        (m['coList'] as List<dynamic>?) ?? [];
                    return coList.contains(coId);
                  });
                  final mappedPOs = <String>{};
                  for (final m in unitMaps) {
                    final pos = (m['poMapping'] as List<dynamic>?) ?? [];
                    mappedPOs.addAll(pos.cast<String>());
                  }
                  return TableRow(
                    children: [
                      _TableCell(coId),
                      ...sortedPOs.map((po) {
                        final mapped = mappedPOs.contains(po);
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: mapped
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.check,
                                        color: Colors.deepPurple,
                                        size: 16),
                                  )
                                : const Text('-',
                                    style: TextStyle(
                                        color: AppColors.textLight)),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── References Section ─────────────────────────────────
  Widget _buildReferencesSection(Map<String, dynamic> details) {
    final textbooks =
        (details['textbooks'] as List<dynamic>?)?.cast<String>() ?? [];
    final references =
        (details['references'] as List<dynamic>?)?.cast<String>() ?? [];
    final online =
        (details['onlineResources'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.library_books, color: Colors.teal, size: 22),
              SizedBox(width: 10),
              Text('Textbooks & References',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 16),
          if (textbooks.isNotEmpty) ...[
            const Text('Textbooks',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 8),
            ...textbooks.asMap().entries.map((e) => _refItem(
                '${e.key + 1}', e.value, Icons.book, Colors.teal)),
            const SizedBox(height: 14),
          ],
          if (references.isNotEmpty) ...[
            const Text('Reference Books',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 8),
            ...references.asMap().entries.map((e) => _refItem(
                '${e.key + 1}', e.value, Icons.auto_stories, Colors.orange)),
            const SizedBox(height: 14),
          ],
          if (online.isNotEmpty) ...[
            const Text('Online Resources',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 8),
            ...online.asMap().entries.map((e) => _refItem(
                '${e.key + 1}', e.value, Icons.link, AppColors.primary)),
          ],
        ],
      ),
    );
  }

  Widget _refItem(String num, String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text('$num. ',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textMedium, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────
  Widget _actionButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _textField(
      TextEditingController ctrl, String label, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

// ── Table helper widgets ─────────────────────────────────
class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 12)),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text,
          style:
              const TextStyle(color: AppColors.textMedium, fontSize: 12)),
    );
  }
}
