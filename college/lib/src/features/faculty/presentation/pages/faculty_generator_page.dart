import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../../../core/data_service.dart';

class FacultyGeneratorPage extends StatefulWidget {
  const FacultyGeneratorPage({super.key});

  @override
  State<FacultyGeneratorPage> createState() => _FacultyGeneratorPageState();
}

class _FacultyGeneratorPageState extends State<FacultyGeneratorPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Selection state for Exam Builder
  String? _selectedCourseCode;
  String _selectedExamType = 'Internal Assessment I';
  String _selectedDifficulty = 'Medium';
  int _selectedMaxMarks = 50;
  
  bool _isGenerating = false;
  List<Map<String, dynamic>>? _generatedPaper;
  
  // Filtering state for Question Bank
  String _filterCourse = 'All';
  String _filterUnit = 'All';
  String _filterLevel = 'All';
  
  // Form state for Add Question Dialog
  final _formKey = GlobalKey<FormState>();
  String _newCourseCode = 'CS6411';
  String _newCourseName = 'Design and Analysis of Algorithms';
  String _newUnit = 'I';
  int _newMaxMarks = 2;
  String _newCognitiveLevel = 'K1: Remember';
  String _newCourseOutcome = 'CO1';
  final _questionTextController = TextEditingController();

  final Map<String, String> _courseNameMap = {
    'CS6411': 'Design and Analysis of Algorithms',
    'CS6301': 'Database Management Systems',
    'CS6551': 'Computer Networks',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionTextController.dispose();
    super.dispose();
  }

  // Smart Algorithmic Selector
  List<Map<String, dynamic>> _generatePaperAlgorithmic(List<Map<String, dynamic>> questions) {
    final courseQs = questions.where((q) => q['courseCode'] == _selectedCourseCode).toList();
    if (courseQs.isEmpty) return [];

    // Shuffle courseQs initially to get random variety
    courseQs.shuffle();

    // Separate pools by marks
    final poolA = courseQs.where((q) => (q['maxMarks'] ?? 0) == 2).toList();
    final poolB = courseQs.where((q) => (q['maxMarks'] ?? 0) == 13).toList();
    final poolC = courseQs.where((q) => (q['maxMarks'] ?? 0) == 15).toList();

    // If poolC is empty but poolB has questions, allow poolB questions to act as Part C
    final effectivePoolC = poolC.isNotEmpty ? poolC : poolB;

    int cognitiveWeight(String level) {
      if (level.startsWith('K1')) return 1;
      if (level.startsWith('K2')) return 2;
      if (level.startsWith('K3')) return 3;
      if (level.startsWith('K4')) return 4;
      if (level.startsWith('K5')) return 5;
      if (level.startsWith('K6')) return 6;
      return 2;
    }

    bool isTargetLevel(int weight) {
      if (_selectedDifficulty == 'Easy') return weight <= 2;
      if (_selectedDifficulty == 'Medium') return weight == 3 || weight == 4;
      if (_selectedDifficulty == 'Hard') return weight >= 5;
      return true;
    }

    void sortPool(List<Map<String, dynamic>> pool) {
      pool.sort((a, b) {
        final wA = cognitiveWeight(a['cognitiveLevel'] ?? '');
        final wB = cognitiveWeight(b['cognitiveLevel'] ?? '');
        final matchA = isTargetLevel(wA) ? 1 : 0;
        final matchB = isTargetLevel(wB) ? 1 : 0;
        return matchB.compareTo(matchA); // Target difficulty matches first
      });
    }

    sortPool(poolA);
    sortPool(poolB);
    sortPool(effectivePoolC);

    final List<Map<String, dynamic>> selected = [];

    if (_selectedMaxMarks == 100) {
      // 100 Marks Standard:
      // Part A: 10 Qs (2 marks) -> Target 2 from each of Units I, II, III, IV, V
      final List<Map<String, dynamic>> partASelected = [];
      final units = ['I', 'II', 'III', 'IV', 'V'];
      
      for (final unit in units) {
        final unitQs = poolA.where((q) => q['unit'] == unit).toList();
        int taken = 0;
        for (final q in unitQs) {
          if (taken < 2 && !partASelected.contains(q)) {
            partASelected.add(q);
            taken++;
          }
        }
      }
      if (partASelected.length < 10) {
        for (final q in poolA) {
          if (partASelected.length < 10 && !partASelected.contains(q)) {
            partASelected.add(q);
          }
        }
      }
      selected.addAll(partASelected.map((q) => {...q, 'part': 'A'}));

      // Part B: 5 Qs (13 marks) -> Target 1 from each of Units I, II, III, IV, V
      final List<Map<String, dynamic>> partBSelected = [];
      for (final unit in units) {
        final unitQs = poolB.where((q) => q['unit'] == unit).toList();
        if (unitQs.isNotEmpty) {
          final q = unitQs.firstWhere((q) => !partBSelected.contains(q), orElse: () => unitQs.first);
          partBSelected.add(q);
        }
      }
      if (partBSelected.length < 5) {
        for (final q in poolB) {
          if (partBSelected.length < 5 && !partBSelected.contains(q)) {
            partBSelected.add(q);
          }
        }
      }
      selected.addAll(partBSelected.map((q) => {...q, 'part': 'B'}));

      // Part C: 1 Q (15 marks) -> Prefer high cognitive levels (K5/K6)
      Map<String, dynamic>? partCSelected;
      final highCQs = effectivePoolC.where((q) => q['unit'] == 'V' || q['unit'] == 'IV').toList();
      if (highCQs.isNotEmpty) {
        partCSelected = highCQs.first;
      } else if (effectivePoolC.isNotEmpty) {
        partCSelected = effectivePoolC.first;
      }
      if (partCSelected != null) {
        selected.add({...partCSelected, 'part': 'C', 'maxMarks': 15});
      }
    } else {
      // 50 Marks Standard:
      // Part A: 5 Qs (2 marks)
      final List<Map<String, dynamic>> partASelected = [];
      final units = ['I', 'II', 'III', 'IV', 'V'];
      for (final unit in units) {
        final unitQs = poolA.where((q) => q['unit'] == unit).toList();
        if (unitQs.isNotEmpty) {
          partASelected.add(unitQs.first);
        }
        if (partASelected.length >= 5) break;
      }
      if (partASelected.length < 5) {
        for (final q in poolA) {
          if (partASelected.length < 5 && !partASelected.contains(q)) {
            partASelected.add(q);
          }
        }
      }
      selected.addAll(partASelected.map((q) => {...q, 'part': 'A'}));

      // Part B: 2 Qs (13 marks)
      final List<Map<String, dynamic>> partBSelected = [];
      for (final q in poolB) {
        if (partBSelected.length < 2) {
          partBSelected.add(q);
        }
      }
      selected.addAll(partBSelected.map((q) => {...q, 'part': 'B'}));

      // Part C: 1 Q (14 marks - adapt from 15m or 13m)
      Map<String, dynamic>? partCSelected;
      if (effectivePoolC.isNotEmpty) {
        partCSelected = effectivePoolC.firstWhere((q) => !partBSelected.contains(q), orElse: () => effectivePoolC.first);
      }
      if (partCSelected != null) {
        selected.add({...partCSelected, 'part': 'C', 'maxMarks': 14});
      }
    }

    return selected;
  }

  void _triggerGeneration(List<Map<String, dynamic>> questions) {
    if (_selectedCourseCode == null) return;
    setState(() {
      _isGenerating = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _generatedPaper = _generatePaperAlgorithmic(questions);
          _isGenerating = false;
        });
        if (_generatedPaper == null || _generatedPaper!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No questions found in database for the selected course code!'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    });
  }

  void _showAddQuestionDialog(BuildContext context, DataService ds) {
    _questionTextController.clear();
    setState(() {
      _newCourseCode = 'CS6411';
      _newCourseName = _courseNameMap[_newCourseCode]!;
      _newUnit = 'I';
      _newMaxMarks = 2;
      _newCognitiveLevel = 'K1: Remember';
      _newCourseOutcome = 'CO1';
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOverlay(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_task, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Question to Bank', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Form(
                key: _formKey,
                child: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _newCourseCode,
                          decoration: const InputDecoration(labelText: 'Course'),
                          items: _courseNameMap.keys.map((code) {
                            return DropdownMenuItem(
                              value: code,
                              child: Text('$code - ${_courseNameMap[code]}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                _newCourseCode = val;
                                _newCourseName = _courseNameMap[val]!;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _newUnit,
                                decoration: const InputDecoration(labelText: 'Unit'),
                                items: ['I', 'II', 'III', 'IV', 'V'].map((u) {
                                  return DropdownMenuItem(value: u, child: Text('Unit $u'));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => _newUnit = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _newMaxMarks,
                                decoration: const InputDecoration(labelText: 'Marks'),
                                items: [2, 13, 15].map((m) {
                                  return DropdownMenuItem(value: m, child: Text('$m Marks'));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => _newMaxMarks = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _newCognitiveLevel,
                                decoration: const InputDecoration(labelText: 'Bloom\'s Level'),
                                items: [
                                  'K1: Remember',
                                  'K2: Understand',
                                  'K3: Apply',
                                  'K4: Analyze',
                                  'K5: Evaluate',
                                  'K6: Create'
                                ].map((l) {
                                  return DropdownMenuItem(value: l, child: Text(l));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => _newCognitiveLevel = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _newCourseOutcome,
                                decoration: const InputDecoration(labelText: 'Course Outcome'),
                                items: ['CO1', 'CO2', 'CO3', 'CO4', 'CO5', 'CO6'].map((co) {
                                  return DropdownMenuItem(value: co, child: Text(co));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => _newCourseOutcome = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _questionTextController,
                          decoration: const InputDecoration(
                            labelText: 'Question Text',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                            hintText: 'Enter university-standard question text...',
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter question text';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ds.addQuestion({
                        'courseCode': _newCourseCode,
                        'courseName': _newCourseName,
                        'unit': _newUnit,
                        'maxMarks': _newMaxMarks,
                        'cognitiveLevel': _newCognitiveLevel,
                        'courseOutcome': _newCourseOutcome,
                        'questionText': _questionTextController.text.trim(),
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Question successfully added to bank!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Question'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _simulatePrint() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.print, color: AppColors.primary),
              SizedBox(width: 10),
              Text('ERP Print Spooler', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
              SizedBox(height: 16),
              Text(
                'Document Sent to Spooler Successful',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'The question paper has been formatted for standard A4 landscape/portrait printing and routed to your browser spooler. Download preview simulated.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _simulateSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Question Paper locked, and officially synchronized with KSRCE ERP Semester Scheduling!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(
      builder: (context, ds, _) {
        final uniqueCourses = ds.questions.map((q) => q['courseCode'] as String).toSet().toList();
        if (_selectedCourseCode == null && uniqueCourses.isNotEmpty) {
          _selectedCourseCode = uniqueCourses.first;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Premium Tab Bar & Header Row
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'KSRCE Faculty Portal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'AI-Powered Exam builder',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 18),
                              SizedBox(width: 8),
                              Text('Automated Exam Builder'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            children: [
                              Icon(Icons.storage, size: 18),
                              SizedBox(width: 8),
                              Text('Central Question Bank'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              
              // Tabs Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExamBuilderTab(ds),
                    _buildQuestionBankTab(ds),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamBuilderTab(DataService ds) {
    final uniqueCourses = ds.questions.map((q) => q['courseCode'] as String).toSet().toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1000;
        final content = [
          // Left configuration panel
          Expanded(
            flex: isMobile ? 0 : 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppCardStyles.raised,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Exam Parameters',
                      icon: Icons.tune,
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCourseCode,
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        border: OutlineInputBorder(),
                      ),
                      items: uniqueCourses.map((code) {
                        return DropdownMenuItem(
                          value: code,
                          child: Text('$code - ${ds.questions.firstWhere((q) => q['courseCode'] == code)['courseName']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCourseCode = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedExamType,
                      decoration: const InputDecoration(
                        labelText: 'Exam Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Internal Assessment I',
                        'Internal Assessment II',
                        'Model Examination',
                        'Semester End Exams'
                      ].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedExamType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedMaxMarks,
                      decoration: const InputDecoration(
                        labelText: 'Max Marks',
                        border: OutlineInputBorder(),
                      ),
                      items: [50, 100].map((m) {
                        return DropdownMenuItem(value: m, child: Text('$m Marks'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedMaxMarks = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Target Difficulty',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Easy', 'Medium', 'Hard'].map((d) {
                        return DropdownMenuItem(value: d, child: Text(d));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDifficulty = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : () => _triggerGeneration(ds.questions),
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(_isGenerating ? 'Selecting optimal bank Qs...' : 'Algorithmic Build Paper'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (!isMobile) const SizedBox(width: 20),
          
          // Right preview panel
          Expanded(
            flex: isMobile ? 0 : 7,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 0),
              child: Container(
                margin: EdgeInsets.only(top: isMobile ? 0 : 20, right: isMobile ? 0 : 20, bottom: isMobile ? 0 : 20),
                decoration: AppCardStyles.elevated,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'University-Style Paper Preview',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                          ),
                          if (_generatedPaper != null && _generatedPaper!.isNotEmpty)
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: _simulatePrint,
                                  icon: const Icon(Icons.print, size: 16, color: AppColors.primary),
                                  label: const Text('Print Paper', style: TextStyle(color: AppColors.primary)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: _simulateSave,
                                  icon: const Icon(Icons.lock, size: 16, color: AppColors.secondary),
                                  label: const Text('Lock & Save', style: TextStyle(color: AppColors.secondary)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF3F4F6), // subtle grayish container to make paper stand out
                        padding: const EdgeInsets.all(24),
                        child: _isGenerating
                            ? const Center(child: CircularProgressIndicator())
                            : _generatedPaper != null && _generatedPaper!.isNotEmpty
                                ? _buildPaperDocument()
                                : _buildEmptyPreviewPlaceholder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];

        return isMobile
            ? SingleChildScrollView(child: Column(children: [content[0], content[2]]))
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: content);
      },
    );
  }

  Widget _buildEmptyPreviewPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Ready to Build Exam Paper',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure the parameters on the left and click "Algorithmic Build Paper"\nto compile a full Anna University Autonomous syllabus-compliant exam sheet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperDocument() {
    final partA = _generatedPaper!.where((q) => q['part'] == 'A').toList();
    final partB = _generatedPaper!.where((q) => q['part'] == 'B').toList();
    final partC = _generatedPaper!.where((q) => q['part'] == 'C').toList();
    final courseName = _generatedPaper!.first['courseName'] ?? '';

    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: AppCardStyles.mediumShadow,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Official Header
              const Center(
                child: Text(
                  'K.S.R. COLLEGE OF ENGINEERING (Autonomous)',
                  style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'TIRUCHENGODE — 637 215',
                  style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'DEPARTMENT OF COMPUTER SCIENCE & ENGINEERING',
                  style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '$_selectedExamType — May 2026',
                  style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Regulation 2022 | B.E. Computer Science and Engineering',
                  style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 12, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              
              // Information details block
              Table(
                border: TableBorder.all(color: Colors.black, width: 1),
                columnWidths: const {
                  0: FlexColumnWidth(4),
                  1: FlexColumnWidth(4),
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Course Code & Title: $_selectedCourseCode / $courseName',
                          style: const TextStyle(fontFamily: 'serif', fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Max. Marks: $_selectedMaxMarks Marks',
                          style: const TextStyle(fontFamily: 'serif', fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Year & Semester: III / VI',
                          style: TextStyle(fontFamily: 'serif', fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Time Allowed: ${_selectedMaxMarks == 100 ? "3 Hours" : "1.5 Hours"}',
                          style: const TextStyle(fontFamily: 'serif', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.black, thickness: 1.5),

              // PART A
              if (partA.isNotEmpty) ...[
                Center(
                  child: Text(
                    'PART A — ( ${partA.length} x 2 = ${partA.length * 2} Marks )',
                    style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                  ),
                ),
                const Center(
                  child: Text(
                    'Answer ALL the Questions',
                    style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 11, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuestionListTable(partA, 1),
                const SizedBox(height: 24),
              ],

              // PART B
              if (partB.isNotEmpty) ...[
                Center(
                  child: Text(
                    'PART B — ( ${partB.length} x 13 = ${partB.length * 13} Marks )',
                    style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                  ),
                ),
                const Center(
                  child: Text(
                    'Answer ALL the Questions (Either or Pattern / Structured)',
                    style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 11, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuestionListTable(partB, partA.length + 1),
                const SizedBox(height: 24),
              ],

              // PART C
              if (partC.isNotEmpty) ...[
                Center(
                  child: Text(
                    'PART C — ( 1 x ${partC.first['maxMarks']} = ${partC.first['maxMarks']} Marks )',
                    style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                  ),
                ),
                const Center(
                  child: Text(
                    'Higher-Order Cognitive Evaluation Question',
                    style: TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 11, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuestionListTable(partC, partA.length + partB.length + 1),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionListTable(List<Map<String, dynamic>> list, int startIndex) {
    return Table(
      border: TableBorder.symmetric(
        inside: const BorderSide(color: Colors.black12, width: 0.5),
        outside: const BorderSide(color: Colors.black, width: 0.5),
      ),
      columnWidths: const {
        0: FixedColumnWidth(40),
        1: FlexColumnWidth(10),
        2: FixedColumnWidth(50),
        3: FixedColumnWidth(50),
        4: FixedColumnWidth(50),
      },
      children: [
        // Header
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF9FAFB)),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text('Q.No', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: Text('Question Text', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text('CO', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text('Level', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text('Marks', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
            ),
          ],
        ),
        // Questions
        ...list.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          final qNo = startIndex + idx;
          final levelAbbr = (q['cognitiveLevel'] as String? ?? 'K1').split(':').first.trim();

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text('$qNo.', style: const TextStyle(fontFamily: 'serif', fontSize: 11), textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Text(
                  q['questionText'] ?? '',
                  style: const TextStyle(fontFamily: 'serif', fontSize: 11, height: 1.3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text(q['courseOutcome'] ?? 'CO1', style: const TextStyle(fontFamily: 'serif', fontSize: 11), textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text(levelAbbr, style: const TextStyle(fontFamily: 'serif', fontSize: 11), textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Text('${q['maxMarks']}', style: const TextStyle(fontFamily: 'serif', fontSize: 11), textAlign: TextAlign.center),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildQuestionBankTab(DataService ds) {
    // Determine unique options for filters
    final courses = ds.questions.map((q) => q['courseCode'] as String).toSet().toList();
    final levels = ['K1: Remember', 'K2: Understand', 'K3: Apply', 'K4: Analyze', 'K5: Evaluate', 'K6: Create'];

    // Filtered list
    final filteredQs = ds.questions.where((q) {
      if (_filterCourse != 'All' && q['courseCode'] != _filterCourse) return false;
      if (_filterUnit != 'All' && q['unit'] != _filterUnit) return false;
      if (_filterLevel != 'All' && !(q['cognitiveLevel'] as String).startsWith(_filterLevel)) return false;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppCardStyles.raised,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterCourse,
                    decoration: const InputDecoration(labelText: 'Filter Course', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: ['All', ...courses].map((c) {
                      return DropdownMenuItem(value: c, child: Text(c == 'All' ? 'All Courses' : c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _filterCourse = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterUnit,
                    decoration: const InputDecoration(labelText: 'Filter Unit', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: ['All', 'I', 'II', 'III', 'IV', 'V'].map((u) {
                      return DropdownMenuItem(value: u, child: Text(u == 'All' ? 'All Units' : 'Unit $u'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _filterUnit = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterLevel,
                    decoration: const InputDecoration(labelText: 'Filter Bloom\'s', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: ['All', 'K1', 'K2', 'K3', 'K4', 'K5', 'K6'].map((l) {
                      return DropdownMenuItem(value: l, child: Text(l == 'All' ? 'All Cognitive Levels' : l));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _filterLevel = val);
                    },
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => _showAddQuestionDialog(context, ds),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Total Count Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filteredQs.length} of ${ds.questions.length} Questions',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLight),
              ),
              Text(
                'Database: ${courses.length} Seeded Courses',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question Cards Grid/List
          Expanded(
            child: filteredQs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory, size: 48, color: AppColors.textMuted.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('No Questions Match Filter Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredQs.length,
                    itemBuilder: (context, index) {
                      final q = filteredQs[index];
                      final qId = q['questionId'] ?? '';
                      final code = q['courseCode'] ?? '';
                      final unit = q['unit'] ?? '';
                      final marks = q['maxMarks'] ?? 0;
                      final outcome = q['courseOutcome'] ?? 'CO1';
                      final level = q['cognitiveLevel'] ?? 'K1: Remember';
                      final text = q['questionText'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: AppCardStyles.accentLeft(
                          marks == 2
                              ? AppColors.info
                              : marks == 13
                                  ? AppColors.warning
                                  : AppColors.accent,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryOverlay(),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$code - Unit $unit',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryOverlay(),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$marks Marks | $outcome',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        level,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                      ),
                                      const Spacer(),
                                      Text(
                                        qId,
                                        style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted.withOpacity(0.6)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textDark,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete Question?'),
                                      content: const Text('Are you sure you want to permanently remove this question from the centralized database bank?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            ds.deleteQuestion(qId);
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Question removed successfully!'),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
