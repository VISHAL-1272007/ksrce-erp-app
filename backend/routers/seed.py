from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
import models
from database import get_db
from passlib.context import CryptContext
import os
import uuid

seed_router = APIRouter(prefix="/admin/seed", tags=["Seed"])
admin_router = APIRouter(prefix="/admin", tags=["Admin"])

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

SEED_SECRET = os.getenv("SEED_SECRET", "ksrce-seed-2024")

class StudentSeed(BaseModel):
    roll_number: str
    full_name: str
    email: str
    phone: Optional[str] = ""
    department: str
    year: str
    section: str = "A"

class SeedRequest(BaseModel):
    secret: str
    students: List[StudentSeed]

class CreateUserRequest(BaseModel):
    secret: str
    email: str
    password: str
    role: str  # admin, faculty, student, hod
    name: str = ""

def _upsert_user(payload: CreateUserRequest, db: Session):
    if payload.secret != SEED_SECRET:
        raise HTTPException(status_code=403, detail="Invalid secret")
    if payload.role not in ["admin", "faculty", "student", "hod"]:
        raise HTTPException(status_code=400, detail="role must be one of: admin, faculty, student, hod")
    hashed = pwd_context.hash(payload.password)
    existing = db.query(models.User).filter(models.User.email == payload.email.lower()).first()
    if existing:
        existing.password_hash = hashed
        existing.role = payload.role
        db.commit()
        return {"message": f"{payload.role.capitalize()} user {payload.email} updated", "action": "updated", "email": payload.email, "password": payload.password, "role": payload.role}
    uid = str(uuid.uuid4())
    user = models.User(id=uid, email=payload.email.lower(), password_hash=hashed, role=payload.role)
    db.add(user)
    db.commit()
    return {"message": f"{payload.role.capitalize()} user {payload.email} created", "action": "created", "email": payload.email, "password": payload.password, "role": payload.role}

@admin_router.post("/create-admin")
def create_admin(payload: CreateUserRequest, db: Session = Depends(get_db)):
    payload.role = "admin"
    return _upsert_user(payload, db)

@admin_router.post("/create-faculty")
def create_faculty(payload: CreateUserRequest, db: Session = Depends(get_db)):
    payload.role = "faculty"
    return _upsert_user(payload, db)

@admin_router.post("/create-user")
def create_any_user(payload: CreateUserRequest, db: Session = Depends(get_db)):
    return _upsert_user(payload, db)

@seed_router.post("")
def seed_students(payload: SeedRequest, db: Session = Depends(get_db)):
    try:
        if payload.secret != SEED_SECRET:
            raise HTTPException(status_code=403, detail="Invalid seed secret")

        default_password = "ksrce"
        hashed_pwd = pwd_context.hash(default_password)
        
        added = []
        skipped = []

        # Ensure department exists, or create one
        dept_id = f"DEPT_{payload.students[0].department.upper().replace(' ', '_').replace('(', '').replace(')', '')}" if payload.students else "DEPT_CSE"
        dept = db.query(models.Department).filter(models.Department.id == dept_id).first()
        if not dept and payload.students:
            dept = models.Department(
                id=dept_id,
                name=payload.students[0].department,
                code=payload.students[0].department.upper().replace(' ', '_').replace('(', '').replace(')', '')
            )
            db.add(dept)
            db.flush()

        for s in payload.students:
            existing_student = db.query(models.Student).filter(
                models.Student.roll_no == s.roll_number
            ).first()
            if existing_student:
                skipped.append(s.roll_number)
                continue

            existing_user = db.query(models.User).filter(
                models.User.email == s.email.lower()
            ).first()
            if existing_user:
                skipped.append(s.roll_number)
                continue

            import uuid
            uid = str(uuid.uuid4())
            
            user = models.User(
                id=uid,
                email=s.email.lower(),
                password_hash=hashed_pwd,
                role="student"
            )
            db.add(user)
            db.flush()

            # Parse year string (e.g. "II" -> 2)
            year_num = 1
            if s.year == "II":
                year_num = 2
            elif s.year == "III":
                year_num = 3
            elif s.year == "IV":
                year_num = 4
            elif s.year.isdigit():
                year_num = int(s.year)

            student = models.Student(
                id=s.roll_number,
                user_id=uid,
                roll_no=s.roll_number,
                name=s.full_name,
                email=s.email.lower(),
                phone=s.phone or None,
                department_id=dept.id,
                year=year_num,
                section=s.section
            )
            db.add(student)
            added.append(s.roll_number)

        db.commit()
        return {
            "added": len(added),
            "skipped": len(skipped),
            "added_roll_numbers": added,
            "skipped_roll_numbers": skipped,
            "default_password": default_password
        }
    except Exception as e:
        import traceback
        tb = traceback.format_exc()
        raise HTTPException(status_code=500, detail=f"Error seeding database: {str(e)}\n{tb}")
