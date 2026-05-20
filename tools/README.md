# Import assets/data JSON into PostgreSQL

This folder contains `import_to_postgres.py` — a small utility that reads JSON files from `assets/data/` and imports them into PostgreSQL.

Quick start

1. Create and activate a Python virtualenv (recommended):

```bash
python -m venv .venv
.venv\Scripts\activate   # Windows
```

2. Install requirements:

```bash
pip install -r requirements.txt
```

3. Edit `.env` at project root to set `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, or set those env vars in your shell.

4. Run the importer (from project root):

```bash
python tools/import_to_postgres.py --data-dir assets/data
```

The script will create one table per JSON file (table name = filename) with `id TEXT PRIMARY KEY` and `payload JSONB`.
