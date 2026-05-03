"""
MediCore HMS - Flask Backend

Uses: oracledb (replaces cx_Oracle, works on Python 3.14)
Install: pip install flask flask-cors oracledb
Run: python project12.py
"""
from flask import Flask, jsonify, request
from flask_cors import CORS
import oracledb
from datetime import datetime, date

app = Flask(__name__)
CORS(app)

# ───────────────────────────────────────────────
# ORACLE CONNECTION CONFIGURATION
# ───────────────────────────────────────────────
DB_USER = "hr"
DB_PASS = "hr"
DB_DSN  = "localhost:1521/XE"

# Initialize thick mode (uses Oracle client)
try:
    oracledb.init_oracle_client(lib_dir=r"C:\oraclexe\app\oracle\product\11.2.0\server\bin")
except Exception as e:
    print(f"Warning: Could not initialize thick mode: {e}")

def get_conn():
    """Create and return an Oracle database connection."""
    return oracledb.connect(user=DB_USER, password=DB_PASS, dsn=DB_DSN)

def to_dict(cursor, row):
    """Convert database row to dictionary with proper type handling."""
    cols = [c[0].lower() for c in cursor.description]
    result = {}
    for col, val in zip(cols, row):
        if isinstance(val, (datetime, date)):
            result[col] = str(val)
        elif hasattr(val, 'read'):  # LOB / CLOB
            result[col] = val.read() if val else None
        else:
            result[col] = val
    return result

# ───────────────────────────────────────────────
# HEALTH CHECK
# ───────────────────────────────────────────────
@app.route("/api/health")
def health():
    """Check database connectivity."""
    try:
        conn = get_conn()
        conn.close()
        return jsonify({"status": "connected", "user": DB_USER, "dsn": DB_DSN})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# ───────────────────────────────────────────────
# DASHBOARD STATS
# ───────────────────────────────────────────────
@app.route("/api/stats")
def stats():
    """Fetch dashboard statistics."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        def count(sql):
            cur.execute(sql)
            return cur.fetchone()[0]
        data = {
            "total_patients":     count("SELECT COUNT(*) FROM patient"),
            "total_doctors":      count("SELECT COUNT(*) FROM doctor"),
            "total_appointments": count("SELECT COUNT(*) FROM appointment"),
            "unpaid_invoices":    count("SELECT COUNT(*) FROM invoice WHERE payment_status='Unpaid'"),
            "low_stock_alerts":   count("SELECT COUNT(*) FROM alerts WHERE resolved=0"),
            "total_departments":  count("SELECT COUNT(*) FROM department"),
        }
        cur.close()
        conn.close()
        return jsonify(data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ───────────────────────────────────────────────
# PATIENTS
# ───────────────────────────────────────────────
@app.route("/api/patients", methods=["GET"])
def get_patients():
    """Retrieve all patients."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            SELECT patient_id, name, TO_CHAR(dob,'YYYY-MM-DD') AS dob,
                   blood_group, phone, email,
                   emergency_contact_name, emergency_contact_phone
            FROM patient ORDER BY name
        """)
        rows = [to_dict(cur, r) for r in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/patients", methods=["POST"])
def add_patient():
    """Add a new patient."""
    try:
        d = request.json
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO patient
                  (name, dob, blood_group, phone, email, address,
                   emergency_contact_name, emergency_contact_phone)
            VALUES (:1, TO_DATE(:2,'YYYY-MM-DD'), :3, :4, :5, :6, :7, :8)
        """, (d["name"], d["dob"], d["blood_group"], d["phone"],
              d.get("email"), d.get("address"),
              d["emergency_contact_name"], d["emergency_contact_phone"]))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Patient added successfully"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ───────────────────────────────────────────────
