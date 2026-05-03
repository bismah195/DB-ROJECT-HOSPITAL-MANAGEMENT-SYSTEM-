🏥 MediCore HMS
A production-grade Hospital Management System · CS-2005 Database Systems · FAST NUCES Karachi
MediCore is a full-stack web application that demonstrates advanced database concepts through a real-world hospital workflow. The frontend is a single-page app with 13 modules, the backend is a REST API in Flask, and all data lives in Oracle XE with triggers, stored procedures, and concurrency constraints enforced at the database level.

✨ Features

Role-Based Access Control — Admin, Doctor, Nurse, and Accountant roles each see a tailored interface
Patient Management — Full CRUD, paginated registry, and per-patient medical history timeline
Appointments — Book, filter by status, and update in real-time with double-booking prevention
Pharmacy & Inventory — Live stock levels with automatic low-stock alerts fired by an Oracle trigger
Lab Tests — Order tests and enter results directly from the UI
Billing & Invoices — Create invoices, track payments, print receipts, and export to CSV
Insurance Claims — Track claim lifecycle from Submitted → Approved → Paid
Room Availability — Live occupancy grid with color-coded capacity indicators
Analytics Dashboard — Charts for doctor workload, payment status, and medicine usage
Concurrency Control Demo — Visual simulation of SELECT FOR UPDATE blocking between two sessions
Audit Log — Every INSERT and UPDATE performed through the UI is recorded client-side
Dark Mode — Full light/dark theme toggle
Global Search — Instant search across patients and doctors


🛠 Tech Stack
LayerTechnologyFrontendHTML5, CSS3, Vanilla JavaScript (single file, no frameworks)BackendPython 3, Flask, Flask-CORSDatabaseOracle XE 11g / 21cORM / Driveroracledb (python-oracledb, thick mode)

🗄 Database Concepts Demonstrated

Triggers — trg_stock_alert fires automatically when medicine stock drops below threshold
Stored Procedures — PROC_PATIENT_DISCHARGE handles cascading updates across appointment, room, and invoice tables
Concurrency Control — SELECT FOR UPDATE with uq_doctor_timeslot constraint prevents double-booking under concurrent load
Views & Joins — Multi-table queries across patient, doctor, department, appointment, invoice, and lab_test
Sequences & Constraints — Primary keys, foreign keys, unique constraints enforced at DB level


🚀 Getting Started
Prerequisites

Oracle XE installed and running on localhost:1521
Python 3.9+
Oracle Instant Client (for thick mode)

Installation
bash# Clone the repo
git clone https://github.com/YOUR_USERNAME/DB-PROJECT-HOSPITAL-MANAGEMENT-SYSTEM.git
cd medicore-hms

# Install Python dependencies
pip install flask flask-cors oracledb

# Configure your Oracle credentials in app.py
DB_USER = "hr"
DB_PASS = "hr"
DB_DSN  = "localhost:1521/XE"

# Start the backend
python project12.py

# Open the frontend
# Just open medicore.html in your browser — no build step needed

📁 Project Structure

medicore-hms/
├── latestweb.html      # Entire frontend — single file SPA
├── project12.py             # Flask REST API — all 20+ endpoints
├── dbfinal.sql         # Oracle DDL — tables, sequences, constraints    
└── README.md

👨‍💻 Authors
Built as a semester project for CS-2005 Database Systems at FAST NUCES Karachi.
