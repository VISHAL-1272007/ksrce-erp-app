import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'persistence_service.dart';
import 'security_service.dart';
import 'firebase_service.dart';
import 'merge_util.dart';
import 'grade_util.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _timetable = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _faculty = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _mentorAssignments = [];
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _fees = [];
  List<Map<String, dynamic>> _certificates = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _eventRegistrations = [];
  List<Map<String, dynamic>> _leave = [];
  List<Map<String, dynamic>> _leaveBalance = [];
  List<Map<String, dynamic>> _library = [];
  List<Map<String, dynamic>> _placements = [];
  List<Map<String, dynamic>> _placementApplications = [];
  List<Map<String, dynamic>> _syllabus = [];
  List<Map<String, dynamic>> _research = [];
  List<Map<String, dynamic>> _facultyTimetable = [];
  List<Map<String, dynamic>> _courseOutcomes = [];
  List<Map<String, dynamic>> _courseDiary = [];
  List<Map<String, dynamic>> _profileEditRequests = [];
  List<Map<String, dynamic>> _questions = [];
  // RTDB subscription
  StreamSubscription? _rtdbResultsSub;

  // Logged in user info
  String? _currentUserId;
  String? _currentRole;
  Map<String, dynamic>? _currentStudent;
  Map<String, dynamic>? _currentFaculty;
  Map<String, dynamic> _roleMasterMap = {
    'masterKeys': <String, dynamic>{},
    'studentLinks': <String, dynamic>{},
    'facultyLinks': <String, dynamic>{},
    'hodLinks': <String, dynamic>{},
  };

  // Getters
  List<Map<String, dynamic>> get students => _students;
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get courses => _courses;
  List<Map<String, dynamic>> get attendance => _attendance;
  List<Map<String, dynamic>> get assignments => _assignments;
  List<Map<String, dynamic>> get results => _results;
  List<Map<String, dynamic>> get timetable => _timetable;
  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get complaints => _complaints;
  List<Map<String, dynamic>> get departments => _departments;
  List<Map<String, dynamic>> get faculty => _faculty;
  List<Map<String, dynamic>> get classes => _classes;
  List<Map<String, dynamic>> get mentorAssignments => _mentorAssignments;
  List<Map<String, dynamic>> get exams => _exams;
  List<Map<String, dynamic>> get fees => _fees;
  List<Map<String, dynamic>> get certificates => _certificates;
  List<Map<String, dynamic>> get events => _events;
  List<Map<String, dynamic>> get eventRegistrations => _eventRegistrations;
  List<Map<String, dynamic>> get leave => _leave;
  List<Map<String, dynamic>> get leaveBalance => _leaveBalance;
  List<Map<String, dynamic>> get library => _library;
  List<Map<String, dynamic>> get placements => _placements;
  List<Map<String, dynamic>> get placementApplications =>
      _placementApplications;
  List<Map<String, dynamic>> get syllabus => _syllabus;
  List<Map<String, dynamic>> get research => _research;
  List<Map<String, dynamic>> get facultyTimetable => _facultyTimetable;
  List<Map<String, dynamic>> get courseOutcomes => _courseOutcomes;
  List<Map<String, dynamic>> get courseDiary => _courseDiary;
  List<Map<String, dynamic>> get profileEditRequests => _profileEditRequests;
  List<Map<String, dynamic>> get questions => _questions;
  String? get currentUserId => _currentUserId;
  String? get currentRole => _currentRole;
  Map<String, dynamic>? get currentStudent => _currentStudent;
  Map<String, dynamic>? get currentFaculty => _currentFaculty;
  Map<String, dynamic> get roleMasterMap => _roleMasterMap;

  /// Returns the masterKey for the currently signed-in user (student/faculty/hod)
  String? get currentMasterKey {
    if (_currentUserId == null) return null;
    final sid = _currentUserId!;
    final studentLinks = (_roleMasterMap['studentLinks'] as Map?) ?? {};
    final facultyLinks = (_roleMasterMap['facultyLinks'] as Map?) ?? {};
    final hodLinks = (_roleMasterMap['hodLinks'] as Map?) ?? {};
    if (studentLinks.containsKey(sid)) {
      return (studentLinks[sid] as Map)['masterKey'] as String?;
    }
    if (facultyLinks.containsKey(sid)) {
      return (facultyLinks[sid] as Map)['masterKey'] as String?;
    }
    if (hodLinks.containsKey(sid)) {
      return (hodLinks[sid] as Map)['masterKey'] as String?;
    }
    return null;
  }

  Map<String, dynamic>? getMasterKeyNode(String masterKey) {
    if (masterKey.trim().isEmpty) return null;
    final mk = _roleMasterMap['masterKeys'] as Map<String, dynamic>?;
    final node = mk?[masterKey] as Map<String, dynamic>?;
    if (node == null) return null;
    return Map<String, dynamic>.from(node);
  }

  String? get activeMasterKey {
    final userId = _currentUserId;
    final linked = currentMasterKey;
    if (userId == null) return linked;
    final settings = getUserSettings(userId);
    final selected = settings['activeMasterKey']?.toString().trim() ?? '';
    if (selected.isNotEmpty && getMasterKeyNode(selected) != null) {
      return selected;
    }
    return linked;
  }

  String getMasterKeyLabel(String masterKey) {
    final node = getMasterKeyNode(masterKey);
    if (node == null) return masterKey;

    final departmentId = node['departmentId']?.toString() ?? '';
    final departmentName = (node['departmentName']?.toString() ?? '').trim();
    final year = node['year'];
    final section = (node['section']?.toString() ?? '').trim().toUpperCase();

    final baseName = departmentName.isNotEmpty
        ? departmentName
        : (departmentId.isNotEmpty ? departmentId : masterKey);
    if (year == null) {
      return '$baseName • Department';
    }

    final parts = <String>[baseName, 'Year $year'];
    if (section.isNotEmpty) parts.add('Section $section');
    return parts.join(' • ');
  }

  List<Map<String, dynamic>> getAvailableMasterKeys({String? role}) {
    final keys = _roleMasterMap['masterKeys'] as Map<String, dynamic>?;
    if (keys == null || keys.isEmpty) return <Map<String, dynamic>>[];

    final portalRole = (role ?? _currentRole ?? 'admin').toLowerCase();
    final currentStudentId = _currentUserId ?? '';
    final currentStudentLink = (_roleMasterMap['studentLinks'] as Map?)?[currentStudentId] as Map<String, dynamic>?;
    final currentFacultyLink = (_roleMasterMap['facultyLinks'] as Map?)?[currentStudentId] as Map<String, dynamic>?;
    final currentHodLink = (_roleMasterMap['hodLinks'] as Map?)?[currentStudentId] as Map<String, dynamic>?;

    String? departmentId;
    if (portalRole == 'student') {
      departmentId = currentStudentLink?['departmentId']?.toString();
    } else if (portalRole == 'faculty') {
      departmentId = currentFacultyLink?['departmentId']?.toString();
    } else if (portalRole == 'hod') {
      departmentId = currentHodLink?['departmentId']?.toString();
    }

    Iterable<MapEntry<String, dynamic>> entries = keys.entries;
    if (portalRole == 'student') {
      final key = activeMasterKey ?? currentMasterKey;
      if (key != null && keys.containsKey(key)) {
        entries = [MapEntry(key, keys[key])];
      }
    } else if (portalRole == 'faculty' || portalRole == 'hod') {
      if ((departmentId ?? '').isNotEmpty) {
        entries = keys.entries.where((entry) {
          final node = entry.value as Map<String, dynamic>?;
          return node?['departmentId']?.toString() == departmentId;
        });
      }
    }

    final options = entries.map((entry) {
      final node = Map<String, dynamic>.from(entry.value as Map);
      final deptId = node['departmentId']?.toString() ?? '';
      final deptName = (node['departmentName']?.toString() ?? '').trim();
      final year = node['year'];
      final section = (node['section']?.toString() ?? '').trim().toUpperCase();
      final title = year == null
          ? (deptName.isNotEmpty ? deptName : deptId)
          : [if (deptName.isNotEmpty) deptName else deptId, 'Year $year', if (section.isNotEmpty) 'Section $section']
              .where((part) => part.isNotEmpty)
              .join(' • ');
      return {
        'masterKey': entry.key,
        'title': title,
        'departmentId': deptId,
        'year': year,
        'section': section,
        'studentCount': (node['studentIds'] as List?)?.length ?? 0,
        'facultyCount': (node['facultyIds'] as List?)?.length ?? 0,
        'hodId': node['hodId'],
      };
    }).toList();

    options.sort((a, b) {
      final aDept = a['departmentId']?.toString() ?? '';
      final bDept = b['departmentId']?.toString() ?? '';
      final deptCompare = aDept.compareTo(bDept);
      if (deptCompare != 0) return deptCompare;
      final aYear = a['year'] == null ? -1 : int.tryParse(a['year'].toString()) ?? -1;
      final bYear = b['year'] == null ? -1 : int.tryParse(b['year'].toString()) ?? -1;
      if (aYear != bYear) return aYear.compareTo(bYear);
      final aSection = a['section']?.toString() ?? '';
      final bSection = b['section']?.toString() ?? '';
      return aSection.compareTo(bSection);
    });

    return options;
  }

  Future<void> setActiveMasterKey(String? masterKey) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final normalized = masterKey?.trim() ?? '';
    if (normalized.isNotEmpty && getMasterKeyNode(normalized) == null) {
      return;
    }

    final settings = Map<String, dynamic>.from(getUserSettings(userId));
    if (normalized.isEmpty) {
      settings.remove('activeMasterKey');
    } else {
      settings['activeMasterKey'] = normalized;
    }
    updateUserSettings(userId, settings);
    await PersistenceService.saveAll(_buildFullMap(), changedKeys: ['settings']);
  }

  /// Get list of student records linked to a masterKey
  List<Map<String, dynamic>> getStudentsForMasterKey(String masterKey) {
    final mk = _roleMasterMap['masterKeys'] as Map<String, dynamic>?;
    if (mk == null) return [];
    final node = mk[masterKey] as Map<String, dynamic>?;
    if (node == null) return [];
    final ids = (node['studentIds'] as List<dynamic>?)?.cast<String>() ?? [];
    return ids.map((id) => getStudentById(id)!).whereType<Map<String, dynamic>>().toList();
  }

  /// Get list of faculty records linked to a masterKey
  List<Map<String, dynamic>> getFacultyForMasterKey(String masterKey) {
    final mk = _roleMasterMap['masterKeys'] as Map<String, dynamic>?;
    if (mk == null) return [];
    final node = mk[masterKey] as Map<String, dynamic>?;
    if (node == null) return [];
    final ids = (node['facultyIds'] as List<dynamic>?)?.cast<String>() ?? [];
    return ids.map((id) => _faculty.firstWhere((f) => f['facultyId'] == id, orElse: () => <String, dynamic>{})).where((f) => f.isNotEmpty).toList();
  }

  /// Get HOD record for a masterKey (if available)
  Map<String, dynamic>? getHODForMasterKey(String masterKey) {
    final mk = _roleMasterMap['masterKeys'] as Map<String, dynamic>?;
    final node = mk?[masterKey] as Map<String, dynamic>?;
    if (node == null) return null;
    final hid = node['hodId'] as String?;
    if (hid == null || hid.isEmpty) return null;
    return _faculty.firstWhere((f) => f['facultyId'] == hid, orElse: () => <String, dynamic>{});
  }

  // Settings storage (persisted)
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> get settings => _settings;

  // ─── ROLE-BASED COLLECTION PRIORITY ─────────────────────────────────
  // Collections per role (loaded eagerly after core)
  static const _roleCollections = <String, List<String>>{
    'student': [
      'courses',
      'attendance',
      'assignments',
      'results',
      'timetable',
      'complaints',
      'fees',
      'certificates',
      'events',
      'eventRegistrations',
      'library',
      'placements',
      'placementApplications',
      'exams'
    ],
    'faculty': [
      'courses',
      'attendance',
      'assignments',
      'results',
      'timetable',
      'classes',
      'mentorAssignments',
      'exams',
      'events',
      'leave',
      'leaveBalance',
      'syllabus',
      'research',
      'facultyTimetable',
      'courseOutcomes',
      'courseDiary',
      'profileEditRequests',
      'complaints'
    ],
    'hod': [
      'courses',
      'attendance',
      'assignments',
      'results',
      'timetable',
      'classes',
      'mentorAssignments',
      'exams',
      'events',
      'leave',
      'leaveBalance',
      'syllabus',
      'research',
      'facultyTimetable',
      'courseOutcomes',
      'courseDiary',
      'profileEditRequests',
      'complaints'
    ],
    'admin': [
      'courses',
      'attendance',
      'assignments',
      'results',
      'timetable',
      'complaints',
      'classes',
      'mentorAssignments',
      'exams',
      'fees',
      'certificates',
      'events',
      'eventRegistrations',
      'leave',
      'leaveBalance',
      'library',
      'placements',
      'placementApplications',
      'syllabus',
      'research',
      'facultyTimetable',
      'courseOutcomes',
      'courseDiary',
      'profileEditRequests'
    ],
  };

  static const _portalModules = <String, List<String>>{
    'student': [
      'dashboard',
      'portal',
      'profile',
      'courses',
      'timetable',
      'syllabus',
      'attendance',
      'results',
      'assignments',
      'exams',
      'fees',
      'library',
      'notifications',
      'complaints',
      'leave',
      'certificates',
      'placements',
      'events',
      'files',
      'settings',
      'tutor',
      'notes',
      'workspace'
    ],
    'faculty': [
      'dashboard',
      'profile',
      'courses',
      'timetable',
      'syllabus',
      'attendance',
      'assignments',
      'grades',
      'students',
      'mentees',
      'adviser',
      'exams',
      'leave',
      'course-details',
      'course-diary',
      'research',
      'notifications',
      'profile-approvals',
      'complaints',
      'reports',
      'events',
      'files',
      'master-key',
      'settings',
      'generator'
    ],
    'hod': [
      'dashboard',
      'profile',
      'faculty',
      'students',
      'courses',
      'my-courses',
      'timetable',
      'syllabus',
      'course-details',
      'course-diary',
      'attendance',
      'assignments',
      'grades',
      'exams',
      'class-advisers',
      'mentors',
      'leave',
      'research',
      'notifications',
      'profile-approvals',
      'reports',
      'events',
      'files',
      'master-key',
      'settings'
    ],
    'admin': [
      'dashboard',
      'departments',
      'faculty',
      'students',
      'courses',
      'classes',
      'hod-assignment',
      'users',
      'reports',
      'notifications',
      'profile-approvals',
      'files',
      'master-key',
      'settings'
    ],
  };

  static const _defaultEditableModules = <String, List<String>>{
    'student': ['profile', 'complaints', 'leave', 'files', 'settings'],
    'faculty': [
      'profile',
      'attendance',
      'assignments',
      'grades',
      'leave',
      'course-diary',
      'files',
      'settings'
    ],
    'hod': [
      'profile',
      'attendance',
      'assignments',
      'grades',
      'leave',
      'course-diary',
      'files',
      'settings'
    ],
    'admin': [
      'dashboard',
      'departments',
      'faculty',
      'students',
      'courses',
      'classes',
      'hod-assignment',
      'users',
      'reports',
      'notifications',
      'profile-approvals',
      'files',
      'settings'
    ],
  };

  /// All collection keys (for full seed / persist)
  static const _allKeys = [
    'students',
    'users',
    'courses',
    'attendance',
    'assignments',
    'results',
    'timetable',
    'notifications',
    'complaints',
    'departments',
    'faculty',
    'classes',
    'mentorAssignments',
    'exams',
    'fees',
    'certificates',
    'events',
    'eventRegistrations',
    'leave',
    'leaveBalance',
    'library',
    'placements',
    'placementApplications',
    'syllabus',
    'research',
    'facultyTimetable',
    'courseOutcomes',
    'courseDiary',
    'profileEditRequests',
  ];

  /// Track which collections have been loaded so lazy loading can fill gaps.
  final Set<String> _loadedCollections = {};

  /// Optimized data loading:
  /// 1. Load from localStorage instantly (no network wait)
  /// 2. If no local data, seed from bundled JSON assets
  /// 3. Sync from Firebase cloud in background (non-blocking)
  Future<void> loadAllData() async {
    if (_isLoaded) return;
    try {
      // Initialize persistence
      await PersistenceService.init();

      // ── STEP 1: Try local cache first (instant, ~5ms) ──
      final local = PersistenceService.loadLocal();
      if (local != null) {
        _hydrateFromMap(local);
        _refreshRoleMasterMap();
        _loadedCollections.addAll(_allKeys);
        _applyAllPreApprovedChanges();
        _isLoaded = true;
        _skipPersist = true;
        notifyListeners();
        _skipPersist = false;
        // Start RTDB listeners
        _startRTDBListeners();

        // ── STEP 2: Background cloud sync (non-blocking) ──
        _backgroundCloudSync();
        return;
      }

      // ── STEP 3: No local data — try cloud ──
      final cloud = await PersistenceService.loadFromCloud();
      if (cloud != null) {
        _hydrateFromMap(cloud);
        _refreshRoleMasterMap();
        _loadedCollections.addAll(_allKeys);
        await PersistenceService.saveLocal(cloud); // cache locally
        _applyAllPreApprovedChanges();
        _isLoaded = true;
        _skipPersist = true;
        notifyListeners();
        _skipPersist = false;
        // Start RTDB listeners
        _startRTDBListeners();
        return;
      }

      // ── STEP 4: First run — seed from bundled JSON assets ──
      await _seedFromAssets();
      _refreshRoleMasterMap();
      _loadedCollections.addAll(_allKeys);
      _applyAllPreApprovedChanges();
      _isLoaded = true;
      _skipPersist = true;
      notifyListeners();
      _skipPersist = false;

      // Persist seed data (local + cloud)
      await PersistenceService.seedSave(_buildFullMap());
      // Start RTDB listeners
      _startRTDBListeners();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  /// Hydrate all fields from a persisted map.
  void _hydrateFromMap(Map<String, dynamic> data) {
    _students = _asList(data['students']);
    _users = _asList(data['users']);
    _courses = _asList(data['courses']);
    _attendance = _asList(data['attendance']);
    _assignments = _asList(data['assignments']);
    _results = _asList(data['results']);
    _timetable = _asList(data['timetable']);
    _notifications = _asList(data['notifications']);
    _complaints = _asList(data['complaints']);
    _departments = _asList(data['departments']);
    _faculty = _asList(data['faculty']);
    _classes = _asList(data['classes']);
    _mentorAssignments = _asList(data['mentorAssignments']);
    _exams = _asList(data['exams']);
    _fees = _asList(data['fees']);
    _certificates = _asList(data['certificates']);
    _events = _asList(data['events']);
    _eventRegistrations = _asList(data['eventRegistrations']);
    _leave = _asList(data['leave']);
    _leaveBalance = _asList(data['leaveBalance']);
    _library = _asList(data['library']);
    _placements = _asList(data['placements']);
    _placementApplications = _asList(data['placementApplications']);
    _syllabus = _asList(data['syllabus']);
    _research = _asList(data['research']);
    _facultyTimetable = _asList(data['facultyTimetable']);
    _courseOutcomes = _asList(data['courseOutcomes']);
    _courseDiary = _asList(data['courseDiary']);
    _profileEditRequests = _asList(data['profileEditRequests']);
    _questions = _asList(data['questions']);
    final settingsRaw = data['settings'];
    if (settingsRaw is List && settingsRaw.isNotEmpty) {
      _settings = Map<String, dynamic>.from(settingsRaw.first as Map);
    } else if (settingsRaw is Map) {
      _settings = Map<String, dynamic>.from(settingsRaw);
    } else {
      _settings = {};
    }
  }

  String _masterKeyFor(String departmentId, {int? year, String? section}) {
    final dept = departmentId.trim().isEmpty ? 'UNKNOWN' : departmentId.trim();
    final y = year?.toString() ?? 'ALL';
    final sec = (section ?? 'ALL').trim().toUpperCase();
    return '$dept|$y|$sec';
  }

  void _refreshRoleMasterMap() {
    final masterKeys = <String, Map<String, dynamic>>{};
    final studentLinks = <String, Map<String, dynamic>>{};
    final facultyLinks = <String, Map<String, dynamic>>{};
    final hodLinks = <String, Map<String, dynamic>>{};

    for (final dept in _departments) {
      final departmentId = (dept['departmentId'] as String? ?? '').trim();
      if (departmentId.isEmpty) continue;

      final hod = _faculty.firstWhere(
        (f) => (f['departmentId'] as String? ?? '').trim() == departmentId && f['isHOD'] == true,
        orElse: () => <String, dynamic>{},
      );
      final hodId = hod['facultyId'] as String? ?? '';

      final deptFaculty = _faculty
          .where((f) => (f['departmentId'] as String? ?? '').trim() == departmentId)
          .toList();
      final deptStudents = _students
          .where((s) => (s['departmentId'] as String? ?? '').trim() == departmentId)
          .toList();
      final deptClasses = _classes
          .where((c) => (c['departmentId'] as String? ?? '').trim() == departmentId)
          .toList();

      final deptKey = _masterKeyFor(departmentId);
      masterKeys[deptKey] = {
        'masterKey': deptKey,
        'departmentId': departmentId,
        'departmentName': dept['name'] ?? dept['departmentName'] ?? '',
        'hodId': hodId,
        'hodName': hod['name'] ?? '',
        'facultyIds': deptFaculty.map((f) => f['facultyId']).whereType<String>().toList(),
        'studentIds': deptStudents.map((s) => s['studentId']).whereType<String>().toList(),
        'classIds': deptClasses.map((c) => c['classId']).whereType<String>().toList(),
      };

      if (hodId.isNotEmpty) {
        hodLinks[hodId] = {
          'masterKey': deptKey,
          'departmentId': departmentId,
          'hodId': hodId,
          'hodName': hod['name'] ?? '',
          'facultyIds': deptFaculty.map((f) => f['facultyId']).whereType<String>().toList(),
          'studentIds': deptStudents.map((s) => s['studentId']).whereType<String>().toList(),
          'classIds': deptClasses.map((c) => c['classId']).whereType<String>().toList(),
        };
      }

      for (final fac in deptFaculty) {
        final facultyId = fac['facultyId'] as String? ?? '';
        if (facultyId.isEmpty) continue;
        final mentorIds = (fac['menteeIds'] as List<dynamic>?)?.cast<String>() ?? [];
        final adviserClasses = _classes
            .where((c) => c['classAdviserId'] == facultyId)
            .map((c) => c['classId'])
            .whereType<String>()
            .toList();
        facultyLinks[facultyId] = {
          'masterKey': deptKey,
          'facultyId': facultyId,
          'facultyName': fac['name'] ?? '',
          'role': fac['isHOD'] == true ? 'hod' : 'faculty',
          'departmentId': departmentId,
          'hodId': hodId,
          'mentorStudentIds': mentorIds,
          'classIds': adviserClasses,
        };
      }

      for (final student in deptStudents) {
        final studentId = student['studentId'] as String? ?? '';
        if (studentId.isEmpty) continue;
        final year = int.tryParse(student['year']?.toString() ?? '');
        final section = student['section']?.toString();
        final studentKey = _masterKeyFor(departmentId, year: year, section: section);
        final mentorId = student['mentorId'] as String? ?? '';
        final adviserId = student['classAdviserId'] as String? ?? '';
        studentLinks[studentId] = {
          'masterKey': studentKey,
          'studentId': studentId,
          'studentName': student['name'] ?? '',
          'departmentId': departmentId,
          'year': student['year'],
          'section': student['section'],
          'mentorId': mentorId,
          'classAdviserId': adviserId,
          'hodId': hodId,
        };
        masterKeys.putIfAbsent(studentKey, () => {
          'masterKey': studentKey,
          'departmentId': departmentId,
          'year': year,
          'section': section,
          'hodId': hodId,
          'facultyIds': <String>[],
          'studentIds': <String>[],
          'classIds': <String>[],
        });
        (masterKeys[studentKey]!['studentIds'] as List<String>).add(studentId);
      }
    }

    _roleMasterMap = {
      'masterKeys': masterKeys,
      'studentLinks': studentLinks,
      'facultyLinks': facultyLinks,
      'hodLinks': hodLinks,
    };
  }

  /// Build the full data map for persistence.
  Map<String, dynamic> _buildFullMap() {
    return {
      'students': _students,
      'users': _users,
      'courses': _courses,
      'attendance': _attendance,
      'assignments': _assignments,
      'results': _results,
      'timetable': _timetable,
      'notifications': _notifications,
      'complaints': _complaints,
      'departments': _departments,
      'faculty': _faculty,
      'classes': _classes,
      'mentorAssignments': _mentorAssignments,
      'exams': _exams,
      'fees': _fees,
      'certificates': _certificates,
      'events': _events,
      'eventRegistrations': _eventRegistrations,
      'leave': _leave,
      'leaveBalance': _leaveBalance,
      'library': _library,
      'placements': _placements,
      'placementApplications': _placementApplications,
      'syllabus': _syllabus,
      'research': _research,
      'facultyTimetable': _facultyTimetable,
      'courseOutcomes': _courseOutcomes,
      'courseDiary': _courseDiary,
      'profileEditRequests': _profileEditRequests,
      'questions': _questions,
      'settings': _settings.isNotEmpty ? [_settings] : [],
    };
  }

  // ------------------ Grade / What-If helpers ------------------
  double calculateCurrentCoursePctFromAssessments(List<Map<String, dynamic>> assessments) {
    return calculateCurrentCoursePct(assessments);
  }

  double simulateCoursePctFromAssessments(List<Map<String, dynamic>> assessments, Map<String, double> hypothetical) {
    return simulateCoursePct(assessments, hypothetical);
  }

  Map<String, dynamic> requiredMarksForTargetFromAssessments(List<Map<String, dynamic>> assessments, double targetPct,
      {String strategy = 'even'}) {
    return requiredMarksForTarget(assessments, targetPct, strategy: strategy);
  }

  // ------------------ Attendance analytics ------------------
  /// Returns per-course attendance summary and trend for a student.
  /// Output: { courseId: { percent, sessions, present, absent, risk: bool } }
  Map<String, Map<String, dynamic>> attendanceAnalyticsForStudent(String studentId, {double riskThreshold = 75.0}) {
    final Map<String, List<Map<String, dynamic>>> byCourse = {};
    for (final a in _attendance) {
      final sid = a['studentId']?.toString();
      if (sid != studentId) continue;
      final cid = a['courseId']?.toString() ?? 'UNKNOWN';
      byCourse.putIfAbsent(cid, () => []).add(Map<String, dynamic>.from(a));
    }

    final out = <String, Map<String, dynamic>>{};
    byCourse.forEach((courseId, records) {
      var present = 0;
      var sessions = 0;
      for (final r in records) {
        final attended = r['present'] ?? r['attended'] ?? r['isPresent'];
        if (attended is bool) {
          sessions++;
          if (attended) present++;
        } else if (attended is num) {
          sessions++;
          if (attended > 0) present++;
        } else if (r.containsKey('status')) {
          sessions++;
          if (r['status']?.toString().toLowerCase() == 'present') present++;
        }
      }
      final percent = sessions > 0 ? (present / sessions) * 100.0 : 100.0;
      out[courseId] = {
        'percent': double.parse(percent.toStringAsFixed(2)),
        'sessions': sessions,
        'present': present,
        'absent': sessions - present,
        'risk': percent < riskThreshold,
      };
    });

    return out;
  }

  // ------------------ Notifications ------------------
  /// Add an in-app notification for a user (student or faculty).
  void notifyUser(String userId, String title, String message, {String type = 'info'}) {
    final note = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'seen': false,
      'ts': DateTime.now().toIso8601String(),
    };
    _notifications.insert(0, note);
    // persist lightweight notifications slice
    PersistenceService.saveAll(_buildFullMap(), changedKeys: ['notifications']);
    notifyListeners();
  }

  /// Upsert an exam-level total (e.g., CIA1/CIA2) for a student and recompute
  /// the derived 'Avg of 2 (20)' entry if both CIA1 and CIA2 are present.
  Future<void> upsertExamResultForStudent({required String studentId, required String courseCode, required String examType, required double obtained, required double maxMarks}) async {
    // find existing result row
    final existing = _results.firstWhere((r) => (r['courseId'] == courseCode || r['courseCode'] == courseCode) && (r['examType'] ?? '') == examType && r['studentId'] == studentId, orElse: () => <String, dynamic>{});
    if (existing.isNotEmpty) {
      // update
      existing['obtainedMarks'] = obtained;
      existing['maxMarks'] = maxMarks;
      try {
        final om = (obtained);
        final mm = (maxMarks);
        existing['status'] = (om >= 0.4 * mm) ? 'Pass' : 'Fail';
      } catch (_) {}
    } else {
      final result = {
        'resultId': 'RES${(_results.length + 1).toString().padLeft(3, '0')}',
        'courseId': courseCode,
        'courseCode': courseCode,
        'courseName': courseCode,
        'studentId': studentId,
        'examType': examType,
        'obtainedMarks': obtained,
        'maxMarks': maxMarks,
        'published': false,
        'gradedDate': DateTime.now().toIso8601String().substring(0, 10),
      };
      _results.add(result);
    }

    // Persist to RTDB so updates are visible to other clients immediately
    final resultMap = existing.isNotEmpty ? existing : _results.last;
    try {
      final rid = resultMap['resultId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final path = '/results/$courseCode/$examType/$rid';
      await FirebaseService.instance.set(path, resultMap);
    } catch (e) {
      // fallback: save locally
      await PersistenceService.saveAll(_buildFullMap());
    }
    notifyListeners();

    // Recompute Avg of 2 (20)
    try {
      final cia1 = _results.firstWhere((r) => (r['courseId'] == courseCode || r['courseCode'] == courseCode) && (r['examType'] ?? '') == 'CIA1' && r['studentId'] == studentId, orElse: () => <String, dynamic>{});
      final cia2 = _results.firstWhere((r) => (r['courseId'] == courseCode || r['courseCode'] == courseCode) && (r['examType'] ?? '') == 'CIA2' && r['studentId'] == studentId, orElse: () => <String, dynamic>{});
      if (cia1.isNotEmpty && cia2.isNotEmpty) {
        final v1 = (cia1['obtainedMarks'] as num?)?.toDouble() ?? 0.0;
        final v2 = (cia2['obtainedMarks'] as num?)?.toDouble() ?? 0.0;
        final avgOfTwo = ((v1 + v2) / 2.0) * (20.0 / 50.0);
        // upsert Avg of 2 (20) row
        final existingAvg = _results.firstWhere((r) => (r['courseId'] == courseCode || r['courseCode'] == courseCode) && (r['examType'] ?? '') == 'Avg of 2 (20)' && r['studentId'] == studentId, orElse: () => <String, dynamic>{});
        if (existingAvg.isNotEmpty) {
          existingAvg['obtainedMarks'] = double.parse(avgOfTwo.toStringAsFixed(2));
          existingAvg['maxMarks'] = 20.0;
        } else {
          final avgResult = {
            'resultId': 'RES${(_results.length + 1).toString().padLeft(3, '0')}',
            'courseId': courseCode,
            'courseCode': courseCode,
            'courseName': courseCode,
            'studentId': studentId,
            'examType': 'Avg of 2 (20)',
            'obtainedMarks': double.parse(avgOfTwo.toStringAsFixed(2)),
            'maxMarks': 20.0,
            'published': false,
            'gradedDate': DateTime.now().toIso8601String().substring(0, 10),
          };
          _results.add(avgResult);
          try {
            final rid2 = avgResult['resultId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
            final path2 = '/results/$courseCode/Avg of 2 (20)/$rid2';
            await FirebaseService.instance.set(path2, avgResult);
          } catch (e) {
            await PersistenceService.saveAll(_buildFullMap());
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to recompute Avg of 2 (20): $e');
    }
  }

  /// Background cloud sync — merges cloud data silently without blocking UI.
  Future<void> _backgroundCloudSync() async {
    try {
      final cloud = await PersistenceService.loadFromCloud();
      if (cloud != null) {
        // Merge cloud data — cloud is the source of truth for shared data
        _hydrateFromMap(cloud);
        await PersistenceService.saveLocal(cloud);
        _skipPersist = true;
        notifyListeners();
        _skipPersist = false;
      }
    } catch (e) {
      debugPrint('Background cloud sync failed: $e');
    }
  }

  /// Lazy-load collections for a specific role (call after login).
  /// Ensures role-relevant data is fresh from cloud.
  Future<void> loadForRole(String role) async {
    final needed = _roleCollections[role] ?? [];
    if (needed.isEmpty) return;

    // Only fetch collections we haven't loaded from cloud yet
    final toFetch =
        needed.where((k) => !_loadedCollections.contains(k)).toList();
    if (toFetch.isEmpty) return;

    try {
      final cloudParts =
          await PersistenceService.loadCollectionsFromCloud(toFetch);
      if (cloudParts.isNotEmpty) {
        for (final key in cloudParts.keys) {
          _setCollection(key, _asList(cloudParts[key]));
          _loadedCollections.add(key);
        }
        _skipPersist = true;
        notifyListeners();
        _skipPersist = false;
      }
    } catch (e) {
      debugPrint('Role-based lazy load failed: $e');
    }
  }

  /// Set a specific collection list by key name.
  void _setCollection(String key, List<Map<String, dynamic>> data) {
    switch (key) {
      case 'students':
        _students = data;
        break;
      case 'users':
        _users = data;
        break;
      case 'courses':
        _courses = data;
        break;
      case 'attendance':
        _attendance = data;
        break;
      case 'assignments':
        _assignments = data;
        break;
      case 'results':
        _results = data;
        break;
      case 'timetable':
        _timetable = data;
        break;
      case 'notifications':
        _notifications = data;
        break;
      case 'complaints':
        _complaints = data;
        break;
      case 'departments':
        _departments = data;
        break;
      case 'faculty':
        _faculty = data;
        break;
      case 'classes':
        _classes = data;
        break;
      case 'mentorAssignments':
        _mentorAssignments = data;
        break;
      case 'exams':
        _exams = data;
        break;
      case 'fees':
        _fees = data;
        break;
      case 'certificates':
        _certificates = data;
        break;
      case 'events':
        _events = data;
        break;
      case 'eventRegistrations':
        _eventRegistrations = data;
        break;
      case 'leave':
        _leave = data;
        break;
      case 'leaveBalance':
        _leaveBalance = data;
        break;
      case 'library':
        _library = data;
        break;
      case 'placements':
        _placements = data;
        break;
      case 'placementApplications':
        _placementApplications = data;
        break;
      case 'syllabus':
        _syllabus = data;
        break;
      case 'research':
        _research = data;
        break;
      case 'facultyTimetable':
        _facultyTimetable = data;
        break;
      case 'courseOutcomes':
        _courseOutcomes = data;
        break;
      case 'courseDiary':
        _courseDiary = data;
        break;
      case 'profileEditRequests':
        _profileEditRequests = data;
        break;
    }
  }

  /// Seed all data from bundled JSON asset files (first run only).
  Future<void> _seedFromAssets() async {
    final futures = await Future.wait([
      _loadJson('assets/data/students.json'), // 0
      _loadJson('assets/data/users.json'), // 1
      _loadJson('assets/data/courses.json'), // 2
      _loadJson('assets/data/attendance.json'), // 3
      _loadJson('assets/data/assignments.json'), // 4
      _loadJson('assets/data/results.json'), // 5
      _loadJson('assets/data/timetable.json'), // 6
      _loadJson('assets/data/notifications.json'), // 7
      _loadJson('assets/data/complaints.json'), // 8
      _loadJson('assets/data/departments.json'), // 9
      _loadJson('assets/data/faculty.json'), // 10
      _loadJson('assets/data/classes.json'), // 11
      _loadJson('assets/data/mentor_assignments.json'), // 12
      _loadJson('assets/data/exams.json'), // 13
      _loadJson('assets/data/fees.json'), // 14
      _loadJson('assets/data/certificates.json'), // 15
      _loadJson('assets/data/events.json'), // 16
      _loadJson('assets/data/event_registrations.json'), // 17
      _loadJson('assets/data/leave.json'), // 18
      _loadJson('assets/data/leave_balance.json'), // 19
      _loadJson('assets/data/library.json'), // 20
      _loadJson('assets/data/placements.json'), // 21
      _loadJson('assets/data/placement_applications.json'), // 22
      _loadJson('assets/data/syllabus.json'), // 23
      _loadJson('assets/data/research.json'), // 24
      _loadJson('assets/data/faculty_timetable.json'), // 25
      _loadJson('assets/data/course_outcomes.json'), // 26
      _loadJson('assets/data/course_diary.json'), // 27
      _loadJson('assets/data/profile_edit_requests.json'), // 28
    ]);
    _students = futures[0];
    _users = futures[1];
    _courses = futures[2];
    _attendance = futures[3];
    _assignments = futures[4];
    _results = futures[5];
    _timetable = futures[6];
    _notifications = futures[7];
    _complaints = futures[8];
    _departments = futures[9];
    _faculty = futures[10];
    _classes = futures[11];
    _mentorAssignments = futures[12];
    _exams = futures[13];
    _fees = futures[14];
    _certificates = futures[15];
    _events = futures[16];
    _eventRegistrations = futures[17];
    _leave = futures[18];
    _leaveBalance = futures[19];
    _library = futures[20];
    _placements = futures[21];
    _placementApplications = futures[22];
    _syllabus = futures[23];
    _research = futures[24];
    _facultyTimetable = futures[25];
    _courseOutcomes = futures[26];
    _courseDiary = futures[27];
    _profileEditRequests = futures[28];
    _seedInitialQuestions();
  }

  /// Persist data: saves locally instantly, debounces cloud writes.
  /// Cloud uses PATCH (not PUT) so Firebase only updates changed collections.
  Future<void> _persistAll() async {
    try {
      await PersistenceService.saveAll(_buildFullMap());
    } catch (e) {
      debugPrint('Error persisting data: $e');
    }
  }

  /// Reset all data to defaults (clear localStorage, reload from assets)
  Future<void> resetAllData() async {
    await PersistenceService.flush(); // flush pending writes first
    await PersistenceService.clearAll();
    _isLoaded = false;
    _loadedCollections.clear();
    _currentUserId = null;
    _currentRole = null;
    _currentStudent = null;
    _currentFaculty = null;
    _settings = {};
    await loadAllData();
  }

  /// Override notifyListeners to auto-persist data on every mutation.
  /// Local save is instant (~5ms); cloud saves are debounced (2s batching).
  bool _skipPersist = false;
  @override
  void notifyListeners() {
    super.notifyListeners();
    if (_isLoaded && !_skipPersist) {
      _persistAll();
    }
  }

  /// Start listeners for Realtime Database results feed and merge updates.
  void _startRTDBListeners() {
    try {
      _rtdbResultsSub?.cancel();
      _rtdbResultsSub = FirebaseService.instance.onValue('/results').listen(
        (event) {
          try {
            final snap = (event as dynamic).snapshot;
            if (snap == null) return;
            final val = snap.value;
            if (val == null) return;
            if (val is Map) {
              _mergeRemoteResultsMap(val);
            }
          } catch (e) {
            debugPrint('RTDB event parse error: $e');
          }
        },
        onError: (err) => debugPrint('RTDB listen error: $err'),
      );
    } catch (e) {
      debugPrint('Failed to start RTDB listeners: $e');
    }
  }

  void _mergeRemoteResultsMap(Map remote) {
    final beforeCount = _results.length;
    final res = mergeRemoteResults(_results, remote);
    final added = res['added'] ?? 0;
    final updated = res['updated'] ?? 0;
    if (added > 0 || updated > 0) {
      debugPrint('RTDB merge: added=$added updated=$updated (before=$beforeCount after=${_results.length})');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _rtdbResultsSub?.cancel();
    super.dispose();
  }

  /// Apply changes from requests that were already approved in the JSON data
  void _applyAllPreApprovedChanges() {
    for (final req in _profileEditRequests) {
      if (req['status'] == 'approved') {
        _applyProfileChanges(req);
      }
    }
  }

  /// Safely cast a dynamic value (from Firebase JSON) to List<Map<String, dynamic>>.
  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) =>
              e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _loadJson(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final List<dynamic> data = json.decode(jsonString);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading $path: $e');
      return [];
    }
  }

  // ─── AUTH (Z++ Security — SHA-256 hashed passwords + brute-force protection) ───
  /// Returns null on success, or an error message on failure.
  String? loginSecure(String userId, String password) {
    // Brute-force check
    final lockSeconds = SecurityService.getLockedOutSeconds(userId);
    if (lockSeconds > 0) {
      return 'Account locked. Try again in $lockSeconds seconds.';
    }

    for (final user in _users) {
      if (user['id'] == userId) {
        final storedHash = user['password'] as String? ?? '';
        if (SecurityService.verifyPassword(password, userId, storedHash)) {
          SecurityService.resetAttempts(userId);
          _currentUserId = userId;
          final resolvedPortalRole = _resolvePortalRoleForUser(user);
          if (resolvedPortalRole == 'student') {
            _currentRole = 'student';
            _currentStudent = _students.firstWhere(
              (s) => s['studentId'] == userId,
              orElse: () => <String, dynamic>{},
            );
            _currentFaculty = null;
          } else if (resolvedPortalRole == 'hod') {
            _currentRole = 'hod';
            _currentFaculty = _faculty.firstWhere(
              (f) => f['facultyId'] == userId,
              orElse: () => <String, dynamic>{},
            );
            _currentStudent = null;
          } else if (resolvedPortalRole == 'faculty') {
            _currentRole = 'faculty';
            _currentFaculty = _faculty.firstWhere(
              (f) => f['facultyId'] == userId,
              orElse: () => <String, dynamic>{},
            );
            _currentStudent = null;
          } else {
            _currentRole = 'admin';
            _currentStudent = null;
            _currentFaculty = null;
          }
          // Lazy-load role-specific collections from cloud (background)
          if (_currentRole != null) {
            loadForRole(_currentRole!);
          }
          notifyListeners();
          return null; // success
        } else {
          SecurityService.recordFailedAttempt(userId);
          final locked = SecurityService.getLockedOutSeconds(userId);
          if (locked > 0)
            return 'Account locked for ${SecurityService.lockoutDuration.inMinutes} minutes.';
          return 'Invalid password.';
        }
      }
    }
    return 'User ID not found.';
  }

  /// Legacy login fallback (kept for compatibility)
  bool login(String userId, String password) {
    return loginSecure(userId, password) == null;
  }

  void logout() {
    _currentUserId = null;
    _currentRole = null;
    _currentStudent = null;
    _currentFaculty = null;
    notifyListeners();
  }

  // ─── STUDENT QUERIES ────────────────────────────────────
  List<Map<String, dynamic>> getStudentCourses(String studentId, {String? masterKey}) {
    final student = _students.firstWhere(
      (s) => s['studentId'] == studentId,
      orElse: () => <String, dynamic>{},
    );
    final enrolled =
        (student['enrolledCourses'] as List<dynamic>?)?.cast<String>() ?? [];
    if (enrolled.isEmpty) {
      // Fallback: return courses matching student's department
      final dept = student['departmentId'] ?? student['department'] ?? '';
      final deptCourses = _courses
          .where((c) => c['departmentId'] == dept || c['department'] == dept)
          .toList();
      if (masterKey == null) return deptCourses;
      final node = getMasterKeyNode(masterKey);
      if (node == null) return deptCourses;
      final selectedDept = node['departmentId']?.toString() ?? '';
      final selectedYear = node['year']?.toString() ?? '';
      final selectedSection = node['section']?.toString().toUpperCase() ?? '';
      return deptCourses.where((c) {
        final courseDept = (c['departmentId'] ?? c['department'] ?? '').toString();
        if (selectedDept.isNotEmpty && courseDept != selectedDept) return false;
        if (selectedYear.isNotEmpty && c['year']?.toString() != selectedYear) return false;
        if (selectedSection.isNotEmpty) {
          final courseSection = c['section']?.toString().toUpperCase() ?? '';
          if (courseSection.isNotEmpty && courseSection != selectedSection) return false;
        }
        return true;
      }).toList();
    }
    final courses = _courses.where((c) => enrolled.contains(c['courseId'])).toList();
    if (masterKey == null) return courses;
    final node = getMasterKeyNode(masterKey);
    if (node == null) return courses;
    final selectedDept = node['departmentId']?.toString() ?? '';
    final selectedYear = node['year']?.toString() ?? '';
    final selectedSection = node['section']?.toString().toUpperCase() ?? '';
    return courses.where((c) {
      final courseDept = (c['departmentId'] ?? c['department'] ?? '').toString();
      if (selectedDept.isNotEmpty && courseDept != selectedDept) return false;
      if (selectedYear.isNotEmpty && c['year']?.toString() != selectedYear) return false;
      if (selectedSection.isNotEmpty) {
        final courseSection = c['section']?.toString().toUpperCase() ?? '';
        if (courseSection.isNotEmpty && courseSection != selectedSection) return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> getStudentAttendance() => _attendance;
  List<Map<String, dynamic>> getStudentAssignments() => _assignments;
  List<Map<String, dynamic>> getStudentResults() => _results;

  List<Map<String, dynamic>> getTimetableForDay(String day) {
    return _timetable.where((t) => t['day'] == day).toList();
  }

  List<Map<String, dynamic>> getUnreadNotifications() {
    return _notifications.where((n) => n['isRead'] == false).toList();
  }

  int get unreadNotificationCount => getUnreadNotifications().length;

  void markNotificationRead(String notifId) {
    final idx =
        _notifications.indexWhere((n) => n['notificationId'] == notifId);
    if (idx != -1) {
      _notifications[idx]['isRead'] = true;
      notifyListeners();
    }
  }

  void addComplaint(Map<String, dynamic> complaint) {
    complaint['complaintId'] =
        'CMP${(_complaints.length + 1).toString().padLeft(3, '0')}';
    complaint['submittedDate'] =
        DateTime.now().toIso8601String().substring(0, 10);
    complaint['status'] = 'pending';
    _complaints.add(complaint);
    notifyListeners();
  }

  double get overallAttendancePercentage {
    if (_attendance.isEmpty) return 0;
    int totalPresent = 0, totalClasses = 0;
    for (final a in _attendance) {
      totalPresent += (a['attendedClasses'] as int? ?? 0);
      totalClasses += (a['totalClasses'] as int? ?? 0);
    }
    return totalClasses > 0 ? (totalPresent / totalClasses * 100) : 0;
  }

  double get currentCGPA {
    if (_currentStudent != null && _currentStudent!['cgpa'] != null) {
      return (_currentStudent!['cgpa'] as num).toDouble();
    }
    return 0.0;
  }

  int get pendingAssignmentsCount {
    return _assignments.where((a) => a['status'] == 'pending').length;
  }

  // Get mentor info for current student
  Map<String, dynamic>? getStudentMentor(String studentId) {
    final student = _students.firstWhere(
      (s) => s['studentId'] == studentId,
      orElse: () => <String, dynamic>{},
    );
    final mentorId = student['mentorId'] as String?;
    if (mentorId == null) return null;
    return _faculty.firstWhere(
      (f) => f['facultyId'] == mentorId,
      orElse: () => <String, dynamic>{},
    );
  }

  // Get class adviser info for current student
  Map<String, dynamic>? getStudentClassAdviser(String studentId) {
    final student = _students.firstWhere(
      (s) => s['studentId'] == studentId,
      orElse: () => <String, dynamic>{},
    );
    final adviserId = student['classAdviserId'] as String?;
    if (adviserId == null) return null;
    return _faculty.firstWhere(
      (f) => f['facultyId'] == adviserId,
      orElse: () => <String, dynamic>{},
    );
  }

  // ─── FACULTY QUERIES ────────────────────────────────────
  List<Map<String, dynamic>> getFacultyCourses(String facultyId, {String? masterKey}) {
    final courses = _courses.where((c) => c['facultyId'] == facultyId).toList();
    if (masterKey == null) return courses;
    final node = getMasterKeyNode(masterKey);
    if (node == null) return courses;
    final deptId = node['departmentId']?.toString() ?? '';
    final year = node['year']?.toString() ?? '';
    final section = node['section']?.toString().toUpperCase() ?? '';
    return courses.where((c) {
      final courseDept = (c['departmentId'] ?? c['department'] ?? '').toString();
      if (deptId.isNotEmpty && courseDept != deptId) return false;
      if (year.isNotEmpty && c['year']?.toString() != year) return false;
      if (section.isNotEmpty) {
        final courseSection = c['section']?.toString().toUpperCase() ?? '';
        if (courseSection.isNotEmpty && courseSection != section) return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> getMentees(String facultyId) {
    final fac = _faculty.firstWhere(
      (f) => f['facultyId'] == facultyId,
      orElse: () => <String, dynamic>{},
    );
    final menteeIds =
        (fac['menteeIds'] as List<dynamic>?)?.cast<String>() ?? [];
    return _students.where((s) => menteeIds.contains(s['studentId'])).toList();
  }

  Map<String, dynamic>? getAdviserClass(String facultyId) {
    final fac = _faculty.firstWhere(
      (f) => f['facultyId'] == facultyId,
      orElse: () => <String, dynamic>{},
    );
    if (fac['isClassAdviser'] != true) return null;
    final adviserFor = fac['adviserFor'] as Map<String, dynamic>?;
    if (adviserFor == null) return null;
    return _classes.firstWhere(
      (c) =>
          c['departmentId'] == adviserFor['departmentId'] &&
          c['year'] == adviserFor['year'] &&
          c['section'] == adviserFor['section'],
      orElse: () => <String, dynamic>{},
    );
  }

  List<Map<String, dynamic>> getCourseStudents(String courseId) {
    return _students.where((s) {
      final enrolled =
          (s['enrolledCourses'] as List<dynamic>?)?.cast<String>() ?? [];
      return enrolled.contains(courseId);
    }).toList();
  }

  bool isFacultyClassAdviser(String facultyId) {
    final fac = _faculty.firstWhere(
      (f) => f['facultyId'] == facultyId,
      orElse: () => <String, dynamic>{},
    );
    return fac['isClassAdviser'] == true;
  }

  // ─── HOD QUERIES ────────────────────────────────────────
  Map<String, dynamic>? getHODDepartment(String facultyId) {
    final fac = _faculty.firstWhere(
      (f) => f['facultyId'] == facultyId,
      orElse: () => <String, dynamic>{},
    );
    final deptId = fac['departmentId'] as String?;
    if (deptId == null) return null;
    return _departments.firstWhere(
      (d) => d['departmentId'] == deptId,
      orElse: () => <String, dynamic>{},
    );
  }

  List<Map<String, dynamic>> getDepartmentFaculty(String departmentId) {
    return _faculty.where((f) => f['departmentId'] == departmentId).toList();
  }

  List<Map<String, dynamic>> getDepartmentStudents(String departmentId) {
    return _students.where((s) => s['departmentId'] == departmentId).toList();
  }

  List<Map<String, dynamic>> getDepartmentClasses(String departmentId) {
    return _classes.where((c) => c['departmentId'] == departmentId).toList();
  }

  List<Map<String, dynamic>> getStudentsForClass(String classId) {
    final cls = _classes.firstWhere(
      (c) => c['classId'] == classId,
      orElse: () => <String, dynamic>{},
    );
    if (cls.isEmpty) return <Map<String, dynamic>>[];

    final ids = (cls['studentIds'] as List<dynamic>?)?.cast<String>() ?? [];
    final byIds = ids
        .map((id) => getStudentById(id))
        .where((s) => s != null)
        .cast<Map<String, dynamic>>()
        .toList();
    if (byIds.isNotEmpty) return byIds;

    // Fallback for older data where class.studentIds was not maintained.
    final deptId = cls['departmentId']?.toString() ?? '';
    final year = cls['year']?.toString() ?? '';
    final section = cls['section']?.toString().toUpperCase() ?? '';
    return _students.where((s) {
      return (s['departmentId']?.toString() ?? '') == deptId &&
          (s['year']?.toString() ?? '') == year &&
          (s['section']?.toString().toUpperCase() ?? '') == section;
    }).toList();
  }

  List<Map<String, dynamic>> getDepartmentCourses(String departmentId) {
    return _courses.where((c) => c['departmentId'] == departmentId).toList();
  }

  List<Map<String, dynamic>> getDepartmentMentorAssignments(
      String departmentId) {
    return _mentorAssignments
        .where((m) => m['departmentId'] == departmentId)
        .toList();
  }

  // ─── HOD ACTIONS ────────────────────────────────────────
  void assignClassAdviser(String classId, String facultyId) {
    // Update class
    final classIdx = _classes.indexWhere((c) => c['classId'] == classId);
    if (classIdx == -1) return;
    final oldAdviserId = _classes[classIdx]['classAdviserId'] as String?;
    _classes[classIdx]['classAdviserId'] = facultyId;

    // Remove old adviser flag
    if (oldAdviserId != null) {
      final oldIdx = _faculty.indexWhere((f) => f['facultyId'] == oldAdviserId);
      if (oldIdx != -1) {
        _faculty[oldIdx]['isClassAdviser'] = false;
        _faculty[oldIdx]['adviserFor'] = null;
      }
    }

    // Set new adviser
    final facIdx = _faculty.indexWhere((f) => f['facultyId'] == facultyId);
    if (facIdx != -1) {
      _faculty[facIdx]['isClassAdviser'] = true;
      _faculty[facIdx]['adviserFor'] = {
        'departmentId': _classes[classIdx]['departmentId'],
        'year': _classes[classIdx]['year'],
        'section': _classes[classIdx]['section'],
      };
    }

    // Update students in this class
    final studentIds =
        (_classes[classIdx]['studentIds'] as List<dynamic>?)?.cast<String>() ??
            [];
    for (final sId in studentIds) {
      final sIdx = _students.indexWhere((s) => s['studentId'] == sId);
      if (sIdx != -1) {
        _students[sIdx]['classAdviserId'] = facultyId;
      }
    }

    notifyListeners();
    _refreshRoleMasterMap();
  }

  void assignMentor(String facultyId, List<String> studentIds,
      String departmentId, int year, String section) {
    // Remove old mentor assignment for this faculty
    _mentorAssignments.removeWhere((m) => m['mentorId'] == facultyId);

    // Get faculty name
    final fac = _faculty.firstWhere(
      (f) => f['facultyId'] == facultyId,
      orElse: () => <String, dynamic>{},
    );
    final facName = fac['name'] as String? ?? '';

    // Create new assignment
    _mentorAssignments.add({
      'mentorId': facultyId,
      'mentorName': facName,
      'departmentId': departmentId,
      'year': year,
      'section': section,
      'menteeIds': studentIds,
    });

    // Update faculty
    final facIdx = _faculty.indexWhere((f) => f['facultyId'] == facultyId);
    if (facIdx != -1) {
      _faculty[facIdx]['menteeIds'] = studentIds;
    }

    // Update students
    for (final sId in studentIds) {
      final sIdx = _students.indexWhere((s) => s['studentId'] == sId);
      if (sIdx != -1) {
        _students[sIdx]['mentorId'] = facultyId;
      }
    }

    notifyListeners();
    _refreshRoleMasterMap();
  }

  // ─── ADMIN ACTIONS ──────────────────────────────────────
  void addDepartment(Map<String, dynamic> dept) {
    dept['departmentId'] = 'DEPT_${dept['departmentCode']}';
    _departments.add(dept);
    notifyListeners();
  }

  void addFaculty(Map<String, dynamic> fac) {
    final id = 'FAC${(_faculty.length + 1).toString().padLeft(3, '0')}';
    fac['facultyId'] = id;
    fac['isHOD'] = false;
    fac['isClassAdviser'] = false;
    fac['adviserFor'] = null;
    fac['menteeIds'] = <String>[];
    fac['courseIds'] = <String>[];
    _faculty.add(fac);

    // Create user account with hashed password
    final defaultPwd = 'ksrce@${id.toLowerCase()}';
    _users.add({
      'id': id,
      'password': SecurityService.hashPassword(defaultPwd, id),
      'role': 'faculty',
      'label': 'Faculty - ${fac['name']}',
    });

    notifyListeners();
  }

  void addStudent(Map<String, dynamic> student) {
    final id = 'STU${(_students.length + 1).toString().padLeft(3, '0')}';
    student['studentId'] = id;
    student['enrolledCourses'] = <String>[];
    student['mentorId'] = null;
    student['classAdviserId'] = null;
    _students.add(student);

    // Create user account with hashed password
    final defaultPwd = 'ksrce@${id.toLowerCase()}';
    _users.add({
      'id': id,
      'password': SecurityService.hashPassword(defaultPwd, id),
      'role': 'student',
      'label': 'Student - ${student['name']}',
    });

    // Add to class if exists
    final classId =
        '${(student['departmentId'] as String? ?? '').replaceAll('DEPT_', '')}_${student['year']}_${student['section']}';
    final classIdx = _classes.indexWhere((c) => c['classId'] == classId);
    if (classIdx != -1) {
      (_classes[classIdx]['studentIds'] as List<dynamic>).add(id);
      // Set class adviser
      student['classAdviserId'] = _classes[classIdx]['classAdviserId'];
    }

    notifyListeners();
  }

  void assignHOD(String departmentId, String facultyId) {
    // Remove old HOD
    final deptIdx =
        _departments.indexWhere((d) => d['departmentId'] == departmentId);
    if (deptIdx == -1) return;
    final oldHodId = _departments[deptIdx]['hodId'] as String?;
    if (oldHodId != null) {
      final oldIdx = _faculty.indexWhere((f) => f['facultyId'] == oldHodId);
      if (oldIdx != -1) _faculty[oldIdx]['isHOD'] = false;
      // Revert user role to faculty
      final oldUserIdx = _users.indexWhere((u) => u['id'] == oldHodId);
      if (oldUserIdx != -1) _users[oldUserIdx]['role'] = 'faculty';
    }

    // Set new HOD
    _departments[deptIdx]['hodId'] = facultyId;
    final facIdx = _faculty.indexWhere((f) => f['facultyId'] == facultyId);
    if (facIdx != -1) _faculty[facIdx]['isHOD'] = true;
    // Update user role
    final userIdx = _users.indexWhere((u) => u['id'] == facultyId);
    if (userIdx != -1) _users[userIdx]['role'] = 'hod';

    notifyListeners();
    _refreshRoleMasterMap();
  }

  void addCourse(Map<String, dynamic> course) {
    final id = course['courseCode'] as String? ??
        'CRS${(_courses.length + 1).toString().padLeft(3, '0')}';
    course['courseId'] = id;
    course['totalClasses'] = 0;
    course['attendedClasses'] = 0;

    // Set faculty name from faculty list
    final facultyId = course['facultyId'] as String?;
    if (facultyId != null) {
      final fac = _faculty.firstWhere(
        (f) => f['facultyId'] == facultyId,
        orElse: () => <String, dynamic>{},
      );
      course['facultyName'] = fac['name'] ?? '';
      // Add to faculty's courseIds
      final facIdx = _faculty.indexWhere((f) => f['facultyId'] == facultyId);
      if (facIdx != -1) {
        final courseIds = ((_faculty[facIdx]['courseIds'] as List<dynamic>?)
                    ?.cast<String>() ??
                [])
            .toList();
        if (!courseIds.contains(id)) {
          courseIds.add(id);
          _faculty[facIdx]['courseIds'] = courseIds;
        }
      }
    }

    _courses.add(course);
    notifyListeners();
  }

  void enrollStudentInCourse(String studentId, String courseId) {
    final sIdx = _students.indexWhere((s) => s['studentId'] == studentId);
    if (sIdx == -1) return;
    final enrolled = ((_students[sIdx]['enrolledCourses'] as List<dynamic>?)
                ?.cast<String>() ??
            [])
        .toList();
    if (!enrolled.contains(courseId)) {
      enrolled.add(courseId);
      _students[sIdx]['enrolledCourses'] = enrolled;
      notifyListeners();
    }
  }

  void bulkEnrollClass(String classId, List<String> courseIds) {
    final classEntry = _classes.firstWhere(
      (c) => c['classId'] == classId,
      orElse: () => <String, dynamic>{},
    );
    final studentIds =
        (classEntry['studentIds'] as List<dynamic>?)?.cast<String>() ?? [];
    for (final sId in studentIds) {
      for (final cId in courseIds) {
        enrollStudentInCourse(sId, cId);
      }
    }
    // Update class courseIds
    final classIdx = _classes.indexWhere((c) => c['classId'] == classId);
    if (classIdx != -1) {
      _classes[classIdx]['courseIds'] = courseIds;
    }
    notifyListeners();
  }

  void addClass(Map<String, dynamic> classEntry) {
    _classes.add(classEntry);
    notifyListeners();
  }

  void updateClass(String classId, Map<String, dynamic> updated) {
    final idx = _classes.indexWhere((c) => c['classId'] == classId);
    if (idx == -1) return;

    updated['classId'] = classId;
    _classes[idx] = {..._classes[idx], ...updated};

    // If adviser changed, update faculty flags and students
    final adviserId = _classes[idx]['classAdviserId'] as String?;
    if (adviserId != null && adviserId.isNotEmpty) {
      final facIdx = _faculty.indexWhere((f) => f['facultyId'] == adviserId);
      if (facIdx != -1) {
        _faculty[facIdx]['isClassAdviser'] = true;
        _faculty[facIdx]['adviserFor'] = {
          'departmentId': _classes[idx]['departmentId'],
          'year': _classes[idx]['year'],
          'section': _classes[idx]['section'],
        };
      }
    }

    notifyListeners();
  }

  void removeClass(String classId) {
    final idx = _classes.indexWhere((c) => c['classId'] == classId);
    if (idx == -1) return;

    final classEntry = _classes[idx];
    final adviserId = classEntry['classAdviserId'] as String?;

    // Clear adviser flags
    if (adviserId != null && adviserId.isNotEmpty) {
      final facIdx = _faculty.indexWhere((f) => f['facultyId'] == adviserId);
      if (facIdx != -1) {
        _faculty[facIdx]['isClassAdviser'] = false;
        _faculty[facIdx]['adviserFor'] = null;
      }
    }

    // Clear students' adviser references
    final studentIds =
        (classEntry['studentIds'] as List<dynamic>?)?.cast<String>() ?? [];
    for (final sId in studentIds) {
      final sIdx = _students.indexWhere((s) => s['studentId'] == sId);
      if (sIdx != -1) {
        _students[sIdx]['classAdviserId'] = null;
      }
    }

    _classes.removeAt(idx);
    notifyListeners();
  }

  // ─── UTILITY ────────────────────────────────────────────
  String getDepartmentName(String departmentId) {
    final dept = _departments.firstWhere(
      (d) => d['departmentId'] == departmentId,
      orElse: () => <String, dynamic>{},
    );
    return dept['departmentName'] as String? ?? departmentId;
  }

  String getDepartmentCode(String departmentId) {
    final dept = _departments.firstWhere(
      (d) => d['departmentId'] == departmentId,
      orElse: () => <String, dynamic>{},
    );
    return dept['departmentCode'] as String? ?? '';
  }

  String getFacultyName(String facultyId) {
    final fac = _faculty.firstWhere(
      (f) => f['facultyId'] == facultyId,
      orElse: () => <String, dynamic>{},
    );
    return fac['name'] as String? ?? facultyId;
  }

  Map<String, dynamic>? getFacultyById(String facultyId) {
    try {
      return _faculty.firstWhere((f) => f['facultyId'] == facultyId);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? getStudentById(String studentId) {
    try {
      return _students.firstWhere((s) => s['studentId'] == studentId);
    } catch (_) {
      return null;
    }
  }

  // ─── EXAM QUERIES ─────────────────────────────────────
  List<Map<String, dynamic>> getStudentExams(String studentId, {String? masterKey}) {
    final student = getStudentById(studentId);
    if (student == null) return _exams;
    final enrolled =
        (student['enrolledCourses'] as List<dynamic>?)?.cast<String>() ?? [];
    final deptId = student['departmentId'] as String? ?? '';
    final exams = _exams.where((e) =>
        enrolled.contains(e['courseId']) || e['departmentId'] == deptId).toList();
    if (masterKey == null) return exams;
    final node = getMasterKeyNode(masterKey);
    if (node == null) return exams;
    final selectedDept = node['departmentId']?.toString() ?? '';
    final selectedStudentIds = getStudentsForMasterKey(masterKey)
        .map((s) => s['studentId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    return exams.where((e) {
      if (selectedDept.isNotEmpty && e['departmentId']?.toString() != selectedDept) return false;
      if (selectedStudentIds.isNotEmpty && !selectedStudentIds.contains(studentId)) return false;
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> getFacultyExams(String facultyId, {String? masterKey}) {
    final exams = _exams.where((e) => e['facultyId'] == facultyId).toList();
    if (masterKey == null) return exams;
    final node = getMasterKeyNode(masterKey);
    if (node == null) return exams;
    final selectedDept = node['departmentId']?.toString() ?? '';
    final selectedFacultyIds = (node['facultyIds'] as List<dynamic>?)?.cast<String>() ?? [];
    return exams.where((e) {
      if (selectedDept.isNotEmpty && e['departmentId']?.toString() != selectedDept) return false;
      if (selectedFacultyIds.isNotEmpty && !selectedFacultyIds.contains(facultyId)) return false;
      return true;
    }).toList();
  }

  // ─── FEE QUERIES ──────────────────────────────────────
  List<Map<String, dynamic>> getStudentFees(String studentId) {
    return _fees.where((f) => f['studentId'] == studentId).toList();
  }

  double getStudentTotalFees(String studentId) {
    return getStudentFees(studentId)
        .fold(0.0, (sum, f) => sum + ((f['amount'] as num?)?.toDouble() ?? 0));
  }

  double getStudentPaidFees(String studentId) {
    return getStudentFees(studentId)
        .fold(0.0, (sum, f) => sum + ((f['paid'] as num?)?.toDouble() ?? 0));
  }

  double getStudentPendingFees(String studentId) {
    return getStudentFees(studentId)
        .fold(0.0, (sum, f) => sum + ((f['pending'] as num?)?.toDouble() ?? 0));
  }

  // ─── CERTIFICATE QUERIES ──────────────────────────────
  List<Map<String, dynamic>> getStudentCertificates(String studentId) {
    return _certificates.where((c) => c['studentId'] == studentId).toList();
  }

  void requestCertificate(
      String studentId, String type, int fee, int processingDays) {
    _certificates.add({
      'certId': 'CERT${(_certificates.length + 1).toString().padLeft(3, '0')}',
      'studentId': studentId,
      'type': type,
      'status': 'pending',
      'requestDate': DateTime.now().toIso8601String().substring(0, 10),
      'fee': fee,
      'processingDays': processingDays,
    });
    notifyListeners();
  }

  // ─── EVENT QUERIES ────────────────────────────────────
  List<Map<String, dynamic>> getUpcomingEvents() {
    return _events.where((e) => e['status'] == 'upcoming').toList();
  }

  List<Map<String, dynamic>> getCompletedEvents() {
    return _events.where((e) => e['status'] == 'completed').toList();
  }

  List<Map<String, dynamic>> getStudentRegisteredEvents(String studentId) {
    final regIds = _eventRegistrations
        .where((r) => r['studentId'] == studentId)
        .map((r) => r['eventId'] as String)
        .toSet();
    return _events.where((e) => regIds.contains(e['eventId'])).toList();
  }

  bool isStudentRegisteredForEvent(String studentId, String eventId) {
    return _eventRegistrations
        .any((r) => r['studentId'] == studentId && r['eventId'] == eventId);
  }

  void registerForEvent(String studentId, String eventId) {
    if (isStudentRegisteredForEvent(studentId, eventId)) return;
    _eventRegistrations.add({
      'registrationId':
          'REG${(_eventRegistrations.length + 1).toString().padLeft(3, '0')}',
      'eventId': eventId,
      'studentId': studentId,
      'registeredDate': DateTime.now().toIso8601String().substring(0, 10),
    });
    final idx = _events.indexWhere((e) => e['eventId'] == eventId);
    if (idx != -1) {
      _events[idx]['registeredCount'] =
          ((_events[idx]['registeredCount'] as int?) ?? 0) + 1;
    }
    notifyListeners();
  }

  // ─── LEAVE QUERIES ────────────────────────────────────
  List<Map<String, dynamic>> getUserLeave(String userId) {
    return _leave.where((l) => l['userId'] == userId).toList();
  }

  List<Map<String, dynamic>> getUserLeaveBalance(String userId) {
    return _leaveBalance.where((l) => l['userId'] == userId).toList();
  }

  List<Map<String, dynamic>> getStudentLeaveRequests(String facultyId) {
    // Get mentees' leave requests for faculty to approve
    final mentees = getMentees(facultyId);
    final menteeIds = mentees.map((m) => m['studentId'] as String).toSet();
    return _leave
        .where(
            (l) => menteeIds.contains(l['userId']) && l['status'] == 'pending')
        .toList();
  }

  void applyLeave(Map<String, dynamic> leaveEntry) {
    leaveEntry['leaveId'] =
        'LV${(_leave.length + 1).toString().padLeft(3, '0')}';
    leaveEntry['appliedDate'] =
        DateTime.now().toIso8601String().substring(0, 10);
    leaveEntry['status'] = 'pending';
    _leave.add(leaveEntry);
    notifyListeners();
  }

  // ─── LIBRARY QUERIES ──────────────────────────────────
  List<Map<String, dynamic>> getStudentLibrary(String studentId) {
    return _library.where((b) => b['studentId'] == studentId).toList();
  }

  List<Map<String, dynamic>> getStudentIssuedBooks(String studentId) {
    return _library
        .where((b) => b['studentId'] == studentId && b['status'] == 'issued')
        .toList();
  }

  List<Map<String, dynamic>> getStudentReturnedBooks(String studentId) {
    return _library
        .where((b) => b['studentId'] == studentId && b['status'] == 'returned')
        .toList();
  }

  int getStudentOverdueBooks(String studentId) {
    return _library
        .where((b) => b['studentId'] == studentId && b['status'] == 'overdue')
        .length;
  }

  double getStudentLibraryFines(String studentId) {
    return _library
        .where((b) => b['studentId'] == studentId && b['fine'] != null)
        .fold(0.0, (sum, b) => sum + ((b['fine'] as num?)?.toDouble() ?? 0));
  }

  // ─── PLACEMENT QUERIES ────────────────────────────────
  List<Map<String, dynamic>> getUpcomingPlacements() {
    return _placements.where((p) => p['status'] == 'upcoming').toList();
  }

  List<Map<String, dynamic>> getCompletedPlacements() {
    return _placements.where((p) => p['status'] == 'completed').toList();
  }

  List<Map<String, dynamic>> getStudentPlacementApplications(String studentId) {
    return _placementApplications
        .where((a) => a['studentId'] == studentId)
        .toList();
  }

  Map<String, dynamic>? getPlacementById(String placementId) {
    try {
      return _placements.firstWhere((p) => p['placementId'] == placementId);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? getCourseById(String courseId) {
    try {
      return _courses.firstWhere((c) => c['courseId'] == courseId);
    } catch (_) {
      return null;
    }
  }

  void applyForPlacement(String studentId, String placementId) {
    _placementApplications.add({
      'applicationId':
          'APP${(_placementApplications.length + 1).toString().padLeft(3, '0')}',
      'placementId': placementId,
      'studentId': studentId,
      'status': 'applied',
      'appliedDate': DateTime.now().toIso8601String().substring(0, 10),
    });
    notifyListeners();
  }

  // ─── SYLLABUS QUERIES ─────────────────────────────────
  List<Map<String, dynamic>> getCourseSyllabus(String courseId) {
    return _syllabus.where((s) => s['courseId'] == courseId).toList();
  }

  List<Map<String, dynamic>> getFacultySyllabus(String facultyId) {
    return _syllabus.where((s) => s['facultyId'] == facultyId).toList();
  }

  double getSyllabusProgress(Map<String, dynamic> syllabusEntry) {
    final units = (syllabusEntry['units'] as List<dynamic>?) ?? [];
    if (units.isEmpty) return 0;
    int totalHours = 0, completedHours = 0;
    for (final u in units) {
      totalHours += (u['totalHours'] as int?) ?? 0;
      completedHours += (u['completedHours'] as int?) ?? 0;
    }
    return totalHours > 0 ? (completedHours / totalHours * 100) : 0;
  }

  // ─── COURSE OUTCOMES QUERIES ───────────────────────────
  Map<String, dynamic>? getCourseOutcomeDetails(String courseId) {
    try {
      return _courseOutcomes.firstWhere((c) => c['courseId'] == courseId);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> getFacultyCourseOutcomes(String facultyId) {
    return _courseOutcomes.where((c) => c['facultyId'] == facultyId).toList();
  }

  List<Map<String, dynamic>> getCourseOutcomeCOs(String courseId) {
    final details = getCourseOutcomeDetails(courseId);
    if (details == null) return [];
    return ((details['courseOutcomes'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> getCourseUnitCOMapping(String courseId) {
    final details = getCourseOutcomeDetails(courseId);
    if (details == null) return [];
    return ((details['unitCOMapping'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>();
  }

  void addCourseOutcomeEntry(Map<String, dynamic> entry) {
    final idx =
        _courseOutcomes.indexWhere((c) => c['courseId'] == entry['courseId']);
    if (idx >= 0) {
      _courseOutcomes[idx] = entry;
    } else {
      _courseOutcomes.add(entry);
    }
    notifyListeners();
  }

  void updateCourseOutcome(
      String courseId, String coId, Map<String, dynamic> updatedCO) {
    final details = getCourseOutcomeDetails(courseId);
    if (details == null) return;
    final cos = ((details['courseOutcomes'] as List<dynamic>?) ?? []);
    final idx = cos.indexWhere((c) => c['coId'] == coId);
    if (idx >= 0) {
      cos[idx] = updatedCO;
    } else {
      cos.add(updatedCO);
    }
    details['courseOutcomes'] = cos;
    details['lastUpdated'] = DateTime.now().toIso8601String().substring(0, 10);
    notifyListeners();
  }

  void addCOToUnit(String courseId, int unitNo, String coId) {
    final details = getCourseOutcomeDetails(courseId);
    if (details == null) return;
    final mappings = ((details['unitCOMapping'] as List<dynamic>?) ?? []);
    final unitIdx = mappings.indexWhere((m) => m['unitNo'] == unitNo);
    if (unitIdx >= 0) {
      final coList = List<String>.from(
          (mappings[unitIdx]['coList'] as List<dynamic>?) ?? []);
      if (!coList.contains(coId)) {
        coList.add(coId);
        mappings[unitIdx]['coList'] = coList;
      }
    } else {
      mappings.add({
        'unitNo': unitNo,
        'coList': [coId],
        'poMapping': []
      });
    }
    details['lastUpdated'] = DateTime.now().toIso8601String().substring(0, 10);
    notifyListeners();
  }

  // ─── RESEARCH QUERIES ─────────────────────────────────

  // ─── COURSE DIARY / TIMETABLE LOG ─────────────────────
  List<Map<String, dynamic>> getFacultyDiary(String facultyId) {
    return _courseDiary.where((d) => d['facultyId'] == facultyId).toList()
      ..sort((a, b) {
        final cmp = (b['date'] ?? '').compareTo(a['date'] ?? '');
        if (cmp != 0) return cmp;
        return ((a['hour'] as int?) ?? 0).compareTo((b['hour'] as int?) ?? 0);
      });
  }

  List<Map<String, dynamic>> getCourseDiary(String courseId) {
    return _courseDiary.where((d) => d['courseId'] == courseId).toList()
      ..sort((a, b) {
        final cmp = (b['date'] ?? '').compareTo(a['date'] ?? '');
        if (cmp != 0) return cmp;
        return ((a['hour'] as int?) ?? 0).compareTo((b['hour'] as int?) ?? 0);
      });
  }

  List<Map<String, dynamic>> getDiaryByDate(String facultyId, String date) {
    return _courseDiary
        .where((d) => d['facultyId'] == facultyId && d['date'] == date)
        .toList()
      ..sort((a, b) =>
          ((a['hour'] as int?) ?? 0).compareTo((b['hour'] as int?) ?? 0));
  }

  void addDiaryEntry(Map<String, dynamic> entry) {
    entry['diaryId'] =
        'DRY${(_courseDiary.length + 1).toString().padLeft(3, '0')}';
    _courseDiary.add(Map<String, dynamic>.from(entry));
    notifyListeners();
  }

  void updateDiaryEntry(String diaryId, Map<String, dynamic> updated) {
    final idx = _courseDiary.indexWhere((d) => d['diaryId'] == diaryId);
    if (idx != -1) {
      _courseDiary[idx] = {..._courseDiary[idx], ...updated};
      notifyListeners();
    }
  }

  int getDiaryEntryCount(String facultyId, String courseId) {
    return _courseDiary
        .where((d) => d['facultyId'] == facultyId && d['courseId'] == courseId)
        .length;
  }

  List<String> getDiaryCoveredTopics(String courseId, int unitNo) {
    return _courseDiary
        .where((d) => d['courseId'] == courseId && d['unitNo'] == unitNo)
        .map((d) => d['topicCovered']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
  }

  // ─── RESEARCH QUERIES (original) ──────────────────────
  List<Map<String, dynamic>> getFacultyResearch(String facultyId) {
    return _research.where((r) => r['facultyId'] == facultyId).toList();
  }

  List<Map<String, dynamic>> getFacultyPublications(String facultyId) {
    return _research
        .where((r) =>
            r['facultyId'] == facultyId &&
            (r['type'] == 'journal' || r['type'] == 'conference'))
        .toList();
  }

  List<Map<String, dynamic>> getFacultyProjects(String facultyId) {
    return _research
        .where((r) => r['facultyId'] == facultyId && r['type'] == 'project')
        .toList();
  }

  List<Map<String, dynamic>> getFacultyPhDScholars(String facultyId) {
    return _research
        .where((r) => r['facultyId'] == facultyId && r['type'] == 'phdScholar')
        .toList();
  }

  int getFacultyTotalCitations(String facultyId) {
    return getFacultyResearch(facultyId)
        .fold(0, (sum, r) => sum + ((r['citations'] as int?) ?? 0));
  }

  // ─── FACULTY TIMETABLE QUERIES ────────────────────────
  List<Map<String, dynamic>> getFacultyTimetableForDay(
      String facultyId, String day) {
    final entry = _facultyTimetable
        .where((t) => t['facultyId'] == facultyId && t['day'] == day)
        .toList();
    if (entry.isEmpty) return [];
    final slots = (entry.first['slots'] as List<dynamic>?) ?? [];
    return slots.cast<Map<String, dynamic>>();
  }

  List<String> getFacultyTimetableDays(String facultyId) {
    return _facultyTimetable
        .where((t) => t['facultyId'] == facultyId)
        .map((t) => t['day'] as String)
        .toList();
  }

  int getFacultyWeeklyHours(String facultyId) {
    int total = 0;
    for (final t
        in _facultyTimetable.where((t) => t['facultyId'] == facultyId)) {
      total += ((t['slots'] as List<dynamic>?)?.length ?? 0);
    }
    return total;
  }

  // ─── FACULTY ATTENDANCE QUERIES ───────────────────────
  List<Map<String, dynamic>> getCourseAttendance(String courseId, {String? masterKey}) {
    final attendance = _attendance.where((a) => a['courseId'] == courseId).toList();
    if (masterKey == null) return attendance;
    final node = getMasterKeyNode(masterKey);
    if (node == null) return attendance;
    final deptId = node['departmentId']?.toString() ?? '';
    if (deptId.isEmpty) return attendance;
    return attendance.where((a) => a['departmentId']?.toString() == deptId).toList();
  }

  // ─── PROFILE EDIT REQUEST WORKFLOW ────────────────────

  /// Get all edit requests submitted by a user
  List<Map<String, dynamic>> getMyEditRequests(String userId) {
    return _profileEditRequests
        .where((r) => r['requesterId'] == userId)
        .toList()
      ..sort((a, b) =>
          (b['submittedDate'] ?? '').compareTo(a['submittedDate'] ?? ''));
  }

  /// Get pending requests where this user is the current approver
  /// Uses the first pending step in approvalChain and matches approverId.
  List<Map<String, dynamic>> getPendingApprovals(String userId, String role) {
    return _profileEditRequests.where((r) {
      final chain = (r['approvalChain'] as List<dynamic>?) ?? [];
      for (final step in chain) {
        final s = step as Map<String, dynamic>;
        if (s['status'] != 'pending') continue;
        final approverId = (s['approverId'] as String?) ?? '';
        // Legacy admin placeholder support.
        if (approverId == 'ADMIN' && role == 'admin') return true;
        return approverId == userId;
      }
      return false;
    }).toList()
      ..sort((a, b) =>
          (b['submittedDate'] ?? '').compareTo(a['submittedDate'] ?? ''));
  }

  /// Get count of pending approvals for badge
  int getPendingApprovalCount(String userId, String role) {
    return getPendingApprovals(userId, role).length;
  }

  /// Submit a new profile edit request
  void submitProfileEditRequest(Map<String, dynamic> request) {
    request['requestId'] =
        'PER${(_profileEditRequests.length + 1).toString().padLeft(3, '0')}';
    request['submittedDate'] =
        DateTime.now().toIso8601String().substring(0, 10);
    request['lastUpdated'] = request['submittedDate'];
    _profileEditRequests.add(Map<String, dynamic>.from(request));
    notifyListeners();
  }

  Map<String, String> _resolveUserContact(String userId) {
    final uid = userId.trim().toUpperCase();
    if (uid.isEmpty)
      return const {'name': '', 'email': '', 'phone': '', 'role': ''};

    final student = _students.firstWhere(
      (s) => (s['studentId'] as String? ?? '').toUpperCase() == uid,
      orElse: () => <String, dynamic>{},
    );
    if (student.isNotEmpty) {
      return {
        'name': (student['name'] as String?) ?? uid,
        'email': (student['email'] as String?) ?? '',
        'phone': (student['phone'] as String?) ?? '',
        'role': 'student',
      };
    }

    final faculty = _faculty.firstWhere(
      (f) => (f['facultyId'] as String? ?? '').toUpperCase() == uid,
      orElse: () => <String, dynamic>{},
    );
    if (faculty.isNotEmpty) {
      final role = faculty['isHOD'] == true ? 'hod' : 'faculty';
      return {
        'name': (faculty['name'] as String?) ?? uid,
        'email': (faculty['email'] as String?) ?? '',
        'phone': (faculty['phone'] as String?) ?? '',
        'role': role,
      };
    }

    final user = _users.firstWhere(
      (u) => (u['id'] as String? ?? '').toUpperCase() == uid,
      orElse: () => <String, dynamic>{},
    );
    return {
      'name': (user['label'] as String?) ?? uid,
      'email': '',
      'phone': '',
      'role': (user['role'] as String?) ?? '',
    };
  }

  void _addWorkflowNotification({
    required String title,
    required String message,
    String recipientId = 'all',
    String recipientRole = 'all',
    String type = 'workflow',
    Map<String, dynamic>? metadata,
  }) {
    _notifications.insert(0, {
      'notificationId':
          'NTF${(_notifications.length + 1).toString().padLeft(3, '0')}',
      'title': title,
      'message': message,
      'type': type,
      'recipientId': recipientId,
      'recipientRole': recipientRole,
      'metadata': metadata ?? <String, dynamic>{},
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    });
  }

  void _sendEmailStub({
    required String toUserId,
    required String event,
    required String subject,
    required String body,
    Map<String, dynamic>? payload,
  }) {
    final contact = _resolveUserContact(toUserId);
    debugPrint(
      '[EMAIL_STUB] event=$event toUserId=$toUserId toEmail=${contact['email']} '
      'subject="$subject" payload=${payload ?? <String, dynamic>{}} body="$body"',
    );
  }

  void _sendSmsStub({
    required String toUserId,
    required String event,
    required String message,
    Map<String, dynamic>? payload,
  }) {
    final contact = _resolveUserContact(toUserId);
    debugPrint(
      '[SMS_STUB] event=$event toUserId=$toUserId toPhone=${contact['phone']} '
      'payload=${payload ?? <String, dynamic>{}} message="$message"',
    );
  }

  String _displayNameForUser(String userId) {
    return _resolveUserContact(userId)['name'] ?? userId;
  }

  /// Submit a forgot-password request that follows role-based approvals:
  /// student -> mentor(if assigned) -> HOD
  /// faculty -> HOD
  /// hod -> admin
  /// Returns null on success or an error message on failure.
  String? submitPasswordResetRequest(String userId, {String reason = ''}) {
    final uid = userId.trim().toUpperCase();
    if (uid.isEmpty) return 'Please enter your User ID.';

    final user = _users.firstWhere(
      (u) => (u['id'] as String? ?? '').toUpperCase() == uid,
      orElse: () => <String, dynamic>{},
    );
    if (user.isEmpty) return 'User ID "$uid" not found.';

    final role = (user['role'] as String? ?? '').toLowerCase();

    final hasPending = _profileEditRequests.any((r) {
      final isPasswordReset =
          (r['requestType'] as String? ?? '') == 'password_reset';
      final sameUser = (r['requesterId'] as String? ?? '') == uid;
      final status = (r['status'] as String? ?? '');
      final isClosed = status == 'approved' || status == 'rejected';
      return isPasswordReset && sameUser && !isClosed;
    });
    if (hasPending) {
      return 'A password reset request is already pending for $uid.';
    }

    final requesterName = _resolveRequesterName(uid, role);
    final departmentId = _resolveDepartmentId(uid, role);
    final approvalChain = <Map<String, dynamic>>[];
    String initialApprover = '';

    if (role == 'student') {
      final student = _students.firstWhere(
        (s) => s['studentId'] == uid,
        orElse: () => <String, dynamic>{},
      );
      if (student.isEmpty) return 'Student profile not found for $uid.';

      final mentorId = (student['mentorId'] as String? ?? '').trim();
      final hod = _findHodByDepartment(
          (student['departmentId'] as String? ?? '').trim());
      final hodId = (hod['facultyId'] as String? ?? '').trim();
      if (hodId.isEmpty)
        return 'No HOD is assigned for this student department.';

      if (mentorId.isNotEmpty) {
        final mentor = _faculty.firstWhere(
          (f) => f['facultyId'] == mentorId,
          orElse: () => <String, dynamic>{},
        );
        approvalChain.add({
          'role': 'mentor',
          'approverId': mentorId,
          'approverName': (mentor['name'] as String?) ?? mentorId,
          'status': 'pending',
          'date': '',
          'remarks': '',
        });
        initialApprover = 'mentor';
      }

      approvalChain.add({
        'role': 'hod',
        'approverId': hodId,
        'approverName': (hod['name'] as String?) ?? hodId,
        'status': mentorId.isEmpty ? 'pending' : 'waiting',
        'date': '',
        'remarks': '',
      });

      if (initialApprover.isEmpty) initialApprover = 'hod';
    } else if (role == 'faculty') {
      final fac = _faculty.firstWhere(
        (f) => f['facultyId'] == uid,
        orElse: () => <String, dynamic>{},
      );
      if (fac.isEmpty) return 'Faculty profile not found for $uid.';
      final hod =
          _findHodByDepartment((fac['departmentId'] as String? ?? '').trim());
      final hodId = (hod['facultyId'] as String? ?? '').trim();
      if (hodId.isEmpty)
        return 'No HOD is assigned for this faculty department.';

      approvalChain.add({
        'role': 'hod',
        'approverId': hodId,
        'approverName': (hod['name'] as String?) ?? hodId,
        'status': 'pending',
        'date': '',
        'remarks': '',
      });
      initialApprover = 'hod';
    } else if (role == 'hod') {
      final adminUser = _users.firstWhere(
        (u) {
          final r = (u['role'] as String? ?? '').toLowerCase();
          final id = (u['id'] as String? ?? '').toUpperCase();
          return r == 'admin' || id.startsWith('ADM');
        },
        orElse: () => <String, dynamic>{},
      );
      if (adminUser.isEmpty)
        return 'No admin user available to approve this request.';
      final adminId = (adminUser['id'] as String?) ?? 'ADMIN';
      final adminName = (adminUser['label'] as String?) ?? 'Admin';

      approvalChain.add({
        'role': 'admin',
        'approverId': adminId,
        'approverName': adminName,
        'status': 'pending',
        'date': '',
        'remarks': '',
      });
      initialApprover = 'admin';
    } else {
      return 'Forgot password workflow is supported only for student, faculty, and HOD users.';
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);
    _profileEditRequests.add({
      'requestId':
          'PER${(_profileEditRequests.length + 1).toString().padLeft(3, '0')}',
      'requestType': 'password_reset',
      'requesterId': uid,
      'requesterName': requesterName,
      'requesterRole': role,
      'departmentId': departmentId,
      'changes': {
        'password': {'old': '********', 'new': 'Reset to default password'}
      },
      'reason': reason.isEmpty ? 'Forgot password request' : reason,
      'status': 'pending_$initialApprover',
      'currentApprover': initialApprover,
      'approvalChain': approvalChain,
      'submittedDate': today,
      'lastUpdated': today,
    });

    final requestId =
        'PER${_profileEditRequests.length.toString().padLeft(3, '0')}';
    final firstApprover = approvalChain.first;
    final approverId = (firstApprover['approverId'] as String?) ?? '';
    final approverName =
        (firstApprover['approverName'] as String?) ?? approverId;

    _addWorkflowNotification(
      title: 'Password Reset Requested',
      message:
          '$requesterName ($uid) raised password reset request $requestId.',
      recipientId: uid,
      recipientRole: role,
      type: 'password_reset',
      metadata: {'requestId': requestId, 'event': 'submitted'},
    );
    if (approverId.isNotEmpty) {
      _addWorkflowNotification(
        title: 'Approval Required',
        message:
            'Password reset request $requestId from $requesterName is assigned to you.',
        recipientId: approverId,
        recipientRole: firstApprover['role'] as String? ?? 'faculty',
        type: 'password_reset',
        metadata: {'requestId': requestId, 'event': 'approval_assigned'},
      );
    }

    _sendEmailStub(
      toUserId: uid,
      event: 'password_reset_submitted',
      subject: 'Password reset request submitted',
      body:
          'Your password reset request ($requestId) was submitted and routed to $approverName.',
      payload: {'requestId': requestId, 'nextApprover': approverName},
    );
    _sendSmsStub(
      toUserId: uid,
      event: 'password_reset_submitted',
      message:
          'KSRCE ERP: Password reset request $requestId submitted. Next approver: $approverName.',
      payload: {'requestId': requestId},
    );
    if (approverId.isNotEmpty) {
      _sendEmailStub(
        toUserId: approverId,
        event: 'password_reset_approval_needed',
        subject: 'Password reset approval required',
        body:
            'Request $requestId from $requesterName ($uid) needs your approval.',
        payload: {'requestId': requestId, 'requesterId': uid},
      );
      _sendSmsStub(
        toUserId: approverId,
        event: 'password_reset_approval_needed',
        message:
            'KSRCE ERP: Approval needed for password reset request $requestId from $requesterName.',
        payload: {'requestId': requestId},
      );
    }

    notifyListeners();
    return null;
  }

  /// Approve a step in the chain and advance to next or finalize
  void approveEditRequest(String requestId, String approverId, String remarks) {
    final idx =
        _profileEditRequests.indexWhere((r) => r['requestId'] == requestId);
    if (idx == -1) return;
    final req = _profileEditRequests[idx];
    final chain = (req['approvalChain'] as List<dynamic>?) ?? [];
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Find current pending step and approve it
    for (int i = 0; i < chain.length; i++) {
      final step = chain[i] as Map<String, dynamic>;
      if (step['status'] == 'pending') {
        final configuredApprover = (step['approverId'] as String?) ?? '';
        final stepRole = (step['role'] as String?) ?? '';
        final allowAdminPlaceholder =
            stepRole == 'admin' && configuredApprover == 'ADMIN';
        if (configuredApprover.isNotEmpty &&
            configuredApprover != approverId &&
            !allowAdminPlaceholder) {
          continue;
        }

        step['status'] = 'approved';
        step['date'] = today;
        step['remarks'] = remarks;
        step['approverId'] = approverId;

        // Find approver name
        final approver = _faculty.firstWhere(
          (f) => f['facultyId'] == approverId,
          orElse: () => <String, dynamic>{},
        );
        step['approverName'] =
            approver['name'] ?? _displayNameForUser(approverId);

        // Check if there's a next step
        if (i + 1 < chain.length) {
          final nextStep = chain[i + 1] as Map<String, dynamic>;
          final nextRole = nextStep['role'] as String? ?? '';
          nextStep['status'] = 'pending';
          req['status'] = 'pending_$nextRole';
          req['currentApprover'] = nextRole;

          final requestIdValue = req['requestId'] as String? ?? '';
          final requesterId = req['requesterId'] as String? ?? '';
          final requesterName = req['requesterName'] as String? ?? requesterId;
          final nextApproverId = (nextStep['approverId'] as String?) ?? '';
          final nextApproverName = (nextStep['approverName'] as String?) ??
              _displayNameForUser(nextApproverId);

          _addWorkflowNotification(
            title: 'Request Forwarded',
            message:
                'Request $requestIdValue from $requesterName moved to $nextApproverName ($nextRole).',
            recipientId: requesterId,
            recipientRole: req['requesterRole'] as String? ?? 'all',
            type: 'workflow',
            metadata: {
              'requestId': requestIdValue,
              'event': 'forwarded',
              'toRole': nextRole
            },
          );
          if (nextApproverId.isNotEmpty) {
            _addWorkflowNotification(
              title: 'Approval Required',
              message:
                  'Request $requestIdValue from $requesterName is now assigned to you.',
              recipientId: nextApproverId,
              recipientRole: nextRole,
              type: 'workflow',
              metadata: {
                'requestId': requestIdValue,
                'event': 'approval_assigned'
              },
            );
          }

          _sendEmailStub(
            toUserId: requesterId,
            event: 'request_forwarded',
            subject: 'Your request moved to next approver',
            body:
                'Request $requestIdValue has been forwarded to $nextApproverName ($nextRole).',
            payload: {'requestId': requestIdValue, 'toRole': nextRole},
          );
          _sendSmsStub(
            toUserId: requesterId,
            event: 'request_forwarded',
            message:
                'KSRCE ERP: Request $requestIdValue forwarded to $nextApproverName ($nextRole).',
            payload: {'requestId': requestIdValue},
          );
          if (nextApproverId.isNotEmpty) {
            _sendEmailStub(
              toUserId: nextApproverId,
              event: 'request_approval_needed',
              subject: 'Approval required for request $requestIdValue',
              body:
                  'Request $requestIdValue from $requesterName needs your approval.',
              payload: {
                'requestId': requestIdValue,
                'requesterId': requesterId
              },
            );
            _sendSmsStub(
              toUserId: nextApproverId,
              event: 'request_approval_needed',
              message:
                  'KSRCE ERP: Approval required for request $requestIdValue from $requesterName.',
              payload: {'requestId': requestIdValue},
            );
          }

          // Auto-fill next approver for student requests
          if (nextRole == 'classAdviser' && req['requesterRole'] == 'student') {
            final studentId = req['requesterId'] as String;
            final student = _students.firstWhere(
              (s) => s['studentId'] == studentId,
              orElse: () => <String, dynamic>{},
            );
            final caId = student['classAdviserId'] as String? ?? '';
            final ca = _faculty.firstWhere(
              (f) => f['facultyId'] == caId,
              orElse: () => <String, dynamic>{},
            );
            nextStep['approverId'] = caId;
            nextStep['approverName'] = ca['name'] ?? caId;
          }
        } else {
          // Final approval — apply request effect
          _applyApprovedRequest(req);
          req['status'] = 'approved';

          final requestIdValue = req['requestId'] as String? ?? '';
          final requesterId = req['requesterId'] as String? ?? '';
          final requestType = req['requestType'] as String? ?? 'profile_edit';
          final isPwd = requestType == 'password_reset';
          final successMessage = isPwd
              ? 'Request $requestIdValue approved. Password has been reset to the default format.'
              : 'Request $requestIdValue approved and changes are applied.';

          _addWorkflowNotification(
            title: isPwd ? 'Password Reset Approved' : 'Request Approved',
            message: successMessage,
            recipientId: requesterId,
            recipientRole: req['requesterRole'] as String? ?? 'all',
            type: isPwd ? 'password_reset' : 'workflow',
            metadata: {'requestId': requestIdValue, 'event': 'approved'},
          );
          _sendEmailStub(
            toUserId: requesterId,
            event: isPwd ? 'password_reset_approved' : 'request_approved',
            subject: isPwd ? 'Password reset approved' : 'Request approved',
            body: successMessage,
            payload: {'requestId': requestIdValue},
          );
          _sendSmsStub(
            toUserId: requesterId,
            event: isPwd ? 'password_reset_approved' : 'request_approved',
            message: 'KSRCE ERP: $successMessage',
            payload: {'requestId': requestIdValue},
          );
        }
        break;
      }
    }
    req['lastUpdated'] = today;
    _profileEditRequests[idx] = req;
    notifyListeners();
  }

  /// Reject a request at any step
  void rejectEditRequest(String requestId, String approverId, String remarks) {
    final idx =
        _profileEditRequests.indexWhere((r) => r['requestId'] == requestId);
    if (idx == -1) return;
    final req = _profileEditRequests[idx];
    final chain = (req['approvalChain'] as List<dynamic>?) ?? [];
    final today = DateTime.now().toIso8601String().substring(0, 10);

    for (final step in chain) {
      final s = step as Map<String, dynamic>;
      if (s['status'] == 'pending') {
        s['status'] = 'rejected';
        s['date'] = today;
        s['remarks'] = remarks;
        s['approverId'] = approverId;
        final approver = _faculty.firstWhere(
          (f) => f['facultyId'] == approverId,
          orElse: () => <String, dynamic>{},
        );
        s['approverName'] = approver['name'] ?? _displayNameForUser(approverId);
        break;
      }
    }
    req['status'] = 'rejected';
    req['lastUpdated'] = today;
    _profileEditRequests[idx] = req;

    final requestIdValue = req['requestId'] as String? ?? '';
    final requesterId = req['requesterId'] as String? ?? '';
    final requestType = req['requestType'] as String? ?? 'profile_edit';
    final isPwd = requestType == 'password_reset';
    final rejectionMessage = isPwd
        ? 'Password reset request $requestIdValue was rejected. Please contact your approver.'
        : 'Request $requestIdValue was rejected. Please review remarks and resubmit.';

    _addWorkflowNotification(
      title: isPwd ? 'Password Reset Rejected' : 'Request Rejected',
      message: rejectionMessage,
      recipientId: requesterId,
      recipientRole: req['requesterRole'] as String? ?? 'all',
      type: isPwd ? 'password_reset' : 'workflow',
      metadata: {'requestId': requestIdValue, 'event': 'rejected'},
    );
    _sendEmailStub(
      toUserId: requesterId,
      event: isPwd ? 'password_reset_rejected' : 'request_rejected',
      subject: isPwd ? 'Password reset rejected' : 'Request rejected',
      body: rejectionMessage,
      payload: {'requestId': requestIdValue},
    );
    _sendSmsStub(
      toUserId: requesterId,
      event: isPwd ? 'password_reset_rejected' : 'request_rejected',
      message: 'KSRCE ERP: $rejectionMessage',
      payload: {'requestId': requestIdValue},
    );

    notifyListeners();
  }

  /// Apply approved request effect.
  void _applyApprovedRequest(Map<String, dynamic> req) {
    final requestType =
        (req['requestType'] as String? ?? 'profile_edit').toLowerCase();
    if (requestType == 'password_reset') {
      _applyPasswordReset(req['requesterId'] as String? ?? '');
      return;
    }
    _applyProfileChanges(req);
  }

  /// Apply approved profile changes to the actual student/faculty record.
  void _applyProfileChanges(Map<String, dynamic> req) {
    final changes = (req['changes'] as Map<String, dynamic>?) ?? {};
    if (req['requesterRole'] == 'student') {
      final idx =
          _students.indexWhere((s) => s['studentId'] == req['requesterId']);
      if (idx != -1) {
        for (final entry in changes.entries) {
          final newVal = (entry.value as Map<String, dynamic>)['new'];
          _students[idx][entry.key] = newVal;
        }
        // Update currentStudent if it's the same user
        if (_currentUserId == req['requesterId']) {
          _currentStudent = _students[idx];
        }
      }
    } else if (req['requesterRole'] == 'faculty') {
      final idx =
          _faculty.indexWhere((f) => f['facultyId'] == req['requesterId']);
      if (idx != -1) {
        for (final entry in changes.entries) {
          final newVal = (entry.value as Map<String, dynamic>)['new'];
          _faculty[idx][entry.key] = newVal;
        }
        if (_currentUserId == req['requesterId']) {
          _currentFaculty = _faculty[idx];
        }
      }
    }
  }

  void _applyPasswordReset(String userId) {
    final uid = userId.trim().toUpperCase();
    if (uid.isEmpty) return;
    final idx = _users
        .indexWhere((u) => (u['id'] as String? ?? '').toUpperCase() == uid);
    if (idx == -1) return;
    final defaultPassword = 'ksrce@${uid.toLowerCase()}';
    _users[idx]['password'] =
        SecurityService.hashPassword(defaultPassword, uid);
  }

  String _resolveRequesterName(String userId, String role) {
    if (role == 'student') {
      final s = _students.firstWhere(
        (x) => x['studentId'] == userId,
        orElse: () => <String, dynamic>{},
      );
      if (s.isNotEmpty) return (s['name'] as String?) ?? userId;
    }
    if (role == 'faculty' || role == 'hod') {
      final f = _faculty.firstWhere(
        (x) => x['facultyId'] == userId,
        orElse: () => <String, dynamic>{},
      );
      if (f.isNotEmpty) return (f['name'] as String?) ?? userId;
    }
    final u = _users.firstWhere(
      (x) => x['id'] == userId,
      orElse: () => <String, dynamic>{},
    );
    return (u['label'] as String?) ?? userId;
  }

  String _resolveDepartmentId(String userId, String role) {
    if (role == 'student') {
      final s = _students.firstWhere(
        (x) => x['studentId'] == userId,
        orElse: () => <String, dynamic>{},
      );
      return (s['departmentId'] as String?) ?? '';
    }
    if (role == 'faculty' || role == 'hod') {
      final f = _faculty.firstWhere(
        (x) => x['facultyId'] == userId,
        orElse: () => <String, dynamic>{},
      );
      return (f['departmentId'] as String?) ?? '';
    }
    return '';
  }

  Map<String, dynamic> _findHodByDepartment(String departmentId) {
    if (departmentId.isEmpty) return <String, dynamic>{};
    return _faculty.firstWhere(
      (f) => f['departmentId'] == departmentId && f['isHOD'] == true,
      orElse: () => <String, dynamic>{},
    );
  }

  /// Get the mentor and class adviser for a student
  Map<String, String> getStudentApprovalChain(String studentId) {
    final student = _students.firstWhere(
      (s) => s['studentId'] == studentId,
      orElse: () => <String, dynamic>{},
    );
    final mentorId = student['mentorId'] as String? ?? '';
    final mentor = _faculty.firstWhere(
      (f) => f['facultyId'] == mentorId,
      orElse: () => <String, dynamic>{},
    );
    final caId = student['classAdviserId'] as String? ?? '';
    final ca = _faculty.firstWhere(
      (f) => f['facultyId'] == caId,
      orElse: () => <String, dynamic>{},
    );
    return {
      'mentorId': mentorId,
      'mentorName': (mentor['name'] as String?) ?? mentorId,
      'classAdviserId': caId,
      'classAdviserName': (ca['name'] as String?) ?? caId,
    };
  }

  /// Get the HOD for a faculty's department
  Map<String, String> getFacultyApprovalChain(String facultyId) {
    final fac = _faculty.firstWhere(
      (f) => f['facultyId'] == facultyId,
      orElse: () => <String, dynamic>{},
    );
    final deptId = fac['departmentId'] as String? ?? '';
    final hod = _faculty.firstWhere(
      (f) => f['departmentId'] == deptId && f['isHOD'] == true,
      orElse: () => <String, dynamic>{},
    );
    return {
      'hodId': (hod['facultyId'] as String?) ?? '',
      'hodName': (hod['name'] as String?) ?? '',
    };
  }

  // ─── USER CRUD OPERATIONS ────────────────────────────
  bool deleteUserById(String userId) {
    final user = _users.firstWhere(
      (u) => u['id'] == userId,
      orElse: () => <String, dynamic>{},
    );
    if (user.isEmpty) return false;

    final role = (user['role'] as String? ?? '').toLowerCase();
    if (role == 'student' || userId.startsWith('STU')) {
      deleteStudent(userId);
      return true;
    }
    if (role == 'faculty' || role == 'hod' || userId.startsWith('FAC')) {
      deleteFaculty(userId);
      return true;
    }

    // Admin or unknown role: remove auth user record only.
    _users.removeWhere((u) => u['id'] == userId);
    if (_currentUserId == userId) logout();
    notifyListeners();
    return true;
  }

  void deleteStudent(String studentId) {
    _students.removeWhere((s) => s['studentId'] == studentId);
    _users.removeWhere((u) => u['id'] == studentId);
    // Remove from class lists
    for (final c in _classes) {
      final ids = (c['studentIds'] as List<dynamic>?) ?? [];
      ids.remove(studentId);
    }
    // Remove from mentor assignments
    for (final m in _mentorAssignments) {
      final ids = (m['menteeIds'] as List<dynamic>?) ?? [];
      ids.remove(studentId);
    }
    // Remove from faculty menteeIds
    for (final f in _faculty) {
      final ids = (f['menteeIds'] as List<dynamic>?) ?? [];
      ids.remove(studentId);
    }
    if (_currentUserId == studentId) logout();
    notifyListeners();
    _refreshRoleMasterMap();
  }

  void deleteFaculty(String facultyId) {
    final fac = _faculty.firstWhere((f) => f['facultyId'] == facultyId,
        orElse: () => <String, dynamic>{});
    _faculty.removeWhere((f) => f['facultyId'] == facultyId);
    _users.removeWhere((u) => u['id'] == facultyId);
    // Remove HOD assignment
    if (fac['isHOD'] == true) {
      final deptIdx = _departments.indexWhere((d) => d['hodId'] == facultyId);
      if (deptIdx != -1) _departments[deptIdx]['hodId'] = null;
    }
    // Remove class adviser assignment
    for (final c in _classes) {
      if (c['classAdviserId'] == facultyId) c['classAdviserId'] = null;
    }
    // Remove mentor assignments
    _mentorAssignments.removeWhere((m) => m['mentorId'] == facultyId);
    // Clear students' references
    for (final s in _students) {
      if (s['mentorId'] == facultyId) s['mentorId'] = null;
      if (s['classAdviserId'] == facultyId) s['classAdviserId'] = null;
    }
    if (_currentUserId == facultyId) logout();
    notifyListeners();
    _refreshRoleMasterMap();
  }

  void updateStudent(String studentId, Map<String, dynamic> updates) {
    final idx = _students.indexWhere((s) => s['studentId'] == studentId);
    if (idx != -1) {
      _students[idx].addAll(updates);
      if (_currentUserId == studentId) _currentStudent = _students[idx];
      notifyListeners();
      _refreshRoleMasterMap();
    }
  }

  void updateFaculty(String facultyId, Map<String, dynamic> updates) {
    final idx = _faculty.indexWhere((f) => f['facultyId'] == facultyId);
    if (idx != -1) {
      _faculty[idx].addAll(updates);
      if (_currentUserId == facultyId) _currentFaculty = _faculty[idx];
      notifyListeners();
      _refreshRoleMasterMap();
    }
  }

  // ─── UPLOADED FILES STORAGE ───────────────────────────
  final List<Map<String, dynamic>> _uploadedFiles = [];
  List<Map<String, dynamic>> get uploadedFiles => _uploadedFiles;

  void addUploadedFile(Map<String, dynamic> fileData) {
    fileData['fileId'] =
        'FILE${(_uploadedFiles.length + 1).toString().padLeft(4, '0')}';
    fileData['uploadedAt'] = DateTime.now().toIso8601String();
    _uploadedFiles.add(fileData);
    notifyListeners();
  }

  List<Map<String, dynamic>> getUploadedFiles(
      {String? userId, String? category}) {
    return _uploadedFiles.where((f) {
      if (userId != null && f['uploadedBy'] != userId) return false;
      if (category != null && f['category'] != category) return false;
      return true;
    }).toList()
      ..sort(
          (a, b) => (b['uploadedAt'] ?? '').compareTo(a['uploadedAt'] ?? ''));
  }

  void deleteUploadedFile(String fileId) {
    _uploadedFiles.removeWhere((f) => f['fileId'] == fileId);
    notifyListeners();
  }

  // ─── FACULTY COMPLAINTS QUERIES ───────────────────────
  List<Map<String, dynamic>> getFacultyComplaints(String facultyId) {
    // Show complaints from students in faculty's courses or mentees
    final mentees = getMentees(facultyId);
    final menteeIds = mentees.map((m) => m['studentId'] as String).toSet();
    final courseStudentIds = <String>{};
    final facCourses = getFacultyCourses(facultyId);
    for (final c in facCourses) {
      final students = getCourseStudents(c['courseId'] as String);
      courseStudentIds.addAll(students.map((s) => s['studentId'] as String));
    }
    final allIds = menteeIds.union(courseStudentIds);
    return _complaints.where((c) => allIds.contains(c['studentId'])).toList();
  }

  // ─── STUDENT-FILTERED QUERIES ─────────────────────────
  /// Get attendance records for a specific student (by enrolled courses)
  List<Map<String, dynamic>> getStudentAttendanceFiltered(String studentId, {String? masterKey}) {
    final student = getStudentById(studentId);
    if (student == null) return _attendance;
    final enrolled =
        (student['enrolledCourses'] as List<dynamic>?)?.cast<String>() ?? [];
    if (enrolled.isEmpty) {
      final deptId = student['departmentId'] ?? '';
      final attendance = _attendance
          .where((a) =>
              a['departmentId'] == deptId || enrolled.contains(a['courseId']))
          .toList();
      if (masterKey == null) return attendance;
      final node = getMasterKeyNode(masterKey);
      if (node == null) return attendance;
      final selectedDept = node['departmentId']?.toString() ?? '';
      return attendance.where((a) => selectedDept.isEmpty || a['departmentId']?.toString() == selectedDept).toList();
    }
    final attendance = _attendance.where((a) => enrolled.contains(a['courseId'])).toList();
    if (masterKey == null) return attendance;
    final node = getMasterKeyNode(masterKey);
    if (node == null) return attendance;
    final selectedDept = node['departmentId']?.toString() ?? '';
    return attendance.where((a) => selectedDept.isEmpty || a['departmentId']?.toString() == selectedDept).toList();
  }

  /// Get assignments for a specific student (by enrolled courses)
  List<Map<String, dynamic>> getStudentAssignmentsFiltered(String studentId) {
    final student = getStudentById(studentId);
    if (student == null) return _assignments;
    final enrolled =
        (student['enrolledCourses'] as List<dynamic>?)?.cast<String>() ?? [];
    if (enrolled.isEmpty) return _assignments;
    return _assignments.where((a) => enrolled.contains(a['courseId'])).toList();
  }

  /// Get results for a specific student
  List<Map<String, dynamic>> getStudentResultsFiltered(String studentId, {String? masterKey}) {
    // Students should only see published results. Faculty/admin/hod can see drafts.
    final isStaff = _currentRole == 'faculty' || _currentRole == 'admin' || _currentRole == 'hod';
    final filtered = _results.where((r) {
      if (r['studentId'] != studentId) return false;
      if (isStaff) return true;
      return r['published'] == true;
    }).toList();
    if (masterKey != null) {
      final node = getMasterKeyNode(masterKey);
      if (node != null) {
        final selectedStudentIds = getStudentsForMasterKey(masterKey)
            .map((s) => s['studentId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        if (selectedStudentIds.isNotEmpty) {
          final scoped = filtered.where((r) => selectedStudentIds.contains(r['studentId']?.toString() ?? '')).toList();
          if (scoped.isNotEmpty) return scoped;
        }
      }
    }
    if (filtered.isEmpty) {
      // Fallback: staff should see all, students see empty
      return isStaff ? _results.where((r) => r['studentId'] == studentId).toList() : <Map<String, dynamic>>[];
    }
    return filtered;
  }

  /// Get timetable for a specific student's class/section
  List<Map<String, dynamic>> getStudentTimetableForDay(
      String studentId, String day) {
    final student = getStudentById(studentId);
    if (student == null) return getTimetableForDay(day);
    final deptId = student['departmentId'] ?? '';
    final year = student['year'];
    final section = student['section'];
    final filtered = _timetable
        .where((t) =>
            t['day'] == day &&
            (t['departmentId'] == deptId ||
                true) && // Fallback if no dept match
            (year == null || t['year'] == year || t['year'] == null) &&
            (section == null ||
                t['section'] == section ||
                t['section'] == null))
        .toList();
    return filtered.isNotEmpty ? filtered : getTimetableForDay(day);
  }

  /// Get notifications for a specific student (by recipient or global)
  List<Map<String, dynamic>> getStudentNotifications(String studentId) {
    return _notifications
        .where((n) =>
            n['recipientId'] == studentId ||
            n['recipientId'] == null ||
            n['recipientId'] == 'all' ||
            n['recipientRole'] == 'student' ||
            n['recipientRole'] == null)
        .toList();
  }

  // ─── ASSIGNMENT CRUD ──────────────────────────────────
  void addAssignment(Map<String, dynamic> assignment) {
    assignment['assignmentId'] =
        'ASG${(_assignments.length + 1).toString().padLeft(3, '0')}';
    assignment['createdDate'] =
        DateTime.now().toIso8601String().substring(0, 10);
    if (assignment['status'] == null) assignment['status'] = 'pending';
    _assignments.add(Map<String, dynamic>.from(assignment));
    notifyListeners();
  }

  void updateAssignment(String assignmentId, Map<String, dynamic> updates) {
    final idx =
        _assignments.indexWhere((a) => a['assignmentId'] == assignmentId);
    if (idx != -1) {
      _assignments[idx].addAll(updates);
      notifyListeners();
    }
  }

  void deleteAssignment(String assignmentId) {
    _assignments.removeWhere((a) => a['assignmentId'] == assignmentId);
    notifyListeners();
  }

  void submitAssignment(
      String assignmentId, String studentId, String? fileUrl) {
    final idx =
        _assignments.indexWhere((a) => a['assignmentId'] == assignmentId);
    if (idx != -1) {
      _assignments[idx]['status'] = 'submitted';
      _assignments[idx]['submittedDate'] =
          DateTime.now().toIso8601String().substring(0, 10);
      _assignments[idx]['submittedBy'] = studentId;
      if (fileUrl != null) _assignments[idx]['fileUrl'] = fileUrl;
      notifyListeners();
    }
  }

  // ─── EXAM CRUD ────────────────────────────────────────
  void addExam(Map<String, dynamic> exam) {
    exam['examId'] = 'EXM${(_exams.length + 1).toString().padLeft(3, '0')}';
    _exams.add(Map<String, dynamic>.from(exam));
    notifyListeners();
  }

  void updateExam(String examId, Map<String, dynamic> updates) {
    final idx = _exams.indexWhere((e) => e['examId'] == examId);
    if (idx != -1) {
      _exams[idx].addAll(updates);
      notifyListeners();
    }
  }

  void deleteExam(String examId) {
    _exams.removeWhere((e) => e['examId'] == examId);
    notifyListeners();
  }

  Map<String, dynamic>? getQuestionPaperPattern(String courseId, String examType) {
    try {
      return _exams.firstWhere(
        (e) => e['courseId'] == courseId && (e['examType'] ?? e['type'] ?? '') == examType,
      )['questionPaperPattern'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  void saveQuestionPaperPattern(
      String courseId, String examType, Map<String, dynamic> pattern) {
    final idx = _exams.indexWhere(
      (e) => e['courseId'] == courseId && (e['examType'] ?? e['type'] ?? '') == examType,
    );
    final payload = {
      'courseId': courseId,
      'examType': examType,
      'type': pattern['type'] ?? 'internal',
      'questionPaperPattern': pattern,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (idx >= 0) {
      _exams[idx].addAll(payload);
    } else {
      payload['examId'] = 'EXM${(_exams.length + 1).toString().padLeft(3, '0')}';
      _exams.add(payload);
    }
    notifyListeners();
  }

  /// Returns true if any exam has a saved question paper pattern.
  bool anyQuestionPaperPatternSaved() {
    try {
      return _exams.any((e) => e['questionPaperPattern'] != null);
    } catch (_) {
      return false;
    }
  }

  /// Returns true if course outcomes are available in seeded data.
  bool hasCourseOutcomes() {
    return _courseOutcomes.isNotEmpty;
  }

  // ─── CENTRAL QUESTION BANK CRUD ───────────────────────
  void addQuestion(Map<String, dynamic> q) {
    if (q['questionId'] == null || q['questionId'].toString().isEmpty) {
      q['questionId'] = 'QST${(_questions.length + 1).toString().padLeft(3, '0')}';
    }
    _questions.add(Map<String, dynamic>.from(q));
    notifyListeners();
  }

  void deleteQuestion(String id) {
    _questions.removeWhere((q) => q['questionId'] == id);
    notifyListeners();
  }

  void _seedInitialQuestions() {
    if (_questions.isNotEmpty) return;
    
    final List<Map<String, dynamic>> defaultQuestions = [
      // CS6411 - Design and Analysis of Algorithms (CSE, IT)
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'I',
        'maxMarks': 2,
        'cognitiveLevel': 'K1: Remember',
        'courseOutcome': 'CO1',
        'questionText': 'Define asymptotic notations: Big-Oh, Big-Omega, and Big-Theta.'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'I',
        'maxMarks': 2,
        'cognitiveLevel': 'K2: Understand',
        'courseOutcome': 'CO1',
        'questionText': 'Distinguish between time complexity and space complexity of an algorithm.'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'I',
        'maxMarks': 13,
        'cognitiveLevel': 'K3: Apply',
        'courseOutcome': 'CO1',
        'questionText': 'Solve the following recurrence relation using Master\'s Theorem:\n1) T(n) = 4T(n/2) + n\n2) T(n) = 2T(n/2) + n log n.'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'II',
        'maxMarks': 2,
        'cognitiveLevel': 'K1: Remember',
        'courseOutcome': 'CO2',
        'questionText': 'State the general principle of Divide and Conquer algorithmic paradigm.'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'II',
        'maxMarks': 2,
        'cognitiveLevel': 'K2: Understand',
        'courseOutcome': 'CO2',
        'questionText': 'Explain why Quick Sort has a worst-case time complexity of O(n^2).'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'II',
        'maxMarks': 13,
        'cognitiveLevel': 'K3: Apply',
        'courseOutcome': 'CO2',
        'questionText': 'Demonstrate the Merge Sort algorithm on the array [38, 27, 43, 3, 9, 82, 10]. Show the split and merge steps clearly.'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'III',
        'maxMarks': 2,
        'cognitiveLevel': 'K2: Understand',
        'courseOutcome': 'CO3',
        'questionText': 'Define dynamic programming and explain the principle of optimality.'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'III',
        'maxMarks': 13,
        'cognitiveLevel': 'K4: Analyze',
        'courseOutcome': 'CO3',
        'questionText': 'Construct the optimal binary search tree for the keys (A, B, C, D) with probabilities p = (0.1, 0.2, 0.4, 0.3) respectively.'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'IV',
        'maxMarks': 2,
        'cognitiveLevel': 'K1: Remember',
        'courseOutcome': 'CO4',
        'questionText': 'Define the concept of backtracking and name two classic problems solved by it.'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'IV',
        'maxMarks': 13,
        'cognitiveLevel': 'K3: Apply',
        'courseOutcome': 'CO4',
        'questionText': 'Apply backtracking to solve the 4-Queens problem. Illustrate the state space tree for the search.'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'V',
        'maxMarks': 2,
        'cognitiveLevel': 'K2: Understand',
        'courseOutcome': 'CO5',
        'questionText': 'Define NP-Complete and NP-Hard classes with suitable Venn diagrams.'
      },
      {
        'courseCode': 'CS6411',
        'courseName': 'Design and Analysis of Algorithms',
        'unit': 'V',
        'maxMarks': 15,
        'cognitiveLevel': 'K6: Create',
        'courseOutcome': 'CO6',
        'questionText': 'Formulate a branch and bound algorithm to solve the Traveling Salesperson Problem (TSP). Prove its optimal bounding logic with an example.'
      },
      
      // CS6301 - Database Management Systems (CSE, IT)
      {
        'courseCode': 'CS6301',
        'courseName': 'Database Management Systems',
        'unit': 'I',
        'maxMarks': 2,
        'cognitiveLevel': 'K1: Remember',
        'courseOutcome': 'CO1',
        'questionText': 'State the advantages of DBMS over standard file-processing systems.'
      },
      {
        'courseCode': 'CS6301',
        'courseName': 'Database Management Systems',
        'unit': 'I',
        'maxMarks': 13,
        'cognitiveLevel': 'K6: Create',
        'courseOutcome': 'CO1',
        'questionText': 'Design an Entity-Relationship (ER) diagram for a University Management System including Entities: Student, Course, Department, Instructor, and Exam.'
      },
      {
        'courseCode': 'CS6301',
        'courseName': 'Database Management Systems',
        'unit': 'II',
        'maxMarks': 2,
        'cognitiveLevel': 'K2: Understand',
        'courseOutcome': 'CO2',
        'questionText': 'Explain the difference between SELECT and PROJECT operators in relational algebra.'
      },
      {
        'courseCode': 'CS6301',
        'courseName': 'Database Management Systems',
        'unit': 'II',
        'maxMarks': 13,
        'cognitiveLevel': 'K3: Apply',
        'courseOutcome': 'CO2',
        'questionText': 'Write SQL queries for a Library Database schema: \n1) Retrieve all books written by "Arthur Conan Doyle".\n2) Count the total books issued in CSE department.'
      },
      {
        'courseCode': 'CS6301',
        'courseName': 'Database Management Systems',
        'unit': 'III',
        'maxMarks': 2,
        'cognitiveLevel': 'K1: Remember',
        'courseOutcome': 'CO3',
        'questionText': 'State the definition of Third Normal Form (3NF) and Boyce-Codd Normal Form (BCNF).'
      },
      {
        'courseCode': 'CS6301',
        'courseName': 'Database Management Systems',
        'unit': 'III',
        'maxMarks': 13,
        'cognitiveLevel': 'K4: Analyze',
        'courseOutcome': 'CO3',
        'questionText': 'Normalize the relation R(A, B, C, D, E) with functional dependencies F = {A -> B, C -> D, A,C -> E} to 3NF. State the primary keys for intermediate tables.'
      },
      {
        'courseCode': 'CS6301',
        'courseName': 'Database Management Systems',
        'unit': 'IV',
        'maxMarks': 2,
        'cognitiveLevel': 'K2: Understand',
        'courseOutcome': 'CO4',
        'questionText': 'Explain ACID properties of a database transaction with examples.'
      },
      {
        'courseCode': 'CS6301',
        'courseName': 'Database Management Systems',
        'unit': 'IV',
        'maxMarks': 13,
        'cognitiveLevel': 'K3: Apply',
        'courseOutcome': 'CO4',
        'questionText': 'Demonstrate the execution of Two-Phase Locking (2PL) protocol. Discuss how it prevents concurrency anomalies.'
      },
      {
        'courseCode': 'CS6301',
        'courseName': 'Database Management Systems',
        'unit': 'V',
        'maxMarks': 2,
        'cognitiveLevel': 'K1: Remember',
        'courseOutcome': 'CO5',
        'questionText': 'Explain indexing. Contrast sparse indexing with dense indexing.'
      },
      {
        'courseCode': 'CS6301',
        'courseName': 'Database Management Systems',
        'unit': 'V',
        'maxMarks': 15,
        'cognitiveLevel': 'K5: Evaluate',
        'courseOutcome': 'CO6',
        'questionText': 'Evaluate the performance of B+ Tree indexing against Hash indexing in databases with very large transactional load.'
      },

      // CS6551 - Computer Networks (CSE, IT)
      {
        'courseCode': 'CS6551',
        'courseName': 'Computer Networks',
        'unit': 'I',
        'maxMarks': 2,
        'cognitiveLevel': 'K1: Remember',
        'courseOutcome': 'CO1',
        'questionText': 'Name the seven layers of the ISO/OSI model in sequential order.'
      },
      {
        'courseCode': 'CS6551',
        'courseName': 'Computer Networks',
        'unit': 'I',
        'maxMarks': 13,
        'cognitiveLevel': 'K2: Understand',
        'courseOutcome': 'CO1',
        'questionText': 'Compare and contrast the architectures of OSI reference model and TCP/IP protocol suite.'
      },
      {
        'courseCode': 'CS6551',
        'courseName': 'Computer Networks',
        'unit': 'II',
        'maxMarks': 2,
        'cognitiveLevel': 'K1: Remember',
        'courseOutcome': 'CO2',
        'questionText': 'Define Hamming distance and explain its role in error-detection techniques.'
      },
      {
        'courseCode': 'CS6551',
        'courseName': 'Computer Networks',
        'unit': 'II',
        'maxMarks': 13,
        'cognitiveLevel': 'K3: Apply',
        'courseOutcome': 'CO2',
        'questionText': 'Compute the CRC code for a message bit pattern M = [10110011] using the generator polynomial G(x) = x^4 + x + 1.'
      },
      {
        'courseCode': 'CS6551',
        'courseName': 'Computer Networks',
        'unit': 'III',
        'maxMarks': 2,
        'cognitiveLevel': 'K2: Understand',
        'courseOutcome': 'CO3',
        'questionText': 'Explain the difference between classful addressing and classless CIDR addressing.'
      },
      {
        'courseCode': 'CS6551',
        'courseName': 'Computer Networks',
        'unit': 'III',
        'maxMarks': 13,
        'cognitiveLevel': 'K4: Analyze',
        'courseOutcome': 'CO3',
        'questionText': 'Illustrate the working of Link State Routing (LSR) using Dijkstra\'s Algorithm on a 6-node network graph. Trace the routing table of the source node.'
      },
      {
        'courseCode': 'CS6551',
        'courseName': 'Computer Networks',
        'unit': 'IV',
        'maxMarks': 2,
        'cognitiveLevel': 'K1: Remember',
        'courseOutcome': 'CO4',
        'questionText': 'Explain the roles of ports, sockets, and multiplexing at the Transport layer.'
      },
      {
        'courseCode': 'CS6551',
        'courseName': 'Computer Networks',
        'unit': 'IV',
        'maxMarks': 13,
        'cognitiveLevel': 'K3: Apply',
        'courseOutcome': 'CO4',
        'questionText': 'Trace the TCP 3-way handshake process for establishing a connection. Highlight sequence and acknowledgment numbers.'
      },
      {
        'courseCode': 'CS6551',
        'courseName': 'Computer Networks',
        'unit': 'V',
        'maxMarks': 2,
        'cognitiveLevel': 'K2: Understand',
        'courseOutcome': 'CO5',
        'questionText': 'Explain the function of Domain Name System (DNS) in mapping hostnames to IP addresses.'
      },
      {
        'courseCode': 'CS6551',
        'courseName': 'Computer Networks',
        'unit': 'V',
        'maxMarks': 15,
        'cognitiveLevel': 'K5: Evaluate',
        'courseOutcome': 'CO6',
        'questionText': 'Critically evaluate the security vulnerabilities of HTTP, FTP, and SMTP, and explain how HTTPS and SMTPS mitigate these threats.'
      }
    ];

    for (int i = 0; i < defaultQuestions.length; i++) {
      defaultQuestions[i]['questionId'] = 'QST${(i + 1).toString().padLeft(3, '0')}';
      _questions.add(defaultQuestions[i]);
    }
  }

  // ─── NOTIFICATION CRUD ────────────────────────────────
  void addNotification(Map<String, dynamic> notification) {
    notification['notificationId'] =
        'NTF${(_notifications.length + 1).toString().padLeft(3, '0')}';
    notification['timestamp'] = DateTime.now().toIso8601String();
    notification['isRead'] = false;
    _notifications.insert(0, Map<String, dynamic>.from(notification));
    notifyListeners();
  }

  void deleteNotification(String notifId) {
    _notifications.removeWhere((n) => n['notificationId'] == notifId);
    notifyListeners();
  }

  // ─── EVENT CRUD ───────────────────────────────────────
  void addEvent(Map<String, dynamic> event) {
    event['eventId'] = 'EVT${(_events.length + 1).toString().padLeft(3, '0')}';
    if (event['status'] == null) event['status'] = 'upcoming';
    event['registeredCount'] = 0;
    _events.add(Map<String, dynamic>.from(event));
    notifyListeners();
  }

  void updateEvent(String eventId, Map<String, dynamic> updates) {
    final idx = _events.indexWhere((e) => e['eventId'] == eventId);
    if (idx != -1) {
      _events[idx].addAll(updates);
      notifyListeners();
    }
  }

  void deleteEvent(String eventId) {
    _events.removeWhere((e) => e['eventId'] == eventId);
    _eventRegistrations.removeWhere((r) => r['eventId'] == eventId);
    notifyListeners();
  }

  // ─── FEE CRUD ─────────────────────────────────────────
  void addFee(Map<String, dynamic> fee) {
    fee['feeId'] = 'FEE${(_fees.length + 1).toString().padLeft(3, '0')}';
    _fees.add(Map<String, dynamic>.from(fee));
    notifyListeners();
  }

  void updateFee(String feeId, Map<String, dynamic> updates) {
    final idx = _fees.indexWhere((f) => f['feeId'] == feeId);
    if (idx != -1) {
      _fees[idx].addAll(updates);
      notifyListeners();
    }
  }

  void recordFeePayment(String feeId, double amount) {
    final idx = _fees.indexWhere((f) => f['feeId'] == feeId);
    if (idx != -1) {
      final current = ((_fees[idx]['paid'] as num?)?.toDouble() ?? 0);
      _fees[idx]['paid'] = current + amount;
      final total = ((_fees[idx]['amount'] as num?)?.toDouble() ?? 0);
      _fees[idx]['pending'] = total - (current + amount);
      if (_fees[idx]['pending'] <= 0) {
        _fees[idx]['status'] = 'paid';
        _fees[idx]['pending'] = 0;
      }
      _fees[idx]['lastPaymentDate'] =
          DateTime.now().toIso8601String().substring(0, 10);
      notifyListeners();
    }
  }

  // ─── TIMETABLE CRUD ──────────────────────────────────
  void addTimetableEntry(Map<String, dynamic> entry) {
    _timetable.add(Map<String, dynamic>.from(entry));
    notifyListeners();
  }

  void updateTimetableEntry(int index, Map<String, dynamic> updates) {
    if (index >= 0 && index < _timetable.length) {
      _timetable[index].addAll(updates);
      notifyListeners();
    }
  }

  void deleteTimetableEntry(int index) {
    if (index >= 0 && index < _timetable.length) {
      _timetable.removeAt(index);
      notifyListeners();
    }
  }

  // ─── RESULT CRUD ──────────────────────────────────────
  void addResult(Map<String, dynamic> result) {
    // Normalize result payload and set defaults
    result = Map<String, dynamic>.from(result);
    result['resultId'] = result['resultId'] ?? 'RES${(_results.length + 1).toString().padLeft(3, '0')}';
    // support both 'marks'/'totalMarks' and 'obtainedMarks'/'maxMarks'
    final obtained = result.containsKey('marks') ? result['marks'] : result['obtainedMarks'];
    final max = result.containsKey('totalMarks') ? result['totalMarks'] : result['maxMarks'] ?? 100;
    result['obtainedMarks'] = obtained;
    result['maxMarks'] = max;
    // Attach course meta
    final courseId = result['courseId'] as String?;
    if (courseId != null) {
      final course = _courses.firstWhere((c) => c['courseId'] == courseId, orElse: () => {});
      result['courseCode'] = course['courseId'] ?? courseId;
      result['courseName'] = course['courseName'] ?? '';
    }
    // default flags
    result['published'] = result['published'] ?? false;
    result['gradedDate'] = result['gradedDate'] ?? DateTime.now().toIso8601String().substring(0, 10);
    // compute simple pass/fail if possible
    try {
      final om = (result['obtainedMarks'] is num) ? (result['obtainedMarks'] as num).toDouble() : double.parse(result['obtainedMarks'].toString());
      final mm = (result['maxMarks'] is num) ? (result['maxMarks'] as num).toDouble() : double.parse(result['maxMarks'].toString());
      result['status'] = (om >= 0.4 * mm) ? 'Pass' : 'Fail';
    } catch (_) {
      result['status'] = result['status'] ?? '';
    }
    _results.add(result);
    notifyListeners();
  }

  void updateResult(String resultId, Map<String, dynamic> updates) {
    final idx = _results.indexWhere((r) => r['resultId'] == resultId);
    if (idx != -1) {
      // normalize updates as in addResult
      if (updates.containsKey('marks')) updates['obtainedMarks'] = updates['marks'];
      if (updates.containsKey('totalMarks')) updates['maxMarks'] = updates['totalMarks'];
      _results[idx].addAll(updates);
      // recompute status
      try {
        final om = (_results[idx]['obtainedMarks'] is num) ? (_results[idx]['obtainedMarks'] as num).toDouble() : double.parse(_results[idx]['obtainedMarks'].toString());
        final mm = (_results[idx]['maxMarks'] is num) ? (_results[idx]['maxMarks'] as num).toDouble() : double.parse(_results[idx]['maxMarks'].toString());
        _results[idx]['status'] = (om >= 0.4 * mm) ? 'Pass' : 'Fail';
      } catch (_) {}
      notifyListeners();
    }
  }

  /// Publish results for a given course and exam type. This sets `published=true`
  /// on matching result rows and notifies affected students.
  void publishResults(String courseId, String examType, {String? publishedBy}) {
    final affected = _results.where((r) => r['courseId'] == courseId && (r['examType'] ?? '') == examType).toList();
    for (final r in affected) {
      r['published'] = true;
      r['publishedBy'] = publishedBy ?? _currentUserId;
      r['publishedDate'] = DateTime.now().toIso8601String().substring(0, 10);
    }
    // Create notifications for students
    for (final r in affected) {
      final studentId = r['studentId'] as String?;
      if (studentId != null) {
        final notif = {
          'title': 'Marks Published',
          'message': 'Your marks for ${r['courseCode'] ?? r['courseId']} ($examType) have been published.',
          'recipientId': studentId,
          'type': 'marks_published',
          'timestamp': DateTime.now().toIso8601String(),
        };
        addNotification(notif);
        try {
          FirebaseService.instance.push('/notifications/$studentId', notif);
        } catch (e) {
          debugPrint('Failed to push notification to RTDB: $e');
        }
      }
    }
    // Sync published results to Firebase Realtime Database (best-effort)
    try {
      for (final r in affected) {
        final rid = r['resultId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
        final path = '/results/$courseId/$examType/$rid';
        FirebaseService.instance.set(path, r);
      }
    } catch (e) {
      // ignore — RTDB sync is best-effort in this demo
      debugPrint('RTDB sync failed: $e');
    }
    notifyListeners();
  }

  // ─── LIBRARY CRUD ─────────────────────────────────────
  void addLibraryBook(Map<String, dynamic> book) {
    book['bookId'] = 'LIB${(_library.length + 1).toString().padLeft(3, '0')}';
    book['status'] = book['status'] ?? 'issued';
    book['issueDate'] =
        book['issueDate'] ?? DateTime.now().toIso8601String().substring(0, 10);
    _library.add(Map<String, dynamic>.from(book));
    notifyListeners();
  }

  void returnBook(String bookId) {
    final idx = _library.indexWhere((b) => b['bookId'] == bookId);
    if (idx != -1) {
      _library[idx]['status'] = 'returned';
      _library[idx]['returnDate'] =
          DateTime.now().toIso8601String().substring(0, 10);
      notifyListeners();
    }
  }

  // ─── PLACEMENT CRUD ──────────────────────────────────
  void addPlacement(Map<String, dynamic> placement) {
    placement['placementId'] =
        'PLC${(_placements.length + 1).toString().padLeft(3, '0')}';
    if (placement['status'] == null) placement['status'] = 'upcoming';
    placement['registeredCount'] = 0;
    _placements.add(Map<String, dynamic>.from(placement));
    notifyListeners();
  }

  void updatePlacement(String placementId, Map<String, dynamic> updates) {
    final idx = _placements.indexWhere((p) => p['placementId'] == placementId);
    if (idx != -1) {
      _placements[idx].addAll(updates);
      notifyListeners();
    }
  }

  // ─── RESEARCH CRUD ────────────────────────────────────
  void addResearch(Map<String, dynamic> research) {
    research['researchId'] =
        'RSH${(_research.length + 1).toString().padLeft(3, '0')}';
    _research.add(Map<String, dynamic>.from(research));
    notifyListeners();
  }

  void updateResearch(String researchId, Map<String, dynamic> updates) {
    final idx = _research.indexWhere((r) => r['researchId'] == researchId);
    if (idx != -1) {
      _research[idx].addAll(updates);
      notifyListeners();
    }
  }

  void deleteResearch(String researchId) {
    _research.removeWhere((r) => r['researchId'] == researchId);
    notifyListeners();
  }

  // ─── SYLLABUS CRUD ────────────────────────────────────
  void addSyllabus(Map<String, dynamic> syllabusEntry) {
    _syllabus.add(Map<String, dynamic>.from(syllabusEntry));
    notifyListeners();
  }

  void updateSyllabus(String courseId, Map<String, dynamic> updates) {
    final idx = _syllabus.indexWhere((s) => s['courseId'] == courseId);
    if (idx != -1) {
      _syllabus[idx].addAll(updates);
      notifyListeners();
    }
  }

  void updateSyllabusUnitProgress(
      String courseId, int unitNo, int completedHours) {
    final idx = _syllabus.indexWhere((s) => s['courseId'] == courseId);
    if (idx == -1) return;
    final units = (_syllabus[idx]['units'] as List<dynamic>?) ?? [];
    final unitIdx = units.indexWhere((u) => u['unitNo'] == unitNo);
    if (unitIdx >= 0) {
      (units[unitIdx] as Map<String, dynamic>)['completedHours'] =
          completedHours;
      notifyListeners();
    }
  }

  // ─── COMPLAINT UPDATE ─────────────────────────────────
  void updateComplaintStatus(String complaintId, String status,
      {String? resolvedBy, String? resolution}) {
    final idx = _complaints.indexWhere((c) => c['complaintId'] == complaintId);
    if (idx != -1) {
      _complaints[idx]['status'] = status;
      if (resolvedBy != null) _complaints[idx]['resolvedBy'] = resolvedBy;
      if (resolution != null) _complaints[idx]['resolution'] = resolution;
      if (status == 'resolved') {
        _complaints[idx]['resolvedDate'] =
            DateTime.now().toIso8601String().substring(0, 10);
      }
      notifyListeners();
    }
  }

  // ─── DEPARTMENT CRUD ──────────────────────────────────
  void updateDepartment(String departmentId, Map<String, dynamic> updates) {
    final idx =
        _departments.indexWhere((d) => d['departmentId'] == departmentId);
    if (idx != -1) {
      _departments[idx].addAll(updates);
      notifyListeners();
    }
  }

  void deleteDepartment(String departmentId) {
    _departments.removeWhere((d) => d['departmentId'] == departmentId);
    // Cascade: remove faculty, students, courses, classes in this dept
    _faculty.removeWhere((f) => f['departmentId'] == departmentId);
    _students.removeWhere((s) => s['departmentId'] == departmentId);
    _courses.removeWhere((c) => c['departmentId'] == departmentId);
    _classes.removeWhere((c) => c['departmentId'] == departmentId);
    notifyListeners();
  }

  // ─── COURSE UPDATE/DELETE ─────────────────────────────
  void updateCourse(String courseId, Map<String, dynamic> updates) {
    final idx = _courses.indexWhere((c) => c['courseId'] == courseId);
    if (idx != -1) {
      _courses[idx].addAll(updates);
      notifyListeners();
    }
  }

  void deleteCourse(String courseId) {
    _courses.removeWhere((c) => c['courseId'] == courseId);
    // Remove from student enrollments
    for (final s in _students) {
      final enrolled = (s['enrolledCourses'] as List<dynamic>?) ?? [];
      enrolled.remove(courseId);
    }
    // Remove from faculty courseIds
    for (final f in _faculty) {
      final courseIds = (f['courseIds'] as List<dynamic>?) ?? [];
      courseIds.remove(courseId);
    }
    notifyListeners();
  }

  // ─── CLASS DELETE ─────────────────────────────────────
  void deleteClass(String classId) {
    _classes.removeWhere((c) => c['classId'] == classId);
    notifyListeners();
  }

  // ─── LEAVE APPROVE/REJECT ─────────────────────────────
  void approveLeave(String leaveId, String approvedBy) {
    final idx = _leave.indexWhere((l) => l['leaveId'] == leaveId);
    if (idx != -1) {
      _leave[idx]['status'] = 'approved';
      _leave[idx]['approvedBy'] = approvedBy;
      _leave[idx]['approvedDate'] =
          DateTime.now().toIso8601String().substring(0, 10);
      // Deduct from leave balance
      final userId = _leave[idx]['userId'] as String? ?? '';
      final leaveType = _leave[idx]['leaveType'] as String? ?? '';
      final balIdx = _leaveBalance.indexWhere(
          (b) => b['userId'] == userId && b['leaveType'] == leaveType);
      if (balIdx != -1) {
        final used = ((_leaveBalance[balIdx]['used'] as int?) ?? 0) + 1;
        _leaveBalance[balIdx]['used'] = used;
        _leaveBalance[balIdx]['remaining'] =
            ((_leaveBalance[balIdx]['total'] as int?) ?? 0) - used;
      }
      notifyListeners();
    }
  }

  void rejectLeave(String leaveId, String rejectedBy, String reason) {
    final idx = _leave.indexWhere((l) => l['leaveId'] == leaveId);
    if (idx != -1) {
      _leave[idx]['status'] = 'rejected';
      _leave[idx]['rejectedBy'] = rejectedBy;
      _leave[idx]['rejectionReason'] = reason;
      notifyListeners();
    }
  }

  // ─── FACULTY TIMETABLE CRUD ───────────────────────────
  void addFacultyTimetableEntry(
      String facultyId, String day, Map<String, dynamic> slot) {
    final idx = _facultyTimetable
        .indexWhere((t) => t['facultyId'] == facultyId && t['day'] == day);
    if (idx != -1) {
      final slots =
          ((_facultyTimetable[idx]['slots'] as List<dynamic>?) ?? []).toList();
      slots.add(slot);
      _facultyTimetable[idx]['slots'] = slots;
    } else {
      _facultyTimetable.add({
        'facultyId': facultyId,
        'day': day,
        'slots': [slot],
      });
    }
    notifyListeners();
  }

  // ─── ATTENDANCE CRUD (Faculty adding attendance) ──────
  void addAttendanceRecord(Map<String, dynamic> record) {
    _attendance.add(Map<String, dynamic>.from(record));
    notifyListeners();
  }

  void updateAttendanceRecord(String courseId, Map<String, dynamic> updates) {
    final idx = _attendance.indexWhere((a) => a['courseId'] == courseId);
    if (idx != -1) {
      _attendance[idx].addAll(updates);
      notifyListeners();
    }
  }

  void markAttendance(String courseId, String studentId, bool present) {
    // Find or create attendance record
    final idx = _attendance.indexWhere(
        (a) => a['courseId'] == courseId && a['studentId'] == studentId);
    if (idx != -1) {
      _attendance[idx]['totalClasses'] =
          ((_attendance[idx]['totalClasses'] as int?) ?? 0) + 1;
      if (present) {
        _attendance[idx]['attendedClasses'] =
            ((_attendance[idx]['attendedClasses'] as int?) ?? 0) + 1;
      } else {
        _attendance[idx]['absentClasses'] =
            ((_attendance[idx]['absentClasses'] as int?) ?? 0) + 1;
      }
      notifyListeners();
    } else {
      _attendance.add({
        'courseId': courseId,
        'studentId': studentId,
        'totalClasses': 1,
        'attendedClasses': present ? 1 : 0,
        'absentClasses': present ? 0 : 1,
      });
      notifyListeners();
    }
  }

  // ─── SETTINGS PERSISTENCE ─────────────────────────────
  void updateSetting(String key, dynamic value) {
    _settings[key] = value;
    notifyListeners();
  }

  dynamic getSetting(String key, [dynamic defaultValue]) {
    return _settings[key] ?? defaultValue;
  }

  Map<String, dynamic> getUserSettings(String userId) {
    return (_settings[userId] as Map<String, dynamic>?) ?? {};
  }

  void updateUserSettings(String userId, Map<String, dynamic> userSettings) {
    _settings[userId] = userSettings;
    notifyListeners();
  }

  // ─── DYNAMIC ROLES & PERMISSIONS ─────────────────────
  String _normalizePortalRole(String value) {
    const allowed = {'student', 'faculty', 'hod', 'admin'};
    final normalized = value.trim().toLowerCase();
    return allowed.contains(normalized) ? normalized : 'admin';
  }

  List<String> _normalizedStringList(dynamic raw) {
    if (raw is! List) return <String>[];
    return raw
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  Map<String, dynamic> _getRolePermissionsStore() {
    final raw = getSetting('rolePermissionRules', {});
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  List<String> availableModulesForPortal(String portalRole) {
    final role = _normalizePortalRole(portalRole);
    return List<String>.from(_portalModules[role] ?? const <String>[]);
  }

  Map<String, dynamic> getRolePolicy(String roleName) {
    final key = roleName.trim().toLowerCase();
    final store = _getRolePermissionsStore();
    final dynamic existing = store[key];
    if (existing is Map) {
      return Map<String, dynamic>.from(existing);
    }

    final defaultPortalRole = _normalizePortalRole(key);
    return {
      'portalRole': defaultPortalRole,
      'view': List<String>.from(
          _portalModules[defaultPortalRole] ?? const <String>[]),
      'edit': List<String>.from(
          _defaultEditableModules[defaultPortalRole] ?? const <String>[]),
    };
  }

  void upsertRolePolicy({
    required String roleName,
    required String portalRole,
    required List<String> viewModules,
    required List<String> editModules,
  }) {
    final key = roleName.trim().toLowerCase();
    if (key.isEmpty) return;

    final normalizedPortalRole = _normalizePortalRole(portalRole);
    final store = _getRolePermissionsStore();
    store[key] = {
      'portalRole': normalizedPortalRole,
      'view': viewModules
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList(),
      'edit': editModules
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList(),
    };
    updateSetting('rolePermissionRules', store);
  }

  String _resolvePortalRoleForUser(Map<String, dynamic> user) {
    final explicitPortal = (user['portalRole'] as String?) ?? '';
    if (explicitPortal.trim().isNotEmpty) {
      return _normalizePortalRole(explicitPortal);
    }

    final role = (user['role'] as String? ?? '').toLowerCase();
    if (role == 'student' ||
        role == 'faculty' ||
        role == 'hod' ||
        role == 'admin') {
      return role;
    }

    final rolePolicy = getRolePolicy(role);
    final policyPortal = rolePolicy['portalRole']?.toString() ?? '';
    if (policyPortal.isNotEmpty) {
      return _normalizePortalRole(policyPortal);
    }

    final userId = (user['id'] as String? ?? '').toUpperCase();
    if (userId.startsWith('STU')) return 'student';
    if (userId.startsWith('FAC')) return 'faculty';
    if (userId.startsWith('HOD')) return 'hod';
    return 'admin';
  }

  Map<String, dynamic> getEffectivePermissionsForUser({String? userId}) {
    final targetUserId = userId ?? _currentUserId;
    if (targetUserId == null) {
      return {'portalRole': 'admin', 'view': <String>[], 'edit': <String>[]};
    }

    final user = _users.firstWhere(
      (u) => u['id'] == targetUserId,
      orElse: () => <String, dynamic>{},
    );
    if (user.isEmpty) {
      return {'portalRole': 'admin', 'view': <String>[], 'edit': <String>[]};
    }

    final role = (user['role'] as String? ?? 'admin').toLowerCase();
    final portalRole = _resolvePortalRoleForUser(user);
    final rolePolicy = getRolePolicy(role);
    final userPermissions = user['permissions'];
    final userPermissionsMap = userPermissions is Map
        ? Map<String, dynamic>.from(userPermissions)
        : <String, dynamic>{};

    final roleView = _normalizedStringList(rolePolicy['view']);
    final roleEdit = _normalizedStringList(rolePolicy['edit']);
    final userView = _normalizedStringList(userPermissionsMap['view']);
    final userEdit = _normalizedStringList(userPermissionsMap['edit']);
    final defaultView =
        List<String>.from(_portalModules[portalRole] ?? const <String>[]);
    final defaultEdit = List<String>.from(
        _defaultEditableModules[portalRole] ?? const <String>[]);

    // For built-in roles, never drop baseline portal modules.
    final isBuiltInRole =
      const {'student', 'faculty', 'hod', 'admin'}.contains(role);
    final effectiveView = isBuiltInRole
      ? <String>{...defaultView, ...roleView, ...userView}.toList()
      : (userView.isNotEmpty
        ? userView
        : (roleView.isNotEmpty ? roleView : defaultView));
    final effectiveEdit = isBuiltInRole
      ? <String>{...defaultEdit, ...roleEdit, ...userEdit}.toList()
      : (userEdit.isNotEmpty
        ? userEdit
        : (roleEdit.isNotEmpty ? roleEdit : defaultEdit));

    return {
      'portalRole': portalRole,
      'view': effectiveView,
      'edit': effectiveEdit,
    };
  }

  bool canViewRoute(String route, {String? userId}) {
    final clean = Uri.tryParse(route)?.path ?? route;
    final segments = clean.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return false;
    if (segments.first == 'login' || segments.first == 'hacker-welcome')
      return true;

    final permissions = getEffectivePermissionsForUser(userId: userId);
    final allowed = _normalizedStringList(permissions['view']);
    if (allowed.contains('*')) return true;
    if (segments.length == 1) return true;
    final module = segments[1].toLowerCase();
    return allowed.contains(module);
  }

  bool canEditModule(String module, {String? userId}) {
    final permissions = getEffectivePermissionsForUser(userId: userId);
    final editable = _normalizedStringList(permissions['edit']);
    if (editable.contains('*')) return true;
    return editable.contains(module.trim().toLowerCase());
  }

  String getHomeRouteForCurrentUser() {
    if (_currentUserId == null) return '/login';
    final permissions = getEffectivePermissionsForUser();
    final portalRole =
        _normalizePortalRole(permissions['portalRole']?.toString() ?? 'admin');
    final allowedViews = _normalizedStringList(permissions['view']);
    if (allowedViews.contains('*') || allowedViews.contains('dashboard')) {
      return '/$portalRole/dashboard';
    }
    if (allowedViews.isNotEmpty) {
      return '/$portalRole/${allowedViews.first}';
    }
    return '/$portalRole/dashboard';
  }

  // ─── CHANGE PASSWORD ─────────────────────────────────
  bool changePassword(String userId, String oldPassword, String newPassword) {
    final idx = _users.indexWhere((u) => u['id'] == userId);
    if (idx == -1) return false;
    final storedHash = _users[idx]['password'] as String? ?? '';
    if (!SecurityService.verifyPassword(oldPassword, userId, storedHash))
      return false;
    _users[idx]['password'] = SecurityService.hashPassword(newPassword, userId);
    notifyListeners();
    return true;
  }

  // ─── RESET PASSWORD TO DEFAULT ────────────────────────
  bool resetPasswordToDefault(String userId) {
    final idx = _users.indexWhere((u) => u['id'] == userId);
    if (idx == -1) return false;
    final defaultPassword = 'ksrce@${userId.toLowerCase()}';
    _users[idx]['password'] =
        SecurityService.hashPassword(defaultPassword, userId);
    notifyListeners();
    return true;
  }
}
