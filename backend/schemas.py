from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

# Token Schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    user_id: Optional[str] = None
    role: Optional[str] = None

# User Schemas
class UserBase(BaseModel):
    id: str
    email: EmailStr
    role: str

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Department Schemas
class DepartmentBase(BaseModel):
    id: str
    name: str
    code: str
    hod_id: Optional[str] = None

class DepartmentCreate(DepartmentBase):
    pass

class DepartmentResponse(DepartmentBase):
    class Config:
        from_attributes = True

# Course Schemas
class CourseBase(BaseModel):
    id: str
    name: str
    department_id: str
    credits: int = 3

class CourseCreate(CourseBase):
    pass

class CourseResponse(CourseBase):
    class Config:
        from_attributes = True

# Student Schemas
class StudentBase(BaseModel):
    id: str
    roll_no: str
    name: str
    email: EmailStr
    phone: Optional[str] = None
    department_id: str
    year: int
    section: str
    cgpa: Optional[float] = None

class StudentCreate(StudentBase):
    password: str # For creating the associated user account

class StudentResponse(StudentBase):
    created_at: datetime
    updated_at: datetime
    user_id: str
    
    class Config:
        from_attributes = True

# Attendance Schemas
class AttendanceBase(BaseModel):
    student_id: str
    course_id: str
    date: datetime
    status: str

class AttendanceCreate(AttendanceBase):
    pass

class AttendanceResponse(AttendanceBase):
    id: str
    marked_by: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# ExamResult Schemas
class ExamResultBase(BaseModel):
    student_id: str
    course_id: str
    exam_type: str
    marks_obtained: Optional[float] = None
    max_marks: Optional[int] = None
    grade: Optional[str] = None

class ExamResultCreate(ExamResultBase):
    pass

class ExamResultResponse(ExamResultBase):
    id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Assignment Schemas
class AssignmentBase(BaseModel):
    course_id: str
    title: str
    description: Optional[str] = None
    due_date: datetime

class AssignmentCreate(AssignmentBase):
    pass

class AssignmentResponse(AssignmentBase):
    id: str
    created_by: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# Submission Schemas
class SubmissionBase(BaseModel):
    assignment_id: str
    student_id: str
    content: Optional[str] = None

class SubmissionCreate(SubmissionBase):
    pass

class SubmissionResponse(SubmissionBase):
    id: str
    submitted_at: datetime
    marks: Optional[float] = None
    
    class Config:
        from_attributes = True

# Timetable Schemas
class TimetableBase(BaseModel):
    department_id: str
    course_id: str
    faculty_id: str
    day_of_week: str
    start_time: str
    end_time: str
    room: Optional[str] = None

class TimetableCreate(TimetableBase):
    pass

class TimetableResponse(TimetableBase):
    id: str
    
    class Config:
        from_attributes = True

# Notification Schemas
class NotificationCreate(BaseModel):
    user_id: str
    title: str
    message: str
    type: str  # assignment, exam, attendance, grade, event, alert
    sender: Optional[str] = None
    extra_data: Optional[str] = None  # JSON string

class NotificationResponse(BaseModel):
    id: str
    user_id: str
    title: str
    message: str
    type: str
    sender: Optional[str] = None
    is_read: bool
    read_at: Optional[datetime] = None
    extra_data: Optional[str] = None
    timestamp: datetime

    class Config:
        from_attributes = True
