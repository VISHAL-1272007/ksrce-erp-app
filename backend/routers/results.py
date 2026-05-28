from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import crud, schemas, auth

router = APIRouter(prefix="/results", tags=["results"])

@router.get("/", response_model=List[schemas.ExamResultResponse])
def get_exam_results(
    db: Session = Depends(get_db), 
    current_user: schemas.TokenData = Depends(auth.get_current_user)
):
    """
    Get exam results. 
    If student: returns only their results.
    If faculty/admin/hod: could return all or be restricted by role (currently returns all for simplicity, but can be filtered).
    """
    if current_user.role == "student":
        # We need the student's ID, which is typically stored in the student profile.
        # But for simplicity in this migration, assume user_id is linked to student_id or they can only query their own records.
        # Let's get the student profile by user_id
        student = db.query(crud.models.Student).filter(crud.models.Student.user_id == current_user.user_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Student profile not found")
        return crud.get_exam_results_for_student(db, student_id=student.id)
    
    # For other roles, return all (in a real app, paginate this)
    return db.query(crud.models.ExamResult).limit(100).all()

@router.post("/", response_model=schemas.ExamResultResponse, status_code=status.HTTP_201_CREATED)
def create_exam_result(
    result: schemas.ExamResultCreate, 
    db: Session = Depends(get_db),
    current_user: schemas.TokenData = Depends(auth.get_current_user)
):
    """
    Create a new exam result. Only faculty/hod/admin can do this.
    """
    if current_user.role == "student":
        raise HTTPException(status_code=403, detail="Students cannot upload results")
    return crud.create_exam_result(db, result=result, user_id=current_user.user_id)
