from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import crud, schemas, auth, models

router = APIRouter(prefix="/attendance", tags=["attendance"])

@router.post("/", response_model=schemas.AttendanceResponse, status_code=status.HTTP_201_CREATED)
def mark_attendance(attendance: schemas.AttendanceCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_active_user)):
    if current_user.role not in ["faculty", "admin", "hod"]:
        raise HTTPException(status_code=403, detail="Not authorized to mark attendance")
    return crud.mark_attendance(db=db, attendance=attendance, marker_id=current_user.id)

@router.get("/{student_id}", response_model=List[schemas.AttendanceResponse])
def get_student_attendance(student_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_active_user)):
    # Only allow students to view their own attendance, or faculty/admin to view anyone's
    if current_user.role == "student" and current_user.id != f"USR_{student_id}":
        # Note: mapping logic here is basic, in real system we'd use relationship
        raise HTTPException(status_code=403, detail="Not authorized to view other students' attendance")
        
    records = crud.get_attendance_for_student(db, student_id=student_id)
    return records