# DOCTORS
# ───────────────────────────────────────────────
@app.route("/api/doctors")
def get_doctors():
    """Retrieve all doctors."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            SELECT d.doctor_id, d.name, d.specialization,
                   d.license_no, d.phone, d.email, dep.dept_name
            FROM doctor d JOIN department dep ON d.dept_id = dep.dept_id
            ORDER BY dep.dept_name, d.name
        """)
        rows = [to_dict(cur, r) for r in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ───────────────────────────────────────────────
# DEPARTMENTS
# ───────────────────────────────────────────────
@app.route("/api/departments")
def get_departments():
    """Retrieve all departments."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            SELECT dep.dept_id, dep.dept_name, dep.floor_no,
                   d.name AS head_doctor
            FROM department dep LEFT JOIN doctor d ON dep.head_doctor_id = d.doctor_id
            ORDER BY dep.dept_name
        """)
        rows = [to_dict(cur, r) for r in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ───────────────────────────────────────────────
# APPOINTMENTS
# ───────────────────────────────────────────────
@app.route("/api/appointments")
def get_appointments():
    """Retrieve all appointments."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            SELECT a.appointment_id, p.name AS patient_name,
                   d.name AS doctor_name, d.specialization, r.room_type,
                   TO_CHAR(a.appt_datetime,'YYYY-MM-DD HH24:MI') AS appt_datetime,
                   a.appointment_type, a.status, a.notes
            FROM appointment a
            JOIN patient p ON a.patient_id = p.patient_id
            JOIN doctor d ON a.doctor_id = d.doctor_id
            LEFT JOIN room r ON a.room_id = r.room_id
            ORDER BY a.appt_datetime DESC
        """)
        rows = [to_dict(cur, r) for r in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ───────────────────────────────────────────────
# MEDICINES
# ───────────────────────────────────────────────
@app.route("/api/medicines")
def get_medicines():
    """Retrieve all medicines with stock status."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            SELECT mi.medicine_id, mi.medicine_name,
                   mi.quantity_available, mi.minimum_threshold,
                   mi.unit, mi.unit_price, s.company_name AS supplier,
                   CASE WHEN mi.quantity_available < mi.minimum_threshold
                        THEN 'LOW' ELSE 'OK' END AS stock_status
            FROM medicine_inventory mi
            JOIN supplier s ON mi.supplier_id = s.supplier_id
            ORDER BY mi.medicine_name
        """)
        rows = [to_dict(cur, r) for r in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ───────────────────────────────────────────────
# LAB TESTS
# ───────────────────────────────────────────────
@app.route("/api/labtests")
def get_labtests():
    """Retrieve all lab tests."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            SELECT lt.test_id, p.name AS patient_name,
                   d.name AS ordered_by, lt.test_name, lt.status,
                   TO_CHAR(lt.result_date,'YYYY-MM-DD') AS result_date
            FROM lab_test lt
            JOIN patient p ON lt.patient_id = p.patient_id
            JOIN doctor d ON lt.ordered_by = d.doctor_id
            ORDER BY lt.created_at DESC
        """)
        rows = [to_dict(cur, r) for r in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ───────────────────────────────────────────────
# INVOICES
# ───────────────────────────────────────────────
@app.route("/api/invoices")
def get_invoices():
    """Retrieve all invoices."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            SELECT i.invoice_id, p.name AS patient_name,
                   TO_CHAR(i.issue_date,'YYYY-MM-DD') AS issue_date,
                   TO_CHAR(i.due_date,'YYYY-MM-DD') AS due_date,
                   i.total_amount, i.amount_paid,
                   (i.total_amount - i.amount_paid) AS balance_due,
                   i.payment_status
            FROM invoice i JOIN patient p ON i.patient_id = p.patient_id
            ORDER BY i.issue_date DESC
        """)
        rows = [to_dict(cur, r) for r in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ───────────────────────────────────────────────
# ALERTS
# ───────────────────────────────────────────────
@app.route("/api/alerts")
def get_alerts():
    """Retrieve all alerts."""
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            SELECT al.alert_id, mi.medicine_name,
                   TO_CHAR(al.triggered_at,'YYYY-MM-DD HH24:MI') AS triggered_at,
                   al.alert_message, al.resolved
            FROM alerts al
            JOIN medicine_inventory mi ON al.medicine_id = mi.medicine_id
            ORDER BY al.triggered_at DESC
        """)
        rows = [to_dict(cur, r) for r in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ───────────────────────────────────────────────

if __name__ == "__main__":
    print("=" * 50)
    print(" MediCore HMS Backend")
    print(f" Oracle: {DB_USER}@{DB_DSN}")
    print(" URL: http://localhost:5000")
    print("=" * 50)
    app.run(debug=True, port=5000)