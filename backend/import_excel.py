import os
import sys
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from passlib.context import CryptContext
import math

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from models import Base, User, Student

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def import_students(excel_path: str, db_url: str):
    print(f"Connecting to database: {db_url.split('@')[1] if '@' in db_url else db_url}")
    engine = create_engine(db_url)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    # Read excel skipping first 3 rows
    df = pd.read_excel(excel_path, header=3)
    
    # Drop rows where 'Register Number' is NaN
    df = df.dropna(subset=['Register Number'])

    default_password = "ksrce"
    hashed_pwd = get_password_hash(default_password)
    
    # Parse file name for year/dept
    filename = os.path.basename(excel_path)
    # Example: "II CSE(IOT).xlsx"
    year = filename.split(' ')[0] if ' ' in filename else "II"
    department = filename.replace(year, "").replace(".xlsx", "").strip() or "CSE(IOT)"

    added_count = 0
    for index, row in df.iterrows():
        reg_no = str(row['Register Number']).replace('.0', '').strip()
        if not reg_no or reg_no == 'nan':
            continue

        name = str(row['Name of the Student']).strip()
        initial = str(row.get('Initial of the Student', '')).strip()
        if initial and initial != 'nan':
            full_name = f"{name} {initial}"
        else:
            full_name = name

        email = str(row.get('Student domain email id', '')).strip()
        if not email or email == 'nan':
            email = str(row.get('Student Personal mail ifd', '')).strip()
        if not email or email == 'nan':
            email = f"{reg_no}@ksrce.ac.in"

        phone = str(row.get('Student Number', '')).replace('.0', '').strip()
        if phone == 'nan':
            phone = ""

        # Check if user already exists
        existing_user = db.query(User).filter((User.email == email)).first()
        existing_student = db.query(Student).filter(Student.roll_number == reg_no).first()

        if existing_student or existing_user:
            print(f"Skipping {reg_no} - already exists in database.")
            continue

        # Create User
        user = User(
            email=email.lower(),
            full_name=full_name,
            password_hash=hashed_pwd,
            role="student"
        )
        db.add(user)
        db.flush() # To get user.id

        # Create Student profile
        student = Student(
            user_id=user.id,
            roll_number=reg_no,
            department=department,
            year=year,
            section="A", # Default section
            phone_number=phone
        )
        db.add(student)
        added_count += 1
        print(f"Added {reg_no}: {full_name}")

    db.commit()
    print(f"\n✅ Successfully imported {added_count} students to the database!")
    print(f"Default password for all imported students is: {default_password}")
    db.close()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python import_excel.py <path_to_excel> <database_url>")
        sys.exit(1)
    
    excel_file = sys.argv[1]
    db_conn_str = sys.argv[2]
    import_students(excel_file, db_conn_str)
