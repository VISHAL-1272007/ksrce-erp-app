from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import crud, schemas, auth

router = APIRouter(prefix="/assignments", tags=["assignments"])

@router.get("/", response_model=List[schemas.AssignmentResponse])
def get_assignments(
    course_id: str = None,
    db: Session = Depends(get_db), 
    current_user: schemas.TokenData = Depends(auth.get_current_user)
):
    """
    Get assignments. Optionally filter by course_id.
    """
    if course_id:
        return crud.get_assignments_by_course(db, course_id=course_id)
    return db.query(crud.models.Assignment).limit(100).all()

@router.post("/", response_model=schemas.AssignmentResponse, status_code=status.HTTP_201_CREATED)
def create_assignment(
    assignment: schemas.AssignmentCreate, 
    db: Session = Depends(get_db),
    current_user: schemas.TokenData = Depends(auth.get_current_user)
):
    """
    Create a new assignment. Only faculty/hod/admin can do this.
    """
    if current_user.role == "student":
        raise HTTPException(status_code=403, detail="Students cannot create assignments")
    return crud.create_assignment(db, assignment=assignment, creator_id=current_user.user_id)

@router.get("/{assignment_id}/submissions", response_model=List[schemas.SubmissionResponse])
def get_submissions(
    assignment_id: str,
    db: Session = Depends(get_db),
    current_user: schemas.TokenData = Depends(auth.get_current_user)
):
    if current_user.role == "student":
        # Students should only see their own submissions
        # Fetch the student ID first
        student = db.query(crud.models.Student).filter(crud.models.Student.user_id == current_user.user_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Student profile not found")
        submissions = crud.get_submissions_by_assignment(db, assignment_id=assignment_id)
        return [s for s in submissions if s.student_id == student.id]
    
    return crud.get_submissions_by_assignment(db, assignment_id=assignment_id)

@router.post("/{assignment_id}/submissions", response_model=schemas.SubmissionResponse, status_code=status.HTTP_201_CREATED)
def create_submission(
    assignment_id: str,
    submission: schemas.SubmissionCreate,
    db: Session = Depends(get_db),
    current_user: schemas.TokenData = Depends(auth.get_current_user)
):
    """
    Submit an assignment.
    """
    if submission.assignment_id != assignment_id:
        raise HTTPException(status_code=400, detail="Assignment ID mismatch")
        
    return crud.create_submission(db, submission=submission)
