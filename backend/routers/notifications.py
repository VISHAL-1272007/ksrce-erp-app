from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import crud, schemas, auth

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/", response_model=List[schemas.NotificationResponse])
def get_my_notifications(
    db: Session = Depends(get_db),
    current_user: schemas.TokenData = Depends(auth.get_current_user),
):
    """
    Returns all notifications belonging to the currently authenticated user,
    newest first (max 100).
    """
    return crud.get_notifications_for_user(db, user_id=current_user.user_id)


@router.post("/", response_model=schemas.NotificationResponse, status_code=status.HTTP_201_CREATED)
def create_notification(
    notif: schemas.NotificationCreate,
    db: Session = Depends(get_db),
    current_user: schemas.TokenData = Depends(auth.get_current_user),
):
    """
    Send a notification to a specific user.
    Only admin, hod, and faculty can create notifications.
    """
    if current_user.role not in ["admin", "hod", "faculty"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admin, HOD, or faculty can send notifications.",
        )
    return crud.create_notification(db, notif=notif, creator_id=current_user.user_id)


@router.put("/{notification_id}/read", response_model=schemas.NotificationResponse)
def mark_as_read(
    notification_id: str,
    db: Session = Depends(get_db),
    current_user: schemas.TokenData = Depends(auth.get_current_user),
):
    """Mark a notification as read. Users can only mark their own notifications."""
    notif = crud.mark_notification_read(db, notif_id=notification_id, user_id=current_user.user_id)
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found.")
    return notif


@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_notification(
    notification_id: str,
    db: Session = Depends(get_db),
    current_user: schemas.TokenData = Depends(auth.get_current_user),
):
    """Delete a notification. Users can only delete their own notifications."""
    notif = crud.delete_notification(db, notif_id=notification_id, user_id=current_user.user_id)
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found.")
