/// Smart Timetable Scheduler Service
/// Generates optimized timetables using constraint satisfaction

class ClassSession {
  final String courseCode;
  final String courseName;
  final String facultyId;
  final String roomId;
  final int strength;
  final String day;
  final String timeSlot;

  ClassSession({
    required this.courseCode,
    required this.courseName,
    required this.facultyId,
    required this.roomId,
    required this.strength,
    required this.day,
    required this.timeSlot,
  });
}

class SchedulingConstraints {
  final List<Map<String, dynamic>> courses;
  final List<Map<String, dynamic>> faculties;
  final List<Map<String, dynamic>> rooms;
  final List<Map<String, dynamic>> classes;

  SchedulingConstraints({
    required this.courses,
    required this.faculties,
    required this.rooms,
    required this.classes,
  });
}

class SmartTimetableScheduler {
  static const List<String> workingDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];
  static const List<String> timeSlots = [
    '09:00-10:00',
    '10:15-11:15',
    '11:30-12:30',
    '13:00-14:00',
    '14:15-15:15',
  ];

  /// Generate optimal schedule using greedy algorithm
  static Future<List<ClassSession>> generateOptimalSchedule(
    SchedulingConstraints constraints,
  ) async {
    return _greedyScheduling(constraints);
  }

  static List<ClassSession> _greedyScheduling(
      SchedulingConstraints constraints) {
    var schedule = <ClassSession>[];
    var facultySlots = <String, Set<String>>{};
    var roomSlots = <String, Set<String>>{};

    // Sort courses by strength (descending)
    var sortedCourses = List<Map<String, dynamic>>.from(constraints.courses);
    sortedCourses.sort((a, b) =>
        ((b['strength'] ?? 0) as int).compareTo(((a['strength'] ?? 0) as int)));

    for (var course in sortedCourses) {
      var courseCode = (course['code'] ?? '').toString();
      var courseName = (course['name'] ?? '').toString();
      var strength = (course['strength'] ?? 30) as int;
      var classesPerWeek = (course['classesPerWeek'] ?? 3) as int;

      for (int classIdx = 0; classIdx < classesPerWeek; classIdx++) {
        var scheduled = false;

        for (var day in workingDays) {
          for (var timeSlot in timeSlots) {
            var slotKey = '$day:$timeSlot';

            for (var faculty in constraints.faculties) {
              var facultyId = (faculty['id'] ?? '').toString();
              var facultyKey = '$facultyId:$slotKey';

              if ((facultySlots[facultyId] ?? {}).contains(slotKey)) continue;

              for (var room in constraints.rooms) {
                var roomId = (room['id'] ?? '').toString();
                var capacity = (room['capacity'] ?? 50) as int;
                var roomKey = '$roomId:$slotKey';

                if (strength <= capacity &&
                    !(roomSlots[roomId] ?? {}).contains(slotKey)) {
                  schedule.add(ClassSession(
                    courseCode: courseCode,
                    courseName: courseName,
                    facultyId: facultyId,
                    roomId: roomId,
                    strength: strength,
                    day: day,
                    timeSlot: timeSlot,
                  ));

                  (facultySlots.putIfAbsent(facultyId, () => {}) as Set<String>)
                      .add(slotKey);
                  (roomSlots.putIfAbsent(roomId, () => {}) as Set<String>)
                      .add(slotKey);

                  scheduled = true;
                  break;
                }
              }
              if (scheduled) break;
            }
            if (scheduled) break;
          }
          if (scheduled) break;
        }
      }
    }

    return schedule;
  }

  /// Validate a schedule against all constraints
  static Map<String, dynamic> validateSchedule(
    List<ClassSession> schedule,
    SchedulingConstraints constraints,
  ) {
    var errors = <String>[];
    var warnings = <String>[];

    // Check faculty conflicts
    var facultyMap = <String, List<ClassSession>>{};
    for (var session in schedule) {
      var key = '${session.facultyId}:${session.day}:${session.timeSlot}';
      if (!facultyMap.containsKey(session.facultyId)) {
        facultyMap[session.facultyId] = [];
      }
      facultyMap[session.facultyId]!.add(session);
    }

    for (var entry in facultyMap.entries) {
      var slotMap = <String, int>{};
      for (var session in entry.value) {
        var slotKey = '${session.day}:${session.timeSlot}';
        slotMap[slotKey] = (slotMap[slotKey] ?? 0) + 1;
      }

      for (var slot in slotMap.entries) {
        if (slot.value > 1) {
          errors.add(
              'Faculty ${entry.key} has ${slot.value} classes in ${slot.key}');
        }
      }
    }

    // Check room conflicts
    var roomMap = <String, List<ClassSession>>{};
    for (var session in schedule) {
      var key = '${session.roomId}:${session.day}:${session.timeSlot}';
      if (!roomMap.containsKey(session.roomId)) {
        roomMap[session.roomId] = [];
      }
      roomMap[session.roomId]!.add(session);
    }

    for (var entry in roomMap.entries) {
      var slotMap = <String, int>{};
      for (var session in entry.value) {
        var slotKey = '${session.day}:${session.timeSlot}';
        slotMap[slotKey] = (slotMap[slotKey] ?? 0) + 1;
      }

      for (var slot in slotMap.entries) {
        if (slot.value > 1) {
          errors.add(
              'Room ${entry.key} has ${slot.value} classes in ${slot.key}');
        }
      }
    }

    // Check room capacity
    for (var session in schedule) {
      var room = constraints.rooms.firstWhere(
        (r) => (r['id'] ?? '').toString() == session.roomId,
        orElse: () => {'capacity': 100},
      );
      var capacity = (room['capacity'] ?? 100) as int;
      if (session.strength > capacity) {
        errors.add(
            'Class strength (${session.strength}) exceeds room capacity ($capacity) for ${session.courseCode}');
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
    };
  }

  /// Get schedule for a specific day
  static List<ClassSession> getScheduleForDay(
    List<ClassSession> schedule,
    String day,
  ) {
    return schedule.where((s) => s.day == day).toList()
      ..sort((a, b) => timeSlots.indexOf(a.timeSlot)
          .compareTo(timeSlots.indexOf(b.timeSlot)));
  }

  /// Get schedule for a specific faculty
  static List<ClassSession> getScheduleForFaculty(
    List<ClassSession> schedule,
    String facultyId,
  ) {
    return schedule.where((s) => s.facultyId == facultyId).toList();
  }

  /// Get schedule for a specific course
  static List<ClassSession> getScheduleForCourse(
    List<ClassSession> schedule,
    String courseCode,
  ) {
    return schedule.where((s) => s.courseCode == courseCode).toList();
  }

  /// Export schedule as iCal format
  static String exportAsIcal(List<ClassSession> schedule) {
    var buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//KSRCE ERP//Timetable//EN');
    buffer.writeln('CALSCALE:GREGORIAN');

    for (var session in schedule) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${session.courseCode}-${session.day}');
      buffer.writeln('SUMMARY:${session.courseName}');
      buffer.writeln('LOCATION:Room ${session.roomId}');
      buffer.writeln('DESCRIPTION:Faculty: ${session.facultyId}\\nStrength: ${session.strength}');
      buffer.writeln('STATUS:CONFIRMED');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }
}
