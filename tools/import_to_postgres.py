#!/usr/bin/env python3
"""Import JSON files from assets/data into PostgreSQL.

Creates one table per JSON file (table name = filename stem) with columns:
- id TEXT PRIMARY KEY
- payload JSONB

Usage:
  python tools/import_to_postgres.py --data-dir assets/data

DB connection is read from environment variables or a .env file:
  PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
"""
from pathlib import Path
import json
import os
import uuid
import argparse

try:
    import psycopg2
    from psycopg2.extras import Json
except Exception as e:
    print("Missing dependency psycopg2. Install from requirements.txt")
    raise

try:
    from dotenv import load_dotenv
except Exception:
    def load_dotenv(path=None):
        return


KEY_CANDIDATES = [
    'id', '_id', 'uid', 'userId', 'studentId', 'facultyId', 'code', 'uuid'
]


def pick_id(obj):
    if not isinstance(obj, dict):
        return None
    for k in KEY_CANDIDATES:
        if k in obj and obj[k] is not None:
            return str(obj[k])
    return None


def ensure_table(conn, table_name):
    with conn.cursor() as cur:
        cur.execute(f"""
        CREATE TABLE IF NOT EXISTS {psycopg2.extensions.AsIs(table_name)} (
            id TEXT PRIMARY KEY,
            payload JSONB NOT NULL
        )
        """)
    conn.commit()


def insert_row(conn, table_name, row_id, payload):
    with conn.cursor() as cur:
        cur.execute(
            f"INSERT INTO {psycopg2.extensions.AsIs(table_name)} (id, payload) VALUES (%s, %s) "
            "ON CONFLICT (id) DO UPDATE SET payload = EXCLUDED.payload",
            (row_id, Json(payload)),
        )
    conn.commit()


def sanitize_table_name(name: str) -> str:
    # lower-case and replace invalid chars with underscore
    return ''.join(c if c.isalnum() else '_' for c in name).lower()


def import_folder(data_dir: Path, conn):
    files = sorted(data_dir.glob('*.json'))
    if not files:
        print(f"No JSON files found in {data_dir}")
        return
    for f in files:
        table = sanitize_table_name(f.stem)
        print(f"Processing {f.name} -> table '{table}'")
        ensure_table(conn, table)
        with f.open('r', encoding='utf-8') as fh:
            data = json.load(fh)
            if isinstance(data, list):
                for obj in data:
                    rid = pick_id(obj) or str(uuid.uuid4())
                    insert_row(conn, table, rid, obj)
            elif isinstance(data, dict):
                rid = pick_id(data) or 'root'
                insert_row(conn, table, rid, data)
            else:
                # primitive value --> wrap
                rid = str(uuid.uuid4())
                insert_row(conn, table, rid, {'value': data})
        print(f"  -> imported from {f.name}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data-dir', default='assets/data', help='Path to JSON data folder')
    parser.add_argument('--db-url', default=None, help='Optional: full postgres DSN, e.g. postgres://user:pass@host:5432/db')
    args = parser.parse_args()

    # load .env if present
    load_dotenv()

    if args.db_url:
        dsn = args.db_url
    else:
        host = os.environ.get('PGHOST', 'localhost')
        port = os.environ.get('PGPORT', '5432')
        db = os.environ.get('PGDATABASE', 'college')
        user = os.environ.get('PGUSER', 'postgres')
        pwd = os.environ.get('PGPASSWORD', '')
        dsn = f"host={host} port={port} dbname={db} user={user} password={pwd}"

    data_dir = Path(args.data_dir)
    if not data_dir.exists():
        print(f"Data directory not found: {data_dir}")
        return

    print("Connecting to Postgres...")
    conn = psycopg2.connect(dsn)
    try:
        import_folder(data_dir, conn)
    finally:
        conn.close()
        print("Done.")


if __name__ == '__main__':
    main()
