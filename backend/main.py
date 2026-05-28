from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from routers import auth, departments, courses, students, attendance, results, assignments, timetable, notifications
from routers.seed import seed_router, admin_router
from database import Base, engine
import models

# Create tables if they do not exist
Base.metadata.create_all(bind=engine)

limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])
app = FastAPI(title="KSRCE ERP API")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Configure CORS for Flutter frontend
origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(departments.router)
app.include_router(courses.router)
app.include_router(students.router)
app.include_router(attendance.router)
app.include_router(results.router)
app.include_router(assignments.router)
app.include_router(timetable.router)
app.include_router(notifications.router)
app.include_router(seed_router)
app.include_router(admin_router)

@app.get("/")
@limiter.limit("5/minute")
def read_root(request: Request):
    return {"message": "Welcome to the KSRCE ERP Backend API!"}
