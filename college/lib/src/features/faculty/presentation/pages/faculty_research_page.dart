import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyResearchPage extends StatefulWidget {
  const FacultyResearchPage({super.key});

  @override
  State<FacultyResearchPage> createState() => _FacultyResearchPageState();
}

class _FacultyResearchPageState extends State<FacultyResearchPage> {

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      final fid = ds.currentUserId ?? '';
      final publications = ds.getFacultyPublications(fid);
      final projects = ds.getFacultyProjects(fid);
      final scholars = ds.getFacultyPhDScholars(fid);
      final citations = ds.getFacultyTotalCitations(fid);

      return Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddResearch(context, ds),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Research', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.science_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Text('Research & Publications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3))),
              ]),
              const SizedBox(height: 24),
              if (isMobile)
                Column(children: [
                  Row(children: [
                    Expanded(child: _statCard('Publications', '${publications.length}', Icons.article_rounded, const Color(0xFF3B82F6))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Projects', '${projects.length}', Icons.work_rounded, const Color(0xFF10B981))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _statCard('PhD Scholars', '${scholars.length}', Icons.school_rounded, const Color(0xFFF97316))),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Citations', '$citations', Icons.format_quote_rounded, const Color(0xFF8B5CF6))),
                  ]),
                ])
              else
                Row(children: [
                  Expanded(child: _statCard('Publications', '${publications.length}', Icons.article_rounded, const Color(0xFF3B82F6))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Projects', '${projects.length}', Icons.work_rounded, const Color(0xFF10B981))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('PhD Scholars', '${scholars.length}', Icons.school_rounded, const Color(0xFFF97316))),
                  const SizedBox(width: 14),
                  Expanded(child: _statCard('Citations', '$citations', Icons.format_quote_rounded, const Color(0xFF8B5CF6))),
                ]),
              const SizedBox(height: 28),
              _buildPublications(publications, ds),
              const SizedBox(height: 24),
              _buildProjects(projects, ds),
              if (scholars.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildScholars(scholars),
              ],
            ]),
          );
        }),
      );
    });
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.statCard(color),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -0.3)),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildPublications(List<Map<String, dynamic>> pubs, DataService ds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.article_rounded, size: 18, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          const Text('Publications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        if (pubs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No publications yet', style: TextStyle(color: AppColors.textLight))),
          ),
        ...pubs.map((p) {
          final researchId = p['researchId'] as String? ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.1)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(p['title'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14))),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') {
                      ds.deleteResearch(researchId);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publication deleted'), backgroundColor: Color(0xFFF43F5E)));
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: Color(0xFFF43F5E)),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 13)),
                    ])),
                  ],
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                ),
              ]),
              const SizedBox(height: 4),
              Text('${p['journal'] ?? p['conference'] ?? ''} | ${p['year'] ?? ''}', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('Citations: ${p['citations'] ?? 0}', style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text(p['type'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildProjects(List<Map<String, dynamic>> projects, DataService ds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.work_rounded, size: 18, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          const Text('Research Projects', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        if (projects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No projects yet', style: TextStyle(color: AppColors.textLight))),
          ),
        ...projects.map((p) {
          final status = p['status'] ?? 'ongoing';
          final color = status == 'completed' ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
          final researchId = p['researchId'] as String? ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['title'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Fund: ${p['fundingAgency'] ?? '-'} | Rs. ${p['fundingAmount'] ?? '-'}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toString().toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') {
                    ds.deleteResearch(researchId);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project deleted'), backgroundColor: Color(0xFFF43F5E)));
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'delete', child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: Color(0xFFF43F5E)),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 13)),
                  ])),
                ],
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildScholars(List<Map<String, dynamic>> scholars) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppCardStyles.elevated,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.school_rounded, size: 18, color: Color(0xFFF97316)),
          const SizedBox(width: 8),
          const Text('PhD Scholars', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 16),
        ...scholars.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.1)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF97316).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.school_rounded, color: Color(0xFFF97316), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['title'] ?? s['scholarName'] ?? '', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
              const SizedBox(height: 2),
              Text(s['researchArea'] ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF97316).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(s['status'] ?? '', style: const TextStyle(color: Color(0xFFF97316), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
        )),
      ]),
    );
  }

  void _showAddResearch(BuildContext context, DataService ds) {
    final titleCtrl = TextEditingController();
    final journalCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '${DateTime.now().year}');
    final citationsCtrl = TextEditingController(text: '0');
    final fundingCtrl = TextEditingController();
    final fundAmtCtrl = TextEditingController();
    String researchType = 'Journal';
    String category = 'publication';
    final types = ['Journal', 'Conference', 'Book Chapter', 'Patent'];
    final categories = ['publication', 'project'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.science_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Add Research', style: TextStyle(color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w600)),
          ]),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Category toggle
              Row(children: categories.map((c) {
                final isSelected = category == c;
                return Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setDlgState(() => category = c),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                      ),
                      child: Center(child: Text(c == 'publication' ? 'Publication' : 'Project',
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textMedium,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ))),
                    ),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Title')),
              const SizedBox(height: 12),
              if (category == 'publication') ...[
                TextField(controller: journalCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Journal / Conference')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: researchType,
                  decoration: _inputDeco('Type'),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDlgState(() => researchType = v!),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: yearCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Year'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: citationsCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Citations'), keyboardType: TextInputType.number)),
                ]),
              ] else ...[
                TextField(controller: fundingCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Funding Agency')),
                const SizedBox(height: 12),
                TextField(controller: fundAmtCtrl, style: const TextStyle(color: AppColors.textDark), decoration: _inputDeco('Funding Amount (Rs.)'), keyboardType: TextInputType.number),
              ],
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () {
                if (titleCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required'), backgroundColor: Color(0xFFF43F5E)));
                  return;
                }
                final research = <String, dynamic>{
                  'facultyId': ds.currentUserId ?? '',
                  'title': titleCtrl.text,
                  'category': category,
                };
                if (category == 'publication') {
                  research['journal'] = journalCtrl.text;
                  research['type'] = researchType;
                  research['year'] = int.tryParse(yearCtrl.text) ?? DateTime.now().year;
                  research['citations'] = int.tryParse(citationsCtrl.text) ?? 0;
                } else {
                  research['fundingAgency'] = fundingCtrl.text.isNotEmpty ? fundingCtrl.text : '-';
                  research['fundingAmount'] = fundAmtCtrl.text.isNotEmpty ? fundAmtCtrl.text : '0';
                  research['status'] = 'ongoing';
                }
                ds.addResearch(research);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${category == 'publication' ? 'Publication' : 'Project'} added!'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ));
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        );
      }),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
      filled: true, fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }
}
