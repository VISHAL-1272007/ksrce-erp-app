import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class FacultyGeneratorPage extends StatefulWidget {
  const FacultyGeneratorPage({super.key});

  @override
  State<FacultyGeneratorPage> createState() => _FacultyGeneratorPageState();
}

class _FacultyGeneratorPageState extends State<FacultyGeneratorPage> {
  bool _isGenerating = false;
  bool _hasGenerated = false;

  void _generateContent() {
    setState(() {
      _isGenerating = true;
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasGenerated = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Course Generator',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Generate Anna University-aligned lesson plans and syllabi.',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppCardStyles.elevated,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Course Code', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: TextEditingController(text: 'CS6411 – Design and Analysis of Algorithms'),
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isGenerating ? null : _generateContent,
                                icon: _isGenerating 
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.auto_awesome),
                                label: Text(_isGenerating ? 'Generating Magic...' : 'Generate Content'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) const SizedBox(width: 24),
                // Right Panel
                if (!isMobile)
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: double.infinity,
                      decoration: AppCardStyles.elevated,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Generated Content Preview',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: _isGenerating
                                ? const Center(child: CircularProgressIndicator())
                                : _hasGenerated
                                    ? _buildGeneratedContent()
                                    : const Center(child: Text('Click Generate to create content')),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }
  
  Widget _buildGeneratedContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('CS6411 – Design and Analysis of Algorithms', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Department: CSE | Year: III | Sem: VI', style: TextStyle(color: Colors.grey)),
          Divider(height: 32),
          Text('Unit III: Dynamic Programming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('This unit covers optimal substructure and overlapping subproblems using dynamic programming.', style: TextStyle(height: 1.5)),
          SizedBox(height: 16),
          Text('Lesson Plan – Week 7', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('• Day 1: Matrix Chain Multiplication\n• Day 2: All Pairs Shortest Path\n• Day 3: Optimal Binary Search Trees', style: TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
