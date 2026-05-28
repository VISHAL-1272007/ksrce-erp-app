from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import crud, schemas, auth

router = APIRouter(prefix="/timetable", tags=["timetable"])

@router.get("/", response_model=List[schemas.TimetableResponse])
def get_timetable(
    department_id: str = None,
    db: Session = Depends(get_db), 
    current_user: schemas.TokenData = Depends(auth.get_current_user)
):
    """
    Get timetable. Optionally filter by department_id.
    """
    if department_id:
        return crud.get_timetable_by_department(db, department_id=department_id)
    return db.query(crud.models.Timetable).limit(100).all()

@router.post("/", response_model=schemas.TimetableResponse, status_code=status.HTTP_201_CREATED)
def create_timetable(
    timetable: schemas.TimetableCreate, 
    db: Session = Depends(get_db),
    current_user: schemas.TokenData = Depends(auth.get_current_user)
):
    """
    Create a new timetable entry. Only admin/hod can do this.
    """
    if current_user.role not in ["admin", "hod"]:
        raise HTTPException(status_code=403, detail="Not authorized to create timetable entries")
    return crud.create_timetable(db, timetable=timetable, creator_id=current_user.user_id)
