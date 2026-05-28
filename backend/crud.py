from sqlalchemy.orm import Session
import models, schemas
from auth import get_password_hash
import json
import uuid

def _log_audit(db: Session, table_name: str, operation: str, record_id: str, changes: dict, changed_by: str = "system"):
    log_entry = models.AuditLog(
        id=str(uuid.uuid4()),
        table_name=table_name,
        operation=operation,
        record_id=record_id,
        changes=json.dumps(changes),
        changed_by=changed_by
    )
    db.add(log_entry)

# --- User/Auth CRUD ---
def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        id=user.id,
        email=user.email,
        role=user.role,
        password_hash=hashed_password
    )
    db.add(db_user)
    _log_audit(db, "users", "INSERT", db_user.id, {"email": db_user.email})
    db.commit()
    db.refresh(db_user)
    return db_user

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

# --- Department CRUD ---
def get_departments(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Department).offset(skip).limit(limit).all()

def create_department(db: Session, dept: schemas.DepartmentCreate):
    db_dept = models.Department(**dept.dict())
    db.add(db_dept)
    _log_audit(db, "departments", "INSERT", db_dept.id, {"name": db_dept.name})
    db.commit()
    db.refresh(db_dept)
    return db_dept

# --- Course CRUD ---
def get_courses(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Course).offset(skip).limit(limit).all()

def create_course(db: Session, course: schemas.CourseCreate):
    db_course = models.Course(**course.dict())
    db.add(db_course)
    _log_audit(db, "courses", "INSERT", db_course.id, {"name": db_course.name})
    db.commit()
    db.refresh(db_course)
    return db_course

# --- Student CRUD ---
def get_students(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Student).offset(skip).limit(limit).all()

def get_student(db: Session, student_id: str):
    return db.query(models.Student).filter(models.Student.id == student_id).first()

def create_student(db: Session, student: schemas.StudentCreate):
    # First create the User for the student
    user_data = schemas.UserCreate(
        id=student.user_id if hasattr(student, 'user_id') else f"USR_{student.id}",
        email=student.email,
        password=student.password,
        role="student"
    )
    db_user = create_user(db, user_data)
    
    # Then create the student profile
    student_dict = student.dict(exclude={'password'})
    student_dict['user_id'] = db_user.id
    
    db_student = models.Student(**student_dict)
    db.add(db_student)
    _log_audit(db, "students", "INSERT", db_student.id, {"name": db_student.name, "user_id": db_student.user_id})
    db.commit()
    db.refresh(db_student)
    return db_student

# --- Attendance CRUD ---
def mark_attendance(db: Session, attendance: schemas.AttendanceCreate, marker_id: str):
    db_attendance = models.Attendance(**attendance.dict(), marked_by=marker_id)
    db.add(db_attendance)
    _log_audit(db, "attendance", "INSERT", db_attendance.id, {"status": db_attendance.status}, marker_id)
    db.commit()
    db.refresh(db_attendance)
    return db_attendance

def get_attendance_for_student(db: Session, student_id: str):
    return db.query(models.Attendance).filter(models.Attendance.student_id == student_id).all()

# --- ExamResult CRUD ---
def create_exam_result(db: Session, result: schemas.ExamResultCreate, user_id: str):
    # Generate a unique ID (in a real app, use UUID)
    import uuid
    result_id = str(uuid.uuid4())
    db_result = models.ExamResult(**result.dict(), id=result_id)
    db.add(db_result)
    _log_audit(db, "exam_results", "INSERT", result_id, {"grade": db_result.grade}, user_id)
    db.commit()
    db.refresh(db_result)
    return db_result

def get_exam_results_for_student(db: Session, student_id: str):
    return db.query(models.ExamResult).filter(models.ExamResult.student_id == student_id).all()

def get_exam_results_by_course(db: Session, course_id: str):
    return db.query(models.ExamResult).filter(models.ExamResult.course_id == course_id).all()

# --- Assignment CRUD ---
def create_assignment(db: Session, assignment: schemas.AssignmentCreate, creator_id: str):
    import uuid
    assignment_id = str(uuid.uuid4())
    db_assignment = models.Assignment(**assignment.dict(), id=assignment_id, created_by=creator_id)
    db.add(db_assignment)
    _log_audit(db, "assignments", "INSERT", assignment_id, {"title": db_assignment.title}, creator_id)
    db.commit()
    db.refresh(db_assignment)
    return db_assignment

def get_assignments_by_course(db: Session, course_id: str):
    return db.query(models.Assignment).filter(models.Assignment.course_id == course_id).all()

# --- Submission CRUD ---
def create_submission(db: Session, submission: schemas.SubmissionCreate):
    import uuid
    submission_id = str(uuid.uuid4())
    db_submission = models.Submission(**submission.dict(), id=submission_id)
    db.add(db_submission)
    _log_audit(db, "submissions", "INSERT", submission_id, {"assignment_id": db_submission.assignment_id}, submission.student_id)
    db.commit()
    db.refresh(db_submission)
    return db_submission

def get_submissions_by_assignment(db: Session, assignment_id: str):
    return db.query(models.Submission).filter(models.Submission.assignment_id == assignment_id).all()

# --- Timetable CRUD ---
def create_timetable(db: Session, timetable: schemas.TimetableCreate, creator_id: str):
    import uuid
    timetable_id = str(uuid.uuid4())
    db_timetable = models.Timetable(**timetable.dict(), id=timetable_id)
    db.add(db_timetable)
    _log_audit(db, "timetable", "INSERT", timetable_id, {"course_id": db_timetable.course_id}, creator_id)
    db.commit()
    db.refresh(db_timetable)
    return db_timetable

def get_timetable_by_department(db: Session, department_id: str):
    return db.query(models.Timetable).filter(models.Timetable.department_id == department_id).all()

# --- Notification CRUD ---
def create_notification(db: Session, notif: schemas.NotificationCreate, creator_id: str):
    import uuid
    notif_id = str(uuid.uuid4())
    db_notif = models.Notification(
        id=notif_id,
        user_id=notif.user_id,
        title=notif.title,
        message=notif.message,
        type=notif.type,
        sender=notif.sender or creator_id,
        metadata=notif.metadata,
    )
    db.add(db_notif)
    db.commit()
    db.refresh(db_notif)
    return db_notif

def get_notifications_for_user(db: Session, user_id: str):
    return (
        db.query(models.Notification)
        .filter(models.Notification.user_id == user_id)
        .order_by(models.Notification.timestamp.desc())
        .limit(100)
        .all()
    )

def mark_notification_read(db: Session, notif_id: str, user_id: str):
    notif = (
        db.query(models.Notification)
        .filter(models.Notification.id == notif_id, models.Notification.user_id == user_id)
        .first()
    )
    if notif:
        notif.is_read = 1
        notif.read_at = datetime.utcnow()
        db.commit()
        db.refresh(notif)
    return notif

def delete_notification(db: Session, notif_id: str, user_id: str):
    notif = (
        db.query(models.Notification)
        .filter(models.Notification.id == notif_id, models.Notification.user_id == user_id)
        .first()
    )
    if notif:
        db.delete(notif)
        db.commit()
    return notif

