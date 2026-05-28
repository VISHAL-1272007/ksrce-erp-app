from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
import models
from database import get_db
from passlib.context import CryptContext
import os

router = APIRouter(prefix="/admin/seed", tags=["Seed"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

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

@router.post("")
def seed_students(payload: SeedRequest, db: Session = Depends(get_db)):
    if payload.secret != SEED_SECRET:
        raise HTTPException(status_code=403, detail="Invalid seed secret")

    default_password = "ksrce"
    hashed_pwd = pwd_context.hash(default_password)
    
    added = []
    skipped = []

    for s in payload.students:
        existing_student = db.query(models.Student).filter(
            models.Student.roll_number == s.roll_number
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

        user = models.User(
            email=s.email.lower(),
            full_name=s.full_name,
            password_hash=hashed_pwd,
            role="student"
        )
        db.add(user)
        db.flush()

        student = models.Student(
            user_id=user.id,
            roll_number=s.roll_number,
            department=s.department,
            year=s.year,
            section=s.section,
            phone_number=s.phone or ""
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
