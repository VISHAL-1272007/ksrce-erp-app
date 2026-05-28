from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import crud, schemas, auth, models

router = APIRouter(prefix="/students", tags=["students"])

@router.get("/", response_model=List[schemas.StudentResponse])
def read_students(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_active_user)):
    students = crud.get_students(db, skip=skip, limit=limit)
    return students

@router.get("/{student_id}", response_model=schemas.StudentResponse)
def read_student(student_id: str, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_active_user)):
    db_student = crud.get_student(db, student_id=student_id)
    if db_student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    return db_student

@router.post("/", response_model=schemas.StudentResponse, status_code=status.HTTP_201_CREATED)
def create_student(student: schemas.StudentCreate, db: Session = Depends(get_db)):
    # Note: For creation, we might not require auth or we might require ADMIN auth. 
    # For now, it's open to allow easy testing.
    db_student = crud.get_student(db, student_id=student.id)
    if db_student:
        raise HTTPException(status_code=400, detail="Student ID already registered")
    return crud.create_student(db=db, student=student)
