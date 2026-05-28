import os
import sys

# Add the current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import engine, Base
import models

def init_db():
    try:
        # Create all tables in the database
        Base.metadata.create_all(bind=engine)
        print("Database schema successfully created!")
        
        # Verify tables
        from sqlalchemy import inspect
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        print(f"Created tables: {tables}")
        
    except Exception as e:
        print(f"Error creating database: {e}")

if __name__ == "__main__":
    init_db()
