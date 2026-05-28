from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Enum, Numeric
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from database import Base

class RoleEnum(str, enum.Enum):
    STUDENT = "student"
    FACULTY = "faculty"
    HOD = "hod"
    ADMIN = "admin"

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True) # e.g. STU001, FAC001
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, nullable=False) # Maps to RoleEnum
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    student_profile = relationship("Student", back_populates="user", uselist=False)
    faculty_profile = relationship("Faculty", back_populates="user", uselist=False)

class Department(Base):
    __tablename__ = "departments"
    
    id = Column(String, primary_key=True, index=True) # e.g. DEPT_CSE
    name = Column(String, nullable=False)
    code = Column(String, nullable=False, unique=True)
    hod_id = Column(String, ForeignKey("users.id"), nullable=True)

class Student(Base):
    __tablename__ = "students"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    roll_no = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    email = Column(String, nullable=False)
    phone = Column(String, unique=True, nullable=True)
    department_id = Column(String, ForeignKey("departments.id"), nullable=False)
    year = Column(Integer, nullable=False)
    section = Column(String, nullable=False)
    cgpa = Column(Numeric(4, 2), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="student_profile")
    department = relationship("Department")
    attendances = relationship("Attendance", back_populates="student", cascade="all, delete-orphan")
    exam_results = relationship("ExamResult", back_populates="student", cascade="all, delete-orphan")

class Faculty(Base):
    __tablename__ = "faculty"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    department_id = Column(String, ForeignKey("departments.id"), nullable=False)
    is_hod = Column(Integer, default=0) # 0 or 1 for boolean in older postgres/sqlite compat

    # Relationships
    user = relationship("User", back_populates="faculty_profile")
    department = relationship("Department")

class Course(Base):
    __tablename__ = "courses"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False)
    department_id = Column(String, ForeignKey("departments.id"), nullable=False)
    credits = Column(Integer, nullable=False, default=3)
    
    # Relationships
    department = relationship("Department")
    attendances = relationship("Attendance", back_populates="course")
    exam_results = relationship("ExamResult", back_populates="course")

class Attendance(Base):
    __tablename__ = "attendance"

    id = Column(String, primary_key=True, index=True)
    student_id = Column(String, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    course_id = Column(String, ForeignKey("courses.id"), nullable=False)
    date = Column(DateTime, nullable=False) # Changed from Date to DateTime for broader compatibility but it should store dates
    status = Column(String, nullable=False) # PRESENT, ABSENT, LATE
    marked_by = Column(String, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    student = relationship("Student", back_populates="attendances")
    course = relationship("Course", back_populates="attendances")
    marker = relationship("User")

class ExamResult(Base):
    __tablename__ = "exam_results"

    id = Column(String, primary_key=True, index=True)
    student_id = Column(String, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    course_id = Column(String, ForeignKey("courses.id"), nullable=False)
    exam_type = Column(String, nullable=False)
    marks_obtained = Column(Numeric(5, 2), nullable=True)
    max_marks = Column(Integer, nullable=True)
    grade = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    student = relationship("Student", back_populates="exam_results")
    course = relationship("Course", back_populates="exam_results")

class AuditLog(Base):
    __tablename__ = "audit_log"

    id = Column(String, primary_key=True, index=True)
    table_name = Column(String, nullable=False)
    operation = Column(String, nullable=False) # INSERT, UPDATE, DELETE
    record_id = Column(String, nullable=False)
    changes = Column(String, nullable=True) # JSON string representation
    changed_by = Column(String, nullable=False)
    changed_at = Column(DateTime, default=datetime.utcnow)

class Assignment(Base):
    __tablename__ = "assignments"

    id = Column(String, primary_key=True, index=True)
    course_id = Column(String, ForeignKey("courses.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    due_date = Column(DateTime, nullable=False)
    created_by = Column(String, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    course = relationship("Course")
    creator = relationship("User")

class Submission(Base):
    __tablename__ = "submissions"

    id = Column(String, primary_key=True, index=True)
    assignment_id = Column(String, ForeignKey("assignments.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(String, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    content = Column(String, nullable=True)
    submitted_at = Column(DateTime, default=datetime.utcnow)
    marks = Column(Numeric(5, 2), nullable=True)
    
    # Relationships
    assignment = relationship("Assignment")
    student = relationship("Student")

class Timetable(Base):
    __tablename__ = "timetable"

    id = Column(String, primary_key=True, index=True)
    department_id = Column(String, ForeignKey("departments.id"), nullable=False)
    course_id = Column(String, ForeignKey("courses.id"), nullable=False)
    faculty_id = Column(String, ForeignKey("faculty.id"), nullable=False)
    day_of_week = Column(String, nullable=False) # e.g., MONDAY, TUESDAY
    start_time = Column(String, nullable=False) # e.g., "09:00"
    end_time = Column(String, nullable=False) # e.g., "10:00"
    room = Column(String, nullable=True)
    
    # Relationships
    department = relationship("Department")
    course = relationship("Course")
    faculty = relationship("Faculty")

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    type = Column(String, nullable=False)  # assignment, exam, attendance, grade, event, alert
    sender = Column(String, nullable=True)
    is_read = Column(Integer, default=0)   # 0 = unread, 1 = read
    read_at = Column(DateTime, nullable=True)
    metadata = Column(String, nullable=True)  # JSON string
    timestamp = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User")
