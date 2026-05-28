"""
Reads II CSE(IOT).xlsx and POSTs all students to the live Render API seed endpoint.
Run: python send_students.py
"""
import json
import urllib.request
import urllib.error
import pandas as pd

EXCEL_PATH = r"d:\Admin\college\II CSE(IOT).xlsx"
API_URL = "https://ksrce-erp-app.onrender.com/admin/seed"
SEED_SECRET = "ksrce-seed-2024"
DEPARTMENT = "CSE(IOT)"
YEAR = "II"

def main():
    print("Reading Excel file...")
    df = pd.read_excel(EXCEL_PATH, header=3)
    df = df.dropna(subset=["Register Number"])

    students = []
    for _, row in df.iterrows():
        reg_no = str(row["Register Number"]).replace(".0", "").strip()
        if not reg_no or reg_no == "nan":
            continue

        name = str(row["Name of the Student"]).strip()
        initial = str(row.get("Initial of the Student", "")).strip()
        full_name = f"{name} {initial}" if initial and initial != "nan" else name

        email = str(row.get("Student domain email id", "")).strip()
        if not email or email == "nan":
            email = str(row.get("Student Personal mail ifd", "")).strip()
        if not email or email == "nan":
            email = f"{reg_no.lower()}@ksrce.ac.in"

        phone = str(row.get("Student Number", "")).replace(".0", "").strip()
        if phone == "nan":
            phone = ""

        students.append({
            "roll_number": reg_no,
            "full_name": full_name,
            "email": email.lower(),
            "phone": phone,
            "department": DEPARTMENT,
            "year": YEAR,
            "section": "A"
        })

    print(f"Found {len(students)} students. Sending to API...")

    payload = json.dumps({
        "secret": SEED_SECRET,
        "students": students
    }).encode("utf-8")

    req = urllib.request.Request(
        API_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            result = json.loads(response.read().decode("utf-8"))
            print(f"\n✅ SUCCESS!")
            print(f"   Added:   {result['added']} students")
            print(f"   Skipped: {result['skipped']} students (already existed)")
            print(f"   Default password: {result['default_password']}")
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        print(f"\n❌ HTTP Error {e.code}: {body}")
    except Exception as ex:
        print(f"\n❌ Error: {ex}")

if __name__ == "__main__":
    main()
