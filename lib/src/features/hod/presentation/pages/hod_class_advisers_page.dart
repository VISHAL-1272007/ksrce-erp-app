import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_card_styles.dart';

class HodClassAdvisersPage extends StatefulWidget {
  const HodClassAdvisersPage({super.key});
  @override
  State<HodClassAdvisersPage> createState() => _HodClassAdvisersPageState();
}

class _HodClassAdvisersPageState extends State<HodClassAdvisersPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataService>(builder: (context, ds, _) {
      if (!ds.isLoaded)
        return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()));

      final deptId = ds.currentFaculty?['departmentId'] as String? ?? '';
      final deptClasses = ds.getDepartmentClasses(deptId);
      final deptFaculty = ds.getDepartmentFaculty(deptId);

      return Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.person_pin, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('Class Adviser Assignment',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ]),
              const SizedBox(height: 8),
              Text(
                  'Assign class advisers for ${ds.getDepartmentCode(deptId)} department',
                  style: const TextStyle(
                      color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton.icon(
                    onPressed: () => _showAddClassDialog(context, ds, deptId),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Class')),
                const SizedBox(width: 12),
                const Text('Manage classes and assign advisers',
                    style: TextStyle(color: AppColors.textLight))
              ]),
              const SizedBox(height: 12),
              ...deptClasses.map((cls) {
                final adviserId = cls['classAdviserId'] as String? ?? '';
                final adviserName = adviserId.isNotEmpty
                    ? ds.getFacultyName(adviserId)
                    : 'Not Assigned';
                final studentCount =
                    (cls['studentIds'] as List<dynamic>?)?.length ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: AppCardStyles.elevated,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                  'Year ${cls['year']} - Section ${cls['section']}',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14))),
                          const Spacer(),
                          Text('$studentCount students',
                              style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 13)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Text('Current Adviser:',
                                    style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(adviserName,
                                    style: TextStyle(
                                        color: adviserId.isNotEmpty
                                            ? AppColors.textDark
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ])),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(
                                adviserId.isNotEmpty ? 'Change' : 'Assign'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            onPressed: () => _showAssignDialog(
                                context, ds, cls, deptFaculty),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                              onPressed: () =>
                                  _showEditClassDialog(context, ds, cls),
                              icon: const Icon(Icons.edit_calendar, size: 20)),
                          IconButton(
                              onPressed: () => _confirmDeleteClass(
                                  context, ds, cls['classId'] as String? ?? ''),
                              icon: const Icon(Icons.delete, size: 20)),
                        ]),
                      ]),
                );
              }),
            ]),
          );
        }),
      );
    });
  }

  void _showAssignDialog(BuildContext context, DataService ds,
      Map<String, dynamic> cls, List<Map<String, dynamic>> facultyList) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
                'Assign Adviser - Year ${cls['year']} Sec ${cls['section']}',
                style:
                    const TextStyle(color: AppColors.textDark, fontSize: 16)),
            content: SizedBox(
              width: 350,
              child: ListView(
                shrinkWrap: true,
                children: facultyList.map((f) {
                  final isCurrentAdviser =
                      cls['classAdviserId'] == f['facultyId'];
                  return ListTile(
                    leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isCurrentAdviser
                            ? AppColors.secondary.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.person,
                            size: 18,
                            color: isCurrentAdviser
                                ? AppColors.secondary
                                : AppColors.primary)),
                    title: Text(f['name'] as String? ?? '',
                        style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: isCurrentAdviser
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14)),
                    subtitle: Text(f['designation'] as String? ?? '',
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 12)),
                    trailing: isCurrentAdviser
                        ? const Icon(Icons.check_circle,
                            color: AppColors.secondary, size: 20)
                        : null,
                    onTap: () {
                      ds.assignClassAdviser(
                          cls['classId'] as String, f['facultyId'] as String);
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('${f['name']} assigned as class adviser'),
                          backgroundColor: AppColors.secondary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))));
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'))
            ],
          );
        });
  }

  void _showAddClassDialog(
      BuildContext context, DataService ds, String departmentId) {
    final yearC = TextEditingController();
    final sectionC = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Add Class',
                  style: TextStyle(color: AppColors.textDark)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Department: ${ds.getDepartmentCode(departmentId)}',
                    style: const TextStyle(color: AppColors.textLight)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: yearC,
                          decoration: const InputDecoration(
                              labelText: 'Year', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: sectionC,
                          decoration: const InputDecoration(
                              labelText: 'Section',
                              border: OutlineInputBorder()))),
                ])
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      if (yearC.text.isNotEmpty && sectionC.text.isNotEmpty) {
                        final code = ds.getDepartmentCode(departmentId);
                        final classId =
                            '${code}_${yearC.text}_${sectionC.text.toUpperCase()}';
                        ds.addClass({
                          'classId': classId,
                          'departmentId': departmentId,
                          'year': int.tryParse(yearC.text) ?? 1,
                          'section': sectionC.text.toUpperCase(),
                          'classAdviserId': '',
                          'studentIds': <String>[],
                          'courseIds': <String>[]
                        });
                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Class $classId created'),
                            backgroundColor: AppColors.secondary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))));
                      }
                    },
                    child: const Text('Create'))
              ],
            ));
  }

  void _showEditClassDialog(
      BuildContext context, DataService ds, Map<String, dynamic> cls) {
    final yearC = TextEditingController(text: (cls['year']?.toString()) ?? '1');
    final sectionC =
        TextEditingController(text: cls['section'] as String? ?? 'A');

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Edit Class',
                  style: TextStyle(color: AppColors.textDark)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: yearC,
                          decoration: const InputDecoration(
                              labelText: 'Year', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: sectionC,
                          decoration: const InputDecoration(
                              labelText: 'Section',
                              border: OutlineInputBorder()))),
                ])
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      if (yearC.text.isNotEmpty && sectionC.text.isNotEmpty) {
                        ds.updateClass(cls['classId'] as String, {
                          'year': int.tryParse(yearC.text) ?? cls['year'],
                          'section': sectionC.text.toUpperCase()
                        });
                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Class updated'),
                            backgroundColor: AppColors.secondary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))));
                      }
                    },
                    child: const Text('Save'))
              ],
            ));
  }

  void _confirmDeleteClass(
      BuildContext context, DataService ds, String classId) {
    showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Delete class'),
                content: const Text(
                    'Delete this class and clear adviser assignments?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () {
                        ds.removeClass(classId);
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                      child: const Text('Delete'))
                ]));
  }
}
