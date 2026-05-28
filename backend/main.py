from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from routers import auth, departments, courses, students, attendance, results, assignments, timetable, notifications, seed

limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])
app = FastAPI(title="KSRCE ERP API")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Configure CORS for Flutter frontend
origins = [
    "http://localhost",
    "http://localhost:8080",
    "http://localhost:3000",
    "http://localhost:5000",
    # Allow the specific Flutter web port during development
    "*" 
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
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
app.include_router(seed.router)

@app.get("/")
@limiter.limit("5/minute")
def read_root(request: Request):
    return {"message": "Welcome to the KSRCE ERP Backend API!"}
