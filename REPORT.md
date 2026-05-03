# 🏥 MediCore HMS — Project Report

**Hospital Management System · Database Project Technical Report**

| | |
|---|---|
| **Course** | CS-2005 Database Systems |
| **Instructor** | Talha Shahid |
| **Institution** | FAST NUCES Karachi |
| **DBMS** | Oracle Database XE 11.2 |
| **Year** | 2025 |

---

## 👥 Team Members

| Name | Roll No |
|------|---------|
| Bismah Sheikh | 24K-0795 |
| Filza Tanweer | 24K-0708 |
| Fatima Haider | 24K-0551 |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Database Schema — Tables](#2-database-schema--tables)
3. [Sequences](#3-sequences)
4. [Triggers](#4-triggers)
5. [Stored Procedures](#5-stored-procedures)
6. [Views — RBAC Access Control](#6-views--rbac-access-control)
7. [Entity-Relationship Model](#7-entity-relationship-model)
8. [Performance Indexes](#8-performance-indexes)
9. [Concurrency Control](#9-concurrency-control)
10. [Advanced SQL Queries](#10-advanced-sql-queries)
11. [Seed Data Summary](#11-seed-data-summary)
12. [Flask REST API — Endpoint Summary](#12-flask-rest-api--endpoint-summary)

---

## 1. Executive Summary

MediCore HMS is a fully functional Hospital Management System built on Oracle Database XE, featuring a Python Flask REST API backend and a responsive single-page web frontend. The system manages the complete patient lifecycle — from registration and appointment booking through clinical consultation, pharmacy dispensing, laboratory testing, and discharge — with every operation backed by ACID-compliant Oracle transactions.

The database design follows strict **Third Normal Form (3NF)** and **Boyce-Codd Normal Form (BCNF)**, with referential integrity enforced through foreign key constraints, CHECK constraints, and UNIQUE constraints at the database level.

The system demonstrates advanced database concepts including:
- Stored procedures with ACID transactions and SAVEPOINTs
- BEFORE INSERT triggers for sequence-based auto-increment
- AFTER UPDATE trigger for automated low-stock alerting
- Role-based access control via SQL views
- Optimistic and pessimistic concurrency control

**Technology Stack:** Oracle XE 11.2 · Python 3 + Flask · HTML/CSS/JS

---

## 2. Database Schema — Tables

The MediCore HMS schema consists of **14 tables** organised across four logical groups: core entities, operational entities, junction/detail tables, and system tables. All primary keys are populated via BEFORE INSERT triggers using Oracle sequences, replacing the PostgreSQL SERIAL pattern.

---

### 2.1 Independent / Core Tables

#### `patient`
The central entity of the system. Stores all registered patients with personal information, blood group, contact details, and emergency contact information.

| Column | Type | Constraint / Notes |
|--------|------|-------------------|
| `patient_id` | NUMBER | PRIMARY KEY — assigned by `seq_patient` via `trg_patient_bi` |
| `name` | VARCHAR2(120) | NOT NULL |
| `dob` | DATE | NOT NULL |
| `blood_group` | VARCHAR2(3) | CHECK IN `('A+','A-','B+','B-','AB+','AB-','O+','O-')` |
| `phone` | VARCHAR2(20) | NOT NULL UNIQUE |
| `email` | VARCHAR2(150) | UNIQUE (nullable) |
| `address` | CLOB | Nullable long-form address |
| `emergency_contact_name` | VARCHAR2(120) | NOT NULL |
| `emergency_contact_phone` | VARCHAR2(20) | NOT NULL |
| `created_at` | TIMESTAMP | DEFAULT SYSTIMESTAMP |

#### `supplier`
Stores pharmaceutical suppliers with contact and lead-time information. Each medicine in the inventory references a supplier.

| Column | Type / Constraint |
|--------|------------------|
| `supplier_id` | NUMBER — PK (`seq_supplier`) |
| `company_name` | VARCHAR2(200) NOT NULL |
| `contact_phone` | VARCHAR2(20) NOT NULL |
| `email` | VARCHAR2(150) UNIQUE |
| `lead_time_days` | NUMBER(5) CHECK >= 0 |
| `created_at` | TIMESTAMP DEFAULT SYSTIMESTAMP |

---

### 2.2 First-Level FK Dependent Tables

#### `department`
Represents hospital departments (Cardiology, Neurology, Orthopaedics, Gynaecology, Emergency Medicine). The `head_doctor_id` foreign key creates a circular dependency with the doctor table and is therefore added via `ALTER TABLE` after the doctor table is created.

| Column | Type / Constraint |
|--------|------------------|
| `dept_id` | NUMBER — PK (`seq_department`) |
| `dept_name` | VARCHAR2(100) NOT NULL UNIQUE |
| `floor_no` | NUMBER(5) NOT NULL CHECK >= 0 |
| `head_doctor_id` | FK → `doctor(doctor_id)` ON DELETE SET NULL — added via ALTER TABLE |

#### `doctor`
Stores all medical staff with specialization and license information. Each doctor belongs to exactly one department.

| Column | Type / Constraint |
|--------|------------------|
| `doctor_id` | NUMBER — PK (`seq_doctor`) |
| `name` | VARCHAR2(120) NOT NULL |
| `specialization` | VARCHAR2(100) NOT NULL |
| `license_no` | VARCHAR2(50) NOT NULL UNIQUE — PMDC license |
| `phone` | VARCHAR2(20) NOT NULL UNIQUE |
| `email` | VARCHAR2(150) UNIQUE |
| `dept_id` | FK → `department(dept_id)` ON DELETE SET NULL |
| `created_at` | TIMESTAMP DEFAULT SYSTIMESTAMP |

#### `medicine_inventory`
Tracks pharmacy stock with quantity, minimum threshold, unit pricing, and supplier linkage. The `quantity_available` CHECK constraint prevents negative stock. The `low_stock_alert` trigger fires automatically whenever quantity drops below the minimum threshold.

| Column | Type / Constraint |
|--------|------------------|
| `medicine_id` | NUMBER — PK (`seq_medicine`) |
| `supplier_id` | FK → `supplier(supplier_id)` NOT NULL |
| `medicine_name` | VARCHAR2(200) NOT NULL |
| `quantity_available` | NUMBER(10) DEFAULT 0 CHECK >= 0 |
| `minimum_threshold` | NUMBER(10) DEFAULT 10 CHECK >= 0 |
| `unit` | VARCHAR2(30) CHECK IN (tablets, capsules, ml, mg, vials, ampoules, sachets, patches, units) |
| `unit_price` | NUMBER(10,2) CHECK >= 0 |
| `created_at` | TIMESTAMP DEFAULT SYSTIMESTAMP |

---

### 2.3 Second-Level FK Dependent Tables

#### `room`
Models hospital rooms with capacity and live occupancy tracking. A CHECK constraint enforces `current_occupancy <= capacity` at the database level.

| Column | Type / Constraint |
|--------|------------------|
| `room_id` | NUMBER — PK (`seq_room`) |
| `dept_id` | FK → `department(dept_id)` NOT NULL |
| `room_type` | CHECK IN (General Ward, ICU, Operating Theatre, Consultation, Recovery, Emergency, Lab) |
| `capacity` | NUMBER(5) CHECK > 0 |
| `current_occupancy` | NUMBER(5) DEFAULT 0 CHECK >= 0 |
| *(constraint)* | `chk_occupancy_capacity`: `current_occupancy <= capacity` |

#### `staff`
Non-medical hospital staff assigned to departments. Role and shift are both constrained via CHECK to specific valid values.

| Column | Type / Constraint |
|--------|------------------|
| `staff_id` | NUMBER — PK (`seq_staff`) |
| `dept_id` | FK → `department(dept_id)` NOT NULL |
| `name` | VARCHAR2(120) NOT NULL |
| `role` | CHECK IN (Nurse, Lab Technician, Receptionist, Pharmacist, Admin, Porter, Security) |
| `shift` | CHECK IN (Morning, Evening, Night) |
| `phone` | VARCHAR2(20) NOT NULL UNIQUE |
| `email` | VARCHAR2(150) UNIQUE |
| `created_at` | TIMESTAMP DEFAULT SYSTIMESTAMP |

#### `appointment`
The operational hub of the clinical system. Two UNIQUE composite constraints enforce double-booking prevention at the database level — no two appointments can share the same doctor and datetime, and no two can share the same room and datetime.

> This is the table locked by `SELECT FOR UPDATE` in the concurrency control demonstration.

| Column | Type / Constraint |
|--------|------------------|
| `appointment_id` | NUMBER — PK (`seq_appointment`) |
| `patient_id` | FK → `patient` ON DELETE CASCADE |
| `doctor_id` | FK → `doctor` NOT NULL |
| `room_id` | FK → `room` ON DELETE SET NULL (nullable) |
| `appt_datetime` | TIMESTAMP NOT NULL |
| `appointment_type` | CHECK IN (Consultation, Follow-up, Surgery, Emergency, Lab Visit, Imaging) |
| `status` | DEFAULT `'Scheduled'` CHECK IN (Scheduled, Confirmed, In Progress, Completed, Cancelled, No-Show) |
| `notes` | CLOB (nullable) |
| *(unique 1)* | `uq_doctor_timeslot`: UNIQUE(`doctor_id`, `appt_datetime`) |
| *(unique 2)* | `uq_room_timeslot`: UNIQUE(`room_id`, `appt_datetime`) |
| `created_at` | TIMESTAMP DEFAULT SYSTIMESTAMP |

---

### 2.4 Weak Entities

#### `prescription`
Existentially dependent on `appointment`. The UNIQUE constraint on `appointment_id` enforces one prescription per appointment. Cascade delete removes prescriptions when the parent appointment is deleted.

| Column | Type / Constraint |
|--------|------------------|
| `prescription_id` | NUMBER — PK (`seq_prescription`) |
| `appointment_id` | FK → `appointment` ON DELETE CASCADE — UNIQUE |
| `prescribed_date` | DATE DEFAULT SYSDATE |
| `notes` | CLOB (nullable) |

#### `invoice`
Existentially dependent on `patient`. The composite key (`patient_id`, `invoice_id`) forms the identifying key. A CHECK constraint prevents `amount_paid` from exceeding `total_amount`.

| Column | Type / Constraint |
|--------|------------------|
| `invoice_id` | NUMBER — PK (`seq_invoice`) |
| `patient_id` | FK → `patient` NOT NULL |
| `issue_date` | DATE DEFAULT SYSDATE |
| `due_date` | DATE (nullable) |
| `total_amount` | NUMBER(10,2) CHECK >= 0 |
| `amount_paid` | NUMBER(10,2) DEFAULT 0 CHECK >= 0 |
| `payment_status` | CHECK IN (Unpaid, Partially Paid, Paid, Waived, Disputed) |
| *(constraint)* | `chk_payment_not_exceed_total`: `amount_paid <= total_amount` |

---

### 2.5 Junction and Detail Tables

#### `prescription_detail`
Links prescriptions to medicines with dosage and quantity information. The UNIQUE constraint on (`prescription_id`, `medicine_id`) prevents the same medicine appearing twice in one prescription.

| Column | Type / Constraint |
|--------|------------------|
| `detail_id` | NUMBER — PK (`seq_presc_detail`) |
| `prescription_id` | FK → `prescription` ON DELETE CASCADE |
| `medicine_id` | FK → `medicine_inventory` |
| `dosage` | VARCHAR2(100) NOT NULL — e.g. `'75mg once daily'` |
| `duration_days` | NUMBER(5) CHECK > 0 |
| `quantity_issued` | NUMBER(10) CHECK > 0 |
| *(unique)* | `uq_medicine_per_prescription`: UNIQUE(`prescription_id`, `medicine_id`) |

#### `lab_test`
Records diagnostic tests ordered by doctors. Results are stored as CLOB to accommodate lengthy textual results.

| Column | Type / Constraint |
|--------|------------------|
| `test_id` | NUMBER — PK (`seq_lab_test`) |
| `patient_id` | FK → `patient` ON DELETE CASCADE |
| `ordered_by` | FK → `doctor` NOT NULL |
| `appointment_id` | FK → `appointment` ON DELETE SET NULL (nullable) |
| `test_name` | VARCHAR2(150) NOT NULL |
| `result` | CLOB (nullable) |
| `result_date` | DATE (nullable) |
| `status` | DEFAULT `'Pending'` CHECK IN (Pending, In Progress, Completed, Cancelled) |
| `created_at` | TIMESTAMP DEFAULT SYSTIMESTAMP |

#### `insurance_claim`
Manages insurance claims linked to invoices. The UNIQUE constraint on `invoice_id` enforces one claim per invoice.

| Column | Type / Constraint |
|--------|------------------|
| `claim_id` | NUMBER — PK (`seq_ins_claim`) |
| `invoice_id` | FK → `invoice` ON DELETE CASCADE — UNIQUE |
| `provider_name` | VARCHAR2(200) NOT NULL |
| `claim_amount` | NUMBER(10,2) CHECK > 0 |
| `claim_status` | CHECK IN (Submitted, Under Review, Approved, Partially Approved, Rejected, Paid) |
| `submitted_at` | TIMESTAMP DEFAULT SYSTIMESTAMP |
| `resolved_at` | TIMESTAMP (nullable) |
| *(constraint)* | `chk_claim_dates`: `resolved_at IS NULL OR resolved_at >= submitted_at` |

---

### 2.6 System Table

#### `alerts`
Automatically populated by the `low_stock_alert` Oracle trigger. This table is **never written to manually** — all inserts come from the trigger. The `resolved` column uses `NUMBER(1)` with `CHECK IN (0,1)` because Oracle 11g has no native BOOLEAN type.

| Column | Type / Constraint |
|--------|------------------|
| `alert_id` | NUMBER — PK (`seq_alerts`) |
| `medicine_id` | FK → `medicine_inventory` ON DELETE CASCADE |
| `triggered_at` | TIMESTAMP DEFAULT SYSTIMESTAMP |
| `alert_message` | CLOB NOT NULL — auto-generated by trigger |
| `resolved` | NUMBER(1) DEFAULT 0 CHECK IN (0,1) — `0`=false, `1`=true |
| `resolved_at` | TIMESTAMP (nullable) |
| *(constraint)* | `chk_alert_resolution`: `(resolved=0 AND resolved_at IS NULL) OR (resolved=1 AND resolved_at IS NOT NULL)` |

---

## 3. Sequences

Oracle 11g does not support the `IDENTITY` column syntax available in Oracle 12c+. To replicate PostgreSQL's `SERIAL` auto-increment behaviour, **14 sequences** were created — one per table.

> **Configuration for all sequences:** `START WITH 1  INCREMENT BY 1  NOCACHE  NOCYCLE`

| Sequence Name | Assigned To | Purpose |
|---------------|-------------|---------|
| `seq_patient` | `patient.patient_id` | Auto-increment patient IDs from 1 |
| `seq_supplier` | `supplier.supplier_id` | Auto-increment supplier IDs from 1 |
| `seq_department` | `department.dept_id` | Auto-increment department IDs from 1 |
| `seq_doctor` | `doctor.doctor_id` | Auto-increment doctor IDs from 1 |
| `seq_medicine` | `medicine_inventory.medicine_id` | Auto-increment medicine IDs from 1 |
| `seq_room` | `room.room_id` | Auto-increment room IDs from 1 |
| `seq_staff` | `staff.staff_id` | Auto-increment staff IDs from 1 |
| `seq_appointment` | `appointment.appointment_id` | Auto-increment appointment IDs |
| `seq_prescription` | `prescription.prescription_id` | Auto-increment prescription IDs |
| `seq_invoice` | `invoice.invoice_id` | Auto-increment invoice IDs from 1 |
| `seq_presc_detail` | `prescription_detail.detail_id` | Auto-increment detail row IDs |
| `seq_lab_test` | `lab_test.test_id` | Auto-increment lab test IDs from 1 |
| `seq_ins_claim` | `insurance_claim.claim_id` | Auto-increment claim IDs from 1 |
| `seq_alerts` | `alerts.alert_id` | Auto-increment alert IDs from 1 |

---

## 4. Triggers

MediCore HMS uses two categories of Oracle triggers: **14 BEFORE INSERT triggers** for automatic sequence-based primary key assignment, and **one AFTER UPDATE trigger** that implements the automated low-stock alerting system.

---

### 4.1 BEFORE INSERT Triggers (Primary Key Assignment)

Each of the 14 tables has a corresponding BEFORE INSERT trigger. The trigger fires before every INSERT and assigns the next sequence value to the primary key if it is NULL.

**Example — `trg_patient_bi`:**

```sql
CREATE OR REPLACE TRIGGER trg_patient_bi
BEFORE INSERT ON patient
FOR EACH ROW
BEGIN
    IF :NEW.patient_id IS NULL THEN
        SELECT seq_patient.NEXTVAL INTO :NEW.patient_id FROM DUAL;
    END IF;
    IF :NEW.created_at IS NULL THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
END;
```

This same pattern is replicated for all 14 tables:
`trg_supplier_bi`, `trg_department_bi`, `trg_doctor_bi`, `trg_medicine_bi`, `trg_room_bi`, `trg_staff_bi`, `trg_appointment_bi`, `trg_prescription_bi`, `trg_invoice_bi`, `trg_presc_detail_bi`, `trg_lab_test_bi`, `trg_ins_claim_bi`, `trg_alerts_bi`

---

### 4.2 AFTER UPDATE Trigger — `low_stock_alert`

This is the most significant trigger in the system. It fires automatically after any UPDATE to `quantity_available` in `medicine_inventory`. It compares the new and old values against `minimum_threshold` and inserts an alert record if stock has just crossed below the threshold for the **first time** (transitioning from above to below).

| Attribute | Detail |
|-----------|--------|
| **Fires when** | `NEW.quantity_available < NEW.minimum_threshold` AND `OLD.quantity_available >= OLD.minimum_threshold` |
| **Action** | INSERT INTO `alerts` with auto-generated descriptive message |
| **Used by** | `sp_dispense_medicine` stored procedure — fires automatically after the UPDATE |

```sql
CREATE OR REPLACE TRIGGER low_stock_alert
AFTER UPDATE OF quantity_available ON medicine_inventory
FOR EACH ROW
BEGIN
    IF :NEW.quantity_available < :NEW.minimum_threshold
       AND :OLD.quantity_available >= :OLD.minimum_threshold THEN
        INSERT INTO alerts (alert_id, medicine_id, alert_message)
        VALUES (
            seq_alerts.NEXTVAL,
            :NEW.medicine_id,
            'LOW STOCK: ' || :NEW.medicine_name ||
            ' has fallen to ' || :NEW.quantity_available ||
            ' ' || :NEW.unit ||
            ' (threshold: ' || :NEW.minimum_threshold || ').'
        );
    END IF;
END;
```

---

## 5. Stored Procedures

Five stored procedures encapsulate the core business logic. Each is called by the Flask API backend. Procedures include explicit error handling with `RAISE_APPLICATION_ERROR`, and procedures 2 and 5 demonstrate ACID-compliant transaction management using SAVEPOINTs.

---

### 5.1 `sp_book_appointment`

Books a new appointment after verifying no scheduling conflict exists. Provides a second layer of protection in addition to the UNIQUE constraints on the appointment table.

| Attribute | Detail |
|-----------|--------|
| **Parameters** | `p_patient_id`, `p_doctor_id`, `p_room_id`, `p_appt_datetime`, `p_appt_type` (all IN) |
| **Step 1** | `SELECT COUNT(*)` to check for doctor double-booking |
| **Step 2** | `SELECT COUNT(*)` to check for room double-booking |
| **Step 3** | `INSERT INTO appointment` if both checks pass |
| **On conflict** | `RAISE_APPLICATION_ERROR(-20001)` — doctor conflict · `(-20002)` — room conflict |
| **On failure** | `ROLLBACK + RAISE` to propagate error to Flask (returns HTTP 400) |
| **Called by** | `POST /api/appointments` |

---

### 5.2 `sp_process_billing`

The most complex procedure in the system. Creates an invoice and optionally an insurance claim in a single ACID transaction. SAVEPOINTs allow the invoice to be retained even if the insurance claim insert fails, demonstrating **partial rollback**.

| Attribute | Detail |
|-----------|--------|
| **Parameters** | `p_patient_id`, `p_total_amount`, `p_amount_paid`, `p_provider_name` (nullable), `p_claim_amount` |
| **SAVEPOINT 1** | `sp_before_invoice` — set before `INSERT INTO invoice` |
| **Invoice insert** | Determines payment status (Unpaid / Partially Paid / Paid) then inserts |
| **SAVEPOINT 2** | `sp_before_claim` — set before `INSERT INTO insurance_claim` |
| **Claim failure** | `ROLLBACK TO sp_before_claim` — claim undone but invoice retained |
| **Commit** | `COMMIT` finalises all retained changes |
| **Called by** | `POST /api/billing` |

---

### 5.3 `sp_dispense_medicine`

Safely deducts stock from `medicine_inventory` with pre-check validation. This procedure is the **trigger point** for `low_stock_alert` — the AFTER UPDATE trigger fires automatically after the UPDATE statement inside this procedure.

| Attribute | Detail |
|-----------|--------|
| **Parameters** | `p_medicine_id NUMBER IN`, `p_quantity NUMBER IN` |
| **Step 1** | `SELECT quantity_available` into local variable |
| **Step 2** | If available < requested: `RAISE_APPLICATION_ERROR(-20003)` — insufficient stock |
| **Step 3** | `UPDATE medicine_inventory SET quantity_available = quantity_available - p_quantity` |
| **Auto-trigger** | `low_stock_alert` fires AFTER the UPDATE if threshold crossed |
| **Exception** | `NO_DATA_FOUND` → `RAISE_APPLICATION_ERROR(-20004)` — medicine ID not found |
| **Called by** | `POST /api/dispense` |

---

### 5.4 `sp_resolve_alert`

Marks an alert as resolved. Validates the alert exists, updates the `resolved` flag to `1`, and sets `resolved_at` to `SYSTIMESTAMP`. `SQL%ROWCOUNT` is checked to ensure the alert ID was valid.

| Attribute | Detail |
|-----------|--------|
| **Parameters** | `p_alert_id NUMBER IN` |
| **Action** | `UPDATE alerts SET resolved=1, resolved_at=SYSTIMESTAMP WHERE alert_id=p_alert_id` |
| **Validation** | `IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20005)` |
| **Called by** | `POST /api/alerts/{id}/resolve` |

---

### 5.5 `PROC_PATIENT_DISCHARGE`

The most critical ACID procedure. Discharges a patient by atomically updating **three separate tables** in one transaction. If any single step fails, all changes are rolled back — demonstrating **Atomicity** and **Consistency**.

| Attribute | Detail |
|-----------|--------|
| **Parameters** | `p_patient_id NUMBER IN` |
| **Step 1** | `SELECT room_id` from the patient's most recent active appointment |
| **Step 2** | `UPDATE room SET current_occupancy = current_occupancy - 1` |
| **Step 3** | `UPDATE invoice SET payment_status='Paid'` for all unpaid invoices |
| **Step 4** | `UPDATE appointment SET status='Completed'` for all active appointments |
| **COMMIT** | All three updates committed atomically if all succeed |
| **ROLLBACK** | Full rollback on `NO_DATA_FOUND` or any `OTHERS` exception |
| **Called by** | `POST /api/discharge` |

---

## 6. Views — RBAC Access Control

MediCore HMS implements **Role-Based Access Control (RBAC) at the database level** using SQL views. Access control is enforced in Oracle itself, not just the application layer.

| View | Role | Exposes | Hides |
|------|------|---------|-------|
| `v_doctor_roster` | All | Doctor name, specialization, license, department | Financial data, patient records, personal contacts |
| `v_patient_privacy` | All | patient_id, name, dob, blood_group, email | phone, address, emergency contacts |
| `v_unpaid_invoices` | Accountant | invoice_id, patient_name, amounts, status | Clinical data |
| `vw_doctor_view` | Doctor | Full medical history, prescriptions, lab results | Invoices, insurance, addresses |
| `vw_nurse_view` | Nurse | Patient name, blood group, emergency contacts, room, medications | Diagnoses, lab results, invoices |
| `vw_accountant_view` | Accountant | Invoices, billing, insurance claims | All clinical data |
| `vw_pharmacy_view` | Pharmacist | Stock levels, supplier details, unresolved alerts | All patient/financial data |

---

## 7. Entity-Relationship Model

The MediCore ER model was designed in **Chen notation** with strict adherence to BCNF. All non-key attributes depend only on the whole primary key with no transitive dependencies.

---

### 7.1 Main Entity Relationships

| From Entity | Cardinality | To Entity | Description |
|-------------|-------------|-----------|-------------|
| `patient` | **1 : M** | `appointment` | One patient → many appointments (CASCADE DELETE) |
| `doctor` | **1 : M** | `appointment` | One doctor → many appointments |
| `department` | **1 : M** | `doctor` | One department → many doctors |
| `department` | **1 : M** | `room` | One department → many rooms |
| `department` | **1 : M** | `staff` | One department → many staff members |
| `doctor` | **0 : 1** | `department` | One doctor may head one department (circular FK via ALTER TABLE) |
| `supplier` | **1 : M** | `medicine_inventory` | One supplier → many medicines |
| `appointment` | **1 : 1** | `prescription` | One appointment → at most one prescription (weak entity) |
| `prescription` | **1 : M** | `prescription_detail` | One prescription → many medicine detail rows |
| `medicine_inventory` | **1 : M** | `prescription_detail` | One medicine → many prescription detail rows |
| `patient` | **1 : M** | `lab_test` | One patient → many lab tests (CASCADE DELETE) |
| `doctor` | **1 : M** | `lab_test` | One doctor → many lab tests ordered |
| `appointment` | **0 : M** | `lab_test` | Lab tests optionally linked to appointment (SET NULL on delete) |
| `patient` | **1 : M** | `invoice` | One patient → many invoices (weak entity) |
| `invoice` | **0 : 1** | `insurance_claim` | Each invoice → at most one insurance claim |
| `medicine_inventory` | **1 : M** | `alerts` | One medicine → many alerts |
| `room` | **0 : 1** | `appointment` | Each appointment optionally occupies one room |

---

### 7.2 Weak Entities

- **`prescription`** — existentially dependent on `appointment`. Partial key: `appointment_id`. Cascade-deleted with parent appointment.
- **`invoice`** — existentially dependent on `patient`. Identifying key: composite (`patient_id`, `invoice_id`).

---

### 7.3 Circular Dependency Resolution

The `department–doctor` relationship creates a circular FK dependency:
- `department` references `doctor` via `head_doctor_id`
- `doctor` references `department` via `dept_id`

**Resolution:**
1. Create `department` first **without** `head_doctor_id` FK
2. Create `doctor` with `dept_id` FK referencing `department`
3. Add `head_doctor_id` FK to `department` via `ALTER TABLE` after both tables exist

---

## 8. Performance Indexes

Ten indexes were created on high-frequency query columns to optimise the most common HMS operations.

| Index Name | Table.Column | Optimises |
|------------|-------------|-----------|
| `idx_appointment_datetime` | `appointment(appt_datetime)` | Range queries on appointment date/time |
| `idx_appointment_patient` | `appointment(patient_id)` | Fetching all appointments for a patient |
| `idx_appointment_doctor` | `appointment(doctor_id)` | Fetching all appointments for a doctor |
| `idx_invoice_patient` | `invoice(patient_id)` | Patient billing history lookup |
| `idx_invoice_status` | `invoice(payment_status)` | Filtering unpaid/partial invoices |
| `idx_claim_status` | `insurance_claim(claim_status)` | Filtering claims by processing status |
| `idx_labtest_patient` | `lab_test(patient_id)` | Fetching lab history for a patient |
| `idx_labtest_status` | `lab_test(status)` | Filtering pending/in-progress tests |
| `idx_medicine_stock` | `medicine_inventory(quantity_available)` | Stock level monitoring queries |
| `idx_alerts_resolved` | `alerts(resolved)` | Filtering unresolved alerts (`resolved=0`) |

---

## 9. Concurrency Control

MediCore HMS demonstrates both **pessimistic** and **optimistic** concurrency control strategies.

---

### 9.1 Pessimistic Locking — SELECT FOR UPDATE

The appointment booking process uses pessimistic locking to prevent the double-booking race condition. When `sp_book_appointment` checks a doctor's timeslot, it acquires an exclusive row lock via `SELECT FOR UPDATE`. A concurrent transaction attempting to book the same slot is **blocked at the database level** until the first transaction commits or rolls back.

```sql
-- Session 1 acquires lock
SELECT * FROM appointment
WHERE  doctor_id = 1
AND    appt_datetime = TO_TIMESTAMP('2025-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS')
FOR UPDATE;

-- Session 2 attempts same row — BLOCKED until Session 1 commits
```

> This is demonstrated interactively in the **Concurrency Demo** page of the HMS frontend, which simulates two sessions racing to book the same slot and shows Session 2 being blocked.

---

### 9.2 Optimistic Concurrency — Version Stamp Pattern

For lower-conflict scenarios such as patient record updates, the optimistic approach uses a `version_stamp` column. The application reads the current version, makes changes, then updates only if the stamp still matches. If another user has modified the record, the update returns 0 rows and the application retries.

```sql
-- Read with version stamp
SELECT patient_id, name, version_stamp FROM patient WHERE patient_id = 1;
-- (returns version_stamp = 3)

-- Update only if version still matches
UPDATE patient
SET    name = 'Updated Name', version_stamp = version_stamp + 1
WHERE  patient_id = 1 AND version_stamp = 3;

-- IF SQL%ROWCOUNT = 0 THEN conflict detected → retry
```

---

## 10. Advanced SQL Queries

The following queries demonstrate proficiency in multi-table joins, aggregate functions, subqueries, HAVING clauses, and Oracle-specific syntax.

---

### 10.1 Multi-Table Join — Full Appointment Details

```sql
SELECT p.name AS patient_name, d.name AS doctor_name,
       a.appt_datetime, a.appointment_type, a.status, r.room_type
FROM   appointment a
JOIN   patient   p ON a.patient_id = p.patient_id
JOIN   doctor    d ON a.doctor_id  = d.doctor_id
LEFT JOIN room   r ON a.room_id    = r.room_id
ORDER BY a.appt_datetime;
```

---

### 10.2 Aggregate — Appointments per Doctor

```sql
SELECT d.name, d.specialization,
       COUNT(a.appointment_id) AS total_appointments
FROM   doctor d LEFT JOIN appointment a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.name, d.specialization
ORDER BY total_appointments DESC;
```

---

### 10.3 Subquery — Patients with No Lab Tests

```sql
SELECT patient_id, name, phone
FROM   patient
WHERE  patient_id NOT IN
       (SELECT DISTINCT patient_id FROM lab_test)
ORDER BY name;
```

---

### 10.4 HAVING — Medicines Dispensed > 30 Units

```sql
SELECT mi.medicine_name,
       SUM(pd.quantity_issued) AS total_dispensed
FROM   prescription_detail pd
JOIN   medicine_inventory  mi ON pd.medicine_id = mi.medicine_id
GROUP BY mi.medicine_id, mi.medicine_name
HAVING SUM(pd.quantity_issued) > 30
ORDER BY total_dispensed DESC;
```

---

### 10.5 Monthly Appointment Summary

```sql
SELECT TO_CHAR(appt_datetime,'YYYY-MM') AS month,
       COUNT(*) AS total,
       SUM(CASE WHEN status='Completed' THEN 1 ELSE 0 END) AS completed,
       SUM(CASE WHEN status='Cancelled' THEN 1 ELSE 0 END) AS cancelled
FROM   appointment
GROUP BY TO_CHAR(appt_datetime,'YYYY-MM')
ORDER BY month;
```

---

### 10.6 Top 3 Busiest Doctors

```sql
SELECT d.name, d.specialization, COUNT(a.appointment_id) AS appts
FROM   doctor d JOIN appointment a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.name, d.specialization
ORDER BY appts DESC
FETCH FIRST 3 ROWS ONLY;
```

---

## 11. Seed Data Summary

The following test data was inserted to demonstrate all system functionality during the project demonstration.

| Table | Rows | Notable Records |
|-------|------|-----------------|
| `department` | **5** | Cardiology, Neurology, Orthopaedics, Gynaecology, Emergency Medicine |
| `supplier` | **5** | MedPak, Getz Pharma, Searle Pakistan, Highnoon, Ferozsons |
| `doctor` | **8** | Across all 5 departments; each department head assigned via UPDATE |
| `medicine_inventory` | **10** | Aspirin, Atorvastatin, Morphine, Ceftriaxone, Paracetamol + more |
| `room` | **8** | One per ward type including ICU and Operating Theatre |
| `staff` | **8** | Nurses, pharmacists, receptionists, lab techs across all departments |
| `patient` | **15** | All Karachi-based; mix of blood groups and ages |
| `appointment` | **20** | 15 completed + 5 upcoming; mix of all appointment types |
| `prescription` | **8** | Linked to completed appointments only |
| `prescription_detail` | **12** | Multi-medicine prescriptions for cardiac and neuro patients |
| `lab_test` | **8** | Completed, Pending, and In Progress examples |
| `invoice` | **8** | Paid, Partially Paid, and Unpaid examples |
| `insurance_claim` | **4** | EFU Life (Paid), Jubilee (Approved), State Life (Under Review), Adamjee (Submitted) |
| `alerts` | **3** | 2 unresolved + 1 resolved |

---

## 12. Flask REST API — Endpoint Summary

The Python Flask backend exposes a RESTful API on **port 5000**. All endpoints return JSON and support CORS. Each POST endpoint that performs a write operation calls the corresponding Oracle stored procedure, ensuring all business logic stays in the database layer.

| Method | Endpoint | Calls | Purpose |
|--------|----------|-------|---------|
| GET | `/api/health` | Oracle connect | Check DB connectivity |
| GET | `/api/stats` | 5 COUNT queries | Dashboard statistics |
| GET | `/api/patients` | SELECT patient | List all patients |
| POST | `/api/patients` | INSERT + trigger | Register new patient |
| PUT | `/api/patients/{id}` | UPDATE patient | Edit patient record |
| DELETE | `/api/patients/{id}` | DELETE patient | Remove patient |
| GET | `/api/doctors` | SELECT + JOIN dept | List all doctors |
| GET | `/api/departments` | SELECT + JOIN doctor | List all departments |
| GET | `/api/appointments` | 4-table JOIN | List all appointments |
| POST | `/api/appointments` | `sp_book_appointment` | Book with double-booking check |
| POST | `/api/appointments/{id}/status` | UPDATE appointment | Inline status change |
| DELETE | `/api/appointments/{id}` | DELETE appointment | Cancel appointment |
| GET | `/api/medicines` | SELECT + JOIN supplier | List inventory with stock status |
| POST | `/api/dispense` | `sp_dispense_medicine` | Dispense + auto-trigger alert |
| GET | `/api/labtests` | 3-table JOIN | List all lab tests |
| POST | `/api/labtests/{id}/result` | UPDATE lab_test | Enter lab result |
| GET | `/api/invoices` | SELECT + JOIN patient | List all invoices |
| POST | `/api/billing` | `sp_process_billing` | ACID invoice + insurance claim |
| GET | `/api/alerts` | SELECT + JOIN medicine | List stock alerts |
| POST | `/api/alerts/{id}/resolve` | `sp_resolve_alert` | Mark alert resolved |
| POST | `/api/discharge` | `PROC_PATIENT_DISCHARGE` | ACID 3-table discharge transaction |
| GET | `/api/rooms` | SELECT + occupancy subquery | Room availability |

---

*MediCore HMS · Oracle XE 11.2 · CS-2005 Database Systems · FAST NUCES Karachi · 2025*
