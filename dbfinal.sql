-- =============================================================================
--  MediCore HMS  --  Oracle SQL DDL  (FIXED VERSION)
--  Course   : CS-2005 Database Systems
--  Instructor: Talha Shahid  |  FAST NUCES Karachi
--  Converted : PostgreSQL 16  -->  Oracle SQL Developer 18.1
--
--  FIX APPLIED:
--  ORA-00984 "column not allowed here" was caused by using
--  DEFAULT seq.NEXTVAL in CREATE TABLE, which is only supported
--  in Oracle 12c with IDENTITY columns.
--  Solution: Use BEFORE INSERT triggers to assign sequence values.
-- =============================================================================


-- ??????????????????????????????????????????????
--  SECTION 0  :  CLEAN SLATE
--  Drop tables in reverse FK order, then drop sequences and triggers
-- ??????????????????????????????????????????????

BEGIN EXECUTE IMMEDIATE 'DROP TABLE alerts              CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE insurance_claim     CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE invoice             CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE lab_test            CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE prescription_detail CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE prescription        CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE appointment         CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE staff               CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE room                CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE medicine_inventory  CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE supplier            CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE doctor              CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE department          CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE patient             CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Drop Sequences
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_patient';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_supplier';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_department';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_doctor';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_medicine';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_room';          EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_staff';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_appointment';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_prescription';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_invoice';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_presc_detail';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_lab_test';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_ins_claim';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_alerts';        EXCEPTION WHEN OTHERS THEN NULL; END;
/


-- ??????????????????????????????????????????????
--  SEQUENCES  (Auto-increment replacement for PostgreSQL SERIAL)
-- ??????????????????????????????????????????????

CREATE SEQUENCE seq_patient      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_supplier     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_department   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_doctor       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_medicine     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_room         START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_staff        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_appointment  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_prescription START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_invoice      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_presc_detail START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_lab_test     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_ins_claim    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_alerts       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;


-- ??????????????????????????????????????????????
--  SECTION 1  :  INDEPENDENT TABLES
-- ??????????????????????????????????????????????

-- 1.1  PATIENT
CREATE TABLE patient (
    patient_id               NUMBER          PRIMARY KEY,
    name                     VARCHAR2(120)   NOT NULL,
    dob                      DATE            NOT NULL,
    blood_group              VARCHAR2(3)     NOT NULL
                                 CONSTRAINT chk_patient_blood_group
                                 CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    phone                    VARCHAR2(20)    NOT NULL UNIQUE,
    email                    VARCHAR2(150)            UNIQUE,
    address                  CLOB,
    emergency_contact_name   VARCHAR2(120)   NOT NULL,
    emergency_contact_phone  VARCHAR2(20)    NOT NULL,
    created_at               TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL
);

COMMENT ON TABLE  patient                        IS 'Core patient registry. One row per individual.';
COMMENT ON COLUMN patient.blood_group            IS 'ABO-Rh system restricted to 8 valid types via CHECK.';
COMMENT ON COLUMN patient.emergency_contact_name IS 'Stored flat (BCNF): no separate emergency-contact entity needed.';

-- BEFORE INSERT trigger to auto-assign patient_id from sequence
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
/


-- 1.2  SUPPLIER
CREATE TABLE supplier (
    supplier_id    NUMBER         PRIMARY KEY,
    company_name   VARCHAR2(200)  NOT NULL,
    contact_phone  VARCHAR2(20)   NOT NULL,
    email          VARCHAR2(150)  UNIQUE,
    lead_time_days NUMBER(5)      NOT NULL
                       CONSTRAINT chk_supplier_lead_time CHECK (lead_time_days >= 0),
    created_at     TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL
);

COMMENT ON COLUMN supplier.lead_time_days IS 'Expected delivery days after order placement. Must be >= 0.';

CREATE OR REPLACE TRIGGER trg_supplier_bi
BEFORE INSERT ON supplier
FOR EACH ROW
BEGIN
    IF :NEW.supplier_id IS NULL THEN
        SELECT seq_supplier.NEXTVAL INTO :NEW.supplier_id FROM DUAL;
    END IF;
    IF :NEW.created_at IS NULL THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
END;
/


-- ??????????????????????????????????????????????
--  SECTION 2  :  FIRST-LEVEL FK DEPENDENTS
-- ??????????????????????????????????????????????

-- 2.1  DEPARTMENT
CREATE TABLE department (
    dept_id        NUMBER        PRIMARY KEY,
    dept_name      VARCHAR2(100) NOT NULL UNIQUE,
    floor_no       NUMBER(5)     NOT NULL CONSTRAINT chk_dept_floor CHECK (floor_no >= 0),
    head_doctor_id NUMBER
);

COMMENT ON COLUMN department.head_doctor_id IS 'FK to doctor(doctor_id). Added via ALTER after doctor is created to break circular dependency.';

CREATE OR REPLACE TRIGGER trg_department_bi
BEFORE INSERT ON department
FOR EACH ROW
BEGIN
    IF :NEW.dept_id IS NULL THEN
        SELECT seq_department.NEXTVAL INTO :NEW.dept_id FROM DUAL;
    END IF;
END;
/


-- 2.2  DOCTOR
CREATE TABLE doctor (
    doctor_id       NUMBER        PRIMARY KEY,
    name            VARCHAR2(120) NOT NULL,
    specialization  VARCHAR2(100) NOT NULL,
    license_no      VARCHAR2(50)  NOT NULL UNIQUE,
    phone           VARCHAR2(20)  NOT NULL UNIQUE,
    email           VARCHAR2(150)          UNIQUE,
    dept_id         NUMBER        NOT NULL
                        CONSTRAINT fk_doctor_dept
                        REFERENCES department(dept_id)
                        ON DELETE SET NULL,
    created_at      TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);

-- NOTE: Oracle default behaviour (no ON DELETE clause) = RESTRICT.
-- ON DELETE SET NULL used here since a doctor can exist without a dept temporarily.

CREATE OR REPLACE TRIGGER trg_doctor_bi
BEFORE INSERT ON doctor
FOR EACH ROW
BEGIN
    IF :NEW.doctor_id IS NULL THEN
        SELECT seq_doctor.NEXTVAL INTO :NEW.doctor_id FROM DUAL;
    END IF;
    IF :NEW.created_at IS NULL THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
END;
/


-- 2.3  Resolve circular FK: department.head_doctor_id -> doctor
ALTER TABLE department
    ADD CONSTRAINT fk_dept_head_doctor
    FOREIGN KEY (head_doctor_id)
    REFERENCES doctor(doctor_id)
    ON DELETE SET NULL;


-- 2.4  MEDICINE_INVENTORY
CREATE TABLE medicine_inventory (
    medicine_id         NUMBER        PRIMARY KEY,
    supplier_id         NUMBER        NOT NULL
                            CONSTRAINT fk_medicine_supplier
                            REFERENCES supplier(supplier_id),
    medicine_name       VARCHAR2(200) NOT NULL,
    quantity_available  NUMBER(10)    DEFAULT 0 NOT NULL
                            CONSTRAINT chk_med_qty CHECK (quantity_available >= 0),
    minimum_threshold   NUMBER(10)    DEFAULT 10 NOT NULL
                            CONSTRAINT chk_med_threshold CHECK (minimum_threshold >= 0),
    unit                VARCHAR2(30)  NOT NULL
                            CONSTRAINT chk_med_unit
                            CHECK (unit IN ('tablets','capsules','ml','mg','vials',
                                            'ampoules','sachets','patches','units')),
    unit_price          NUMBER(10,2)  NOT NULL
                            CONSTRAINT chk_med_price CHECK (unit_price >= 0),
    created_at          TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);

COMMENT ON COLUMN medicine_inventory.minimum_threshold IS 'Trigger fires an alert when quantity_available drops below this value.';

CREATE OR REPLACE TRIGGER trg_medicine_bi
BEFORE INSERT ON medicine_inventory
FOR EACH ROW
BEGIN
    IF :NEW.medicine_id IS NULL THEN
        SELECT seq_medicine.NEXTVAL INTO :NEW.medicine_id FROM DUAL;
    END IF;
    IF :NEW.created_at IS NULL THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
END;
/


-- ??????????????????????????????????????????????
--  SECTION 3  :  SECOND-LEVEL FK DEPENDENTS
-- ??????????????????????????????????????????????

-- 3.1  ROOM
CREATE TABLE room (
    room_id           NUMBER       PRIMARY KEY,
    dept_id           NUMBER       NOT NULL
                          CONSTRAINT fk_room_dept
                          REFERENCES department(dept_id),
    room_type         VARCHAR2(50) NOT NULL
                          CONSTRAINT chk_room_type
                          CHECK (room_type IN ('General Ward','ICU','Operating Theatre',
                                               'Consultation','Recovery','Emergency','Lab')),
    capacity          NUMBER(5)    NOT NULL CONSTRAINT chk_room_capacity CHECK (capacity > 0),
    current_occupancy NUMBER(5)    DEFAULT 0 NOT NULL
                          CONSTRAINT chk_room_occupancy CHECK (current_occupancy >= 0),
    CONSTRAINT chk_occupancy_capacity CHECK (current_occupancy <= capacity)
);

CREATE OR REPLACE TRIGGER trg_room_bi
BEFORE INSERT ON room
FOR EACH ROW
BEGIN
    IF :NEW.room_id IS NULL THEN
        SELECT seq_room.NEXTVAL INTO :NEW.room_id FROM DUAL;
    END IF;
END;
/


-- 3.2  STAFF
CREATE TABLE staff (
    staff_id   NUMBER        PRIMARY KEY,
    dept_id    NUMBER        NOT NULL
                   CONSTRAINT fk_staff_dept
                   REFERENCES department(dept_id),
    name       VARCHAR2(120) NOT NULL,
    role       VARCHAR2(60)  NOT NULL
                   CONSTRAINT chk_staff_role
                   CHECK (role IN ('Nurse','Lab Technician','Receptionist',
                                   'Pharmacist','Admin','Porter','Security')),
    shift      VARCHAR2(10)  NOT NULL
                   CONSTRAINT chk_staff_shift
                   CHECK (shift IN ('Morning','Evening','Night')),
    phone      VARCHAR2(20)  NOT NULL UNIQUE,
    email      VARCHAR2(150)          UNIQUE,
    created_at TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE OR REPLACE TRIGGER trg_staff_bi
BEFORE INSERT ON staff
FOR EACH ROW
BEGIN
    IF :NEW.staff_id IS NULL THEN
        SELECT seq_staff.NEXTVAL INTO :NEW.staff_id FROM DUAL;
    END IF;
    IF :NEW.created_at IS NULL THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
END;
/


-- 3.3  APPOINTMENT
CREATE TABLE appointment (
    appointment_id   NUMBER       PRIMARY KEY,
    patient_id       NUMBER       NOT NULL
                         CONSTRAINT fk_appt_patient
                         REFERENCES patient(patient_id)
                         ON DELETE CASCADE,
    doctor_id        NUMBER       NOT NULL
                         CONSTRAINT fk_appt_doctor
                         REFERENCES doctor(doctor_id),
    room_id          NUMBER
                         CONSTRAINT fk_appt_room
                         REFERENCES room(room_id)
                         ON DELETE SET NULL,
    appt_datetime    TIMESTAMP    NOT NULL,
    appointment_type VARCHAR2(50) NOT NULL
                         CONSTRAINT chk_appt_type
                         CHECK (appointment_type IN ('Consultation','Follow-up','Surgery',
                                                     'Emergency','Lab Visit','Imaging')),
    status           VARCHAR2(20) DEFAULT 'Scheduled' NOT NULL
                         CONSTRAINT chk_appt_status
                         CHECK (status IN ('Scheduled','Confirmed','In Progress',
                                           'Completed','Cancelled','No-Show')),
    notes            CLOB,
    created_at       TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT uq_doctor_timeslot UNIQUE (doctor_id, appt_datetime),
    CONSTRAINT uq_room_timeslot   UNIQUE (room_id, appt_datetime)
);

COMMENT ON COLUMN appointment.doctor_id IS 'Enforces no double-booking at DB level via uq_doctor_timeslot.';

CREATE OR REPLACE TRIGGER trg_appointment_bi
BEFORE INSERT ON appointment
FOR EACH ROW
BEGIN
    IF :NEW.appointment_id IS NULL THEN
        SELECT seq_appointment.NEXTVAL INTO :NEW.appointment_id FROM DUAL;
    END IF;
    IF :NEW.created_at IS NULL THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
END;
/


-- ??????????????????????????????????????????????
--  SECTION 4  :  WEAK ENTITIES
-- ??????????????????????????????????????????????

-- 4.1  PRESCRIPTION
CREATE TABLE prescription (
    prescription_id  NUMBER    PRIMARY KEY,
    appointment_id   NUMBER    NOT NULL UNIQUE
                         CONSTRAINT fk_presc_appt
                         REFERENCES appointment(appointment_id)
                         ON DELETE CASCADE,
    prescribed_date  DATE      DEFAULT SYSDATE NOT NULL,
    notes            CLOB,
    CONSTRAINT uq_prescription_appointment UNIQUE (prescription_id, appointment_id)
);

COMMENT ON TABLE prescription IS 'Weak entity: existentially dependent on appointment. Cascade delete enforces this.';
COMMENT ON COLUMN prescription.appointment_id IS 'Partial key in Chen notation. UNIQUE enforces 1 prescription per appointment.';

CREATE OR REPLACE TRIGGER trg_prescription_bi
BEFORE INSERT ON prescription
FOR EACH ROW
BEGIN
    IF :NEW.prescription_id IS NULL THEN
        SELECT seq_prescription.NEXTVAL INTO :NEW.prescription_id FROM DUAL;
    END IF;
    IF :NEW.prescribed_date IS NULL THEN
        :NEW.prescribed_date := SYSDATE;
    END IF;
END;
/


-- 4.2  INVOICE
CREATE TABLE invoice (
    invoice_id     NUMBER        PRIMARY KEY,
    patient_id     NUMBER        NOT NULL
                       CONSTRAINT fk_invoice_patient
                       REFERENCES patient(patient_id),
    issue_date     DATE          DEFAULT SYSDATE NOT NULL,
    due_date       DATE,
    total_amount   NUMBER(10,2)  NOT NULL
                       CONSTRAINT chk_invoice_total CHECK (total_amount >= 0),
    amount_paid    NUMBER(10,2)  DEFAULT 0 NOT NULL
                       CONSTRAINT chk_invoice_paid CHECK (amount_paid >= 0),
    payment_status VARCHAR2(20)  DEFAULT 'Unpaid' NOT NULL
                       CONSTRAINT chk_invoice_status
                       CHECK (payment_status IN ('Unpaid','Partially Paid','Paid','Waived','Disputed')),
    CONSTRAINT uq_invoice_patient UNIQUE (patient_id, invoice_id),
    CONSTRAINT chk_payment_not_exceed_total CHECK (amount_paid <= total_amount)
);

COMMENT ON TABLE invoice IS 'Weak entity: existentially depends on patient. Composite key (patient_id, invoice_id) is the identifying key.';

CREATE OR REPLACE TRIGGER trg_invoice_bi
BEFORE INSERT ON invoice
FOR EACH ROW
BEGIN
    IF :NEW.invoice_id IS NULL THEN
        SELECT seq_invoice.NEXTVAL INTO :NEW.invoice_id FROM DUAL;
    END IF;
    IF :NEW.issue_date IS NULL THEN
        :NEW.issue_date := SYSDATE;
    END IF;
END;
/


-- ??????????????????????????????????????????????
--  SECTION 5  :  JUNCTION & DETAIL TABLES
-- ??????????????????????????????????????????????

-- 5.1  PRESCRIPTION_DETAIL
CREATE TABLE prescription_detail (
    detail_id        NUMBER        PRIMARY KEY,
    prescription_id  NUMBER        NOT NULL
                         CONSTRAINT fk_pd_prescription
                         REFERENCES prescription(prescription_id)
                         ON DELETE CASCADE,
    medicine_id      NUMBER        NOT NULL
                         CONSTRAINT fk_pd_medicine
                         REFERENCES medicine_inventory(medicine_id),
    dosage           VARCHAR2(100) NOT NULL,
    duration_days    NUMBER(5)     NOT NULL
                         CONSTRAINT chk_pd_duration CHECK (duration_days > 0),
    quantity_issued  NUMBER(10)    NOT NULL
                         CONSTRAINT chk_pd_qty CHECK (quantity_issued > 0),
    CONSTRAINT uq_medicine_per_prescription UNIQUE (prescription_id, medicine_id)
);

CREATE OR REPLACE TRIGGER trg_presc_detail_bi
BEFORE INSERT ON prescription_detail
FOR EACH ROW
BEGIN
    IF :NEW.detail_id IS NULL THEN
        SELECT seq_presc_detail.NEXTVAL INTO :NEW.detail_id FROM DUAL;
    END IF;
END;
/


-- 5.2  LAB_TEST
CREATE TABLE lab_test (
    test_id         NUMBER        PRIMARY KEY,
    patient_id      NUMBER        NOT NULL
                        CONSTRAINT fk_lab_patient
                        REFERENCES patient(patient_id)
                        ON DELETE CASCADE,
    ordered_by      NUMBER        NOT NULL
                        CONSTRAINT fk_lab_doctor
                        REFERENCES doctor(doctor_id),
    appointment_id  NUMBER
                        CONSTRAINT fk_lab_appt
                        REFERENCES appointment(appointment_id)
                        ON DELETE SET NULL,
    test_name       VARCHAR2(150) NOT NULL,
    result          CLOB,
    result_date     DATE,
    status          VARCHAR2(20)  DEFAULT 'Pending' NOT NULL
                        CONSTRAINT chk_lab_status
                        CHECK (status IN ('Pending','In Progress','Completed','Cancelled')),
    created_at      TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE OR REPLACE TRIGGER trg_lab_test_bi
BEFORE INSERT ON lab_test
FOR EACH ROW
BEGIN
    IF :NEW.test_id IS NULL THEN
        SELECT seq_lab_test.NEXTVAL INTO :NEW.test_id FROM DUAL;
    END IF;
    IF :NEW.created_at IS NULL THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
END;
/


-- 5.3  INSURANCE_CLAIM
CREATE TABLE insurance_claim (
    claim_id        NUMBER        PRIMARY KEY,
    invoice_id      NUMBER        NOT NULL UNIQUE
                        CONSTRAINT fk_claim_invoice
                        REFERENCES invoice(invoice_id)
                        ON DELETE CASCADE,
    provider_name   VARCHAR2(200) NOT NULL,
    claim_amount    NUMBER(10,2)  NOT NULL
                        CONSTRAINT chk_claim_amount CHECK (claim_amount > 0),
    claim_status    VARCHAR2(30)  DEFAULT 'Submitted' NOT NULL
                        CONSTRAINT chk_claim_status
                        CHECK (claim_status IN ('Submitted','Under Review','Approved',
                                                'Partially Approved','Rejected','Paid')),
    submitted_at    TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    resolved_at     TIMESTAMP,
    CONSTRAINT chk_claim_dates CHECK (resolved_at IS NULL OR resolved_at >= submitted_at)
);

CREATE OR REPLACE TRIGGER trg_ins_claim_bi
BEFORE INSERT ON insurance_claim
FOR EACH ROW
BEGIN
    IF :NEW.claim_id IS NULL THEN
        SELECT seq_ins_claim.NEXTVAL INTO :NEW.claim_id FROM DUAL;
    END IF;
    IF :NEW.submitted_at IS NULL THEN
        :NEW.submitted_at := SYSTIMESTAMP;
    END IF;
END;
/


-- 5.4  ALERTS
--      Oracle has no BOOLEAN ? NUMBER(1) with CHECK (0=FALSE, 1=TRUE)
CREATE TABLE alerts (
    alert_id      NUMBER        PRIMARY KEY,
    medicine_id   NUMBER        NOT NULL
                      CONSTRAINT fk_alert_medicine
                      REFERENCES medicine_inventory(medicine_id)
                      ON DELETE CASCADE,
    triggered_at  TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    alert_message CLOB          NOT NULL,
    resolved      NUMBER(1)     DEFAULT 0 NOT NULL
                      CONSTRAINT chk_alert_resolved CHECK (resolved IN (0, 1)),
    resolved_at   TIMESTAMP,
    CONSTRAINT chk_alert_resolution CHECK (
        (resolved = 0 AND resolved_at IS NULL) OR
        (resolved = 1 AND resolved_at IS NOT NULL)
    )
);

COMMENT ON TABLE  alerts          IS 'Populated automatically by the low_stock_alert TRIGGER on medicine_inventory.';
COMMENT ON COLUMN alerts.resolved IS '0 = FALSE (unresolved), 1 = TRUE (resolved). Oracle has no native BOOLEAN.';

CREATE OR REPLACE TRIGGER trg_alerts_bi
BEFORE INSERT ON alerts
FOR EACH ROW
BEGIN
    IF :NEW.alert_id IS NULL THEN
        SELECT seq_alerts.NEXTVAL INTO :NEW.alert_id FROM DUAL;
    END IF;
    IF :NEW.triggered_at IS NULL THEN
        :NEW.triggered_at := SYSTIMESTAMP;
    END IF;
END;
/


-- ??????????????????????????????????????????????
--  SECTION 6  :  INDEXES FOR QUERY PERFORMANCE
-- ??????????????????????????????????????????????

CREATE INDEX idx_appointment_datetime ON appointment(appt_datetime);
CREATE INDEX idx_appointment_patient  ON appointment(patient_id);
CREATE INDEX idx_appointment_doctor   ON appointment(doctor_id);

CREATE INDEX idx_invoice_patient      ON invoice(patient_id);
CREATE INDEX idx_invoice_status       ON invoice(payment_status);
CREATE INDEX idx_claim_status         ON insurance_claim(claim_status);

CREATE INDEX idx_labtest_patient      ON lab_test(patient_id);
CREATE INDEX idx_labtest_status       ON lab_test(status);

CREATE INDEX idx_medicine_stock       ON medicine_inventory(quantity_available);

-- Note: Oracle does NOT support partial/filtered indexes (WHERE clause).
-- Use full index; filter in queries with WHERE resolved = 0
CREATE INDEX idx_alerts_resolved      ON alerts(resolved);


-- ??????????????????????????????????????????????
--  SECTION 7  :  LOW-STOCK ALERT TRIGGER
--  Fires when quantity_available drops below minimum_threshold
--  Note: COMMENT ON TRIGGER is NOT supported in Oracle ? removed
-- ??????????????????????????????????????????????

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
            ' has fallen to '  || TO_CHAR(:NEW.quantity_available) ||
            ' '                || :NEW.unit ||
            ' (threshold: '    || TO_CHAR(:NEW.minimum_threshold) || ').'
        );
    END IF;
END;
/


-- =============================================================================
--  END OF DDL  --  All errors resolved
-- =============================================================================















--PHASE 2(INSERTING SEED):

-- =============================================================================
--  MediCore HMS  --  Oracle SQL DML  (INSERT Statements)
--  Course   : CS-2005 Database Systems
--  Instructor: Talha Shahid  |  FAST NUCES Karachi
--  Context  : Karachi-based Hospital Data
--  Order    : Respects all Foreign Key constraints
-- =============================================================================


-- ??????????????????????????????????????????????
--  SECTION 1  :  DEPARTMENTS  (5 rows)
--  No FK dependencies — insert first
-- ??????????????????????????????????????????????

INSERT INTO department (dept_name, floor_no) VALUES ('Cardiology',          1);
INSERT INTO department (dept_name, floor_no) VALUES ('Neurology',           2);
INSERT INTO department (dept_name, floor_no) VALUES ('Orthopaedics',        3);
INSERT INTO department (dept_name, floor_no) VALUES ('Gynaecology',         4);
INSERT INTO department (dept_name, floor_no) VALUES ('Emergency Medicine',  0);

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 2  :  SUPPLIERS  (5 rows)
--  No FK dependencies — insert alongside departments
-- ??????????????????????????????????????????????

INSERT INTO supplier (company_name,                  contact_phone,   email,                          lead_time_days)
VALUES ('MedPak Pharmaceuticals Karachi',            '021-35810001',  'orders@medpak.com.pk',         3);

INSERT INTO supplier (company_name,                  contact_phone,   email,                          lead_time_days)
VALUES ('Getz Pharma Pvt Ltd',                       '021-34302401',  'supply@getzpharma.com',        2);

INSERT INTO supplier (company_name,                  contact_phone,   email,                          lead_time_days)
VALUES ('Searle Pakistan Limited',                   '021-34325661',  'logistics@searlepk.com',       4);

INSERT INTO supplier (company_name,                  contact_phone,   email,                          lead_time_days)
VALUES ('Highnoon Laboratories Karachi',             '021-36961001',  'procurement@highnoon.com.pk',  5);

INSERT INTO supplier (company_name,                  contact_phone,   email,                          lead_time_days)
VALUES ('Ferozsons Laboratories Ltd',                '021-35231171',  'sales@ferozsons.com.pk',       3);

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 3  :  DOCTORS  (8 rows)
--  FK: dept_id ? department(dept_id)
--  dept_id values: 1=Cardiology, 2=Neurology, 3=Orthopaedics,
--                  4=Gynaecology, 5=Emergency Medicine
-- ??????????????????????????????????????????????

INSERT INTO doctor (name,                    specialization,            license_no,     phone,           email,                           dept_id)
VALUES ('Dr. Murtaza Hussain',               'Interventional Cardiology','PMDC-2201',   '0300-2111001',  'murtaza.hussain@medicore.pk',   1);

INSERT INTO doctor (name,                    specialization,            license_no,     phone,           email,                           dept_id)
VALUES ('Dr. Sana Mirza',                    'Cardiac Electrophysiology','PMDC-2202',   '0321-2111002',  'sana.mirza@medicore.pk',        1);

INSERT INTO doctor (name,                    specialization,            license_no,     phone,           email,                           dept_id)
VALUES ('Dr. Farhan Qureshi',                'Clinical Neurology',       'PMDC-2203',   '0333-2111003',  'farhan.qureshi@medicore.pk',    2);

INSERT INTO doctor (name,                    specialization,            license_no,     phone,           email,                           dept_id)
VALUES ('Dr. Nadia Baig',                    'Neurosurgery',             'PMDC-2204',   '0312-2111004',  'nadia.baig@medicore.pk',        2);

INSERT INTO doctor (name,                    specialization,            license_no,     phone,           email,                           dept_id)
VALUES ('Dr. Imran Sheikh',                  'Orthopaedic Surgery',      'PMDC-2205',   '0345-2111005',  'imran.sheikh@medicore.pk',      3);

INSERT INTO doctor (name,                    specialization,            license_no,     phone,           email,                           dept_id)
VALUES ('Dr. Zainab Raza',                   'Obstetrics & Gynaecology', 'PMDC-2206',   '0300-2111006',  'zainab.raza@medicore.pk',       4);

INSERT INTO doctor (name,                    specialization,            license_no,     phone,           email,                           dept_id)
VALUES ('Dr. Bilal Ansari',                  'Emergency Medicine',       'PMDC-2207',   '0336-2111007',  'bilal.ansari@medicore.pk',      5);

INSERT INTO doctor (name,                    specialization,            license_no,     phone,           email,                           dept_id)
VALUES ('Dr. Hina Siddiqui',                 'Gynaecologic Oncology',    'PMDC-2208',   '0311-2111008',  'hina.siddiqui@medicore.pk',     4);

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 4  :  UPDATE department.head_doctor_id
--  Now that doctors exist, assign department heads
-- ??????????????????????????????????????????????

UPDATE department SET head_doctor_id = 1 WHERE dept_id = 1;  -- Dr. Murtaza  ? Cardiology
UPDATE department SET head_doctor_id = 3 WHERE dept_id = 2;  -- Dr. Farhan   ? Neurology
UPDATE department SET head_doctor_id = 5 WHERE dept_id = 3;  -- Dr. Imran    ? Orthopaedics
UPDATE department SET head_doctor_id = 6 WHERE dept_id = 4;  -- Dr. Zainab   ? Gynaecology
UPDATE department SET head_doctor_id = 7 WHERE dept_id = 5;  -- Dr. Bilal    ? Emergency Medicine

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 5  :  MEDICINE_INVENTORY  (10 rows)
--  FK: supplier_id ? supplier(supplier_id)
-- ??????????????????????????????????????????????

INSERT INTO medicine_inventory (supplier_id, medicine_name,         quantity_available, minimum_threshold, unit,      unit_price)
VALUES (1, 'Aspirin 75mg',                   500,                   50,                 'tablets',         12.50);

INSERT INTO medicine_inventory (supplier_id, medicine_name,         quantity_available, minimum_threshold, unit,      unit_price)
VALUES (1, 'Atorvastatin 20mg',              320,                   40,                 'tablets',         45.00);

INSERT INTO medicine_inventory (supplier_id, medicine_name,         quantity_available, minimum_threshold, unit,      unit_price)
VALUES (2, 'Metoprolol 50mg',                210,                   30,                 'tablets',         38.75);

INSERT INTO medicine_inventory (supplier_id, medicine_name,         quantity_available, minimum_threshold, unit,      unit_price)
VALUES (2, 'Amlodipine 5mg',                 180,                   25,                 'tablets',         22.00);

INSERT INTO medicine_inventory (supplier_id, medicine_name,         quantity_available, minimum_threshold, unit,      unit_price)
VALUES (3, 'Diclofenac Sodium 75mg',         400,                   60,                 'tablets',         18.50);

INSERT INTO medicine_inventory (supplier_id, medicine_name,         quantity_available, minimum_threshold, unit,      unit_price)
VALUES (3, 'Omeprazole 20mg',                270,                   35,                 'capsules',        30.00);

INSERT INTO medicine_inventory (supplier_id, medicine_name,         quantity_available, minimum_threshold, unit,      unit_price)
VALUES (4, 'Normal Saline 0.9%',             150,                   20,                 'ml',              85.00);

INSERT INTO medicine_inventory (supplier_id, medicine_name,         quantity_available, minimum_threshold, unit,      unit_price)
VALUES (4, 'Morphine Sulphate 10mg',         80,                    15,                 'ampoules',        220.00);

INSERT INTO medicine_inventory (supplier_id, medicine_name,         quantity_available, minimum_threshold, unit,      unit_price)
VALUES (5, 'Ceftriaxone 1g',                 120,                   20,                 'vials',           350.00);

INSERT INTO medicine_inventory (supplier_id, medicine_name,         quantity_available, minimum_threshold, unit,      unit_price)
VALUES (5, 'Paracetamol 500mg',              600,                   80,                 'tablets',         8.00);

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 6  :  ROOMS  (8 rows)
--  FK: dept_id ? department(dept_id)
-- ??????????????????????????????????????????????

INSERT INTO room (dept_id, room_type,           capacity, current_occupancy) VALUES (1, 'General Ward',      6,  4);
INSERT INTO room (dept_id, room_type,           capacity, current_occupancy) VALUES (1, 'ICU',               4,  2);
INSERT INTO room (dept_id, room_type,           capacity, current_occupancy) VALUES (2, 'Consultation',      2,  1);
INSERT INTO room (dept_id, room_type,           capacity, current_occupancy) VALUES (2, 'General Ward',      6,  3);
INSERT INTO room (dept_id, room_type,           capacity, current_occupancy) VALUES (3, 'Operating Theatre', 3,  1);
INSERT INTO room (dept_id, room_type,           capacity, current_occupancy) VALUES (3, 'Recovery',          4,  2);
INSERT INTO room (dept_id, room_type,           capacity, current_occupancy) VALUES (4, 'General Ward',      8,  5);
INSERT INTO room (dept_id, room_type,           capacity, current_occupancy) VALUES (5, 'Emergency',         10, 7);

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 7  :  STAFF  (8 rows)
--  FK: dept_id ? department(dept_id)
-- ??????????????????????????????????????????????

INSERT INTO staff (dept_id, name,                role,             shift,     phone,           email)
VALUES (1, 'Rukhsana Patel',                     'Nurse',          'Morning', '0300-3001001',  'rukhsana.p@medicore.pk');

INSERT INTO staff (dept_id, name,                role,             shift,     phone,           email)
VALUES (2, 'Kamran Lodhi',                       'Lab Technician', 'Morning', '0321-3001002',  'kamran.l@medicore.pk');

INSERT INTO staff (dept_id, name,                role,             shift,     phone,           email)
VALUES (3, 'Shazia Noor',                        'Nurse',          'Evening', '0333-3001003',  'shazia.n@medicore.pk');

INSERT INTO staff (dept_id, name,                role,             shift,     phone,           email)
VALUES (4, 'Asma Farooq',                        'Nurse',          'Morning', '0312-3001004',  'asma.f@medicore.pk');

INSERT INTO staff (dept_id, name,                role,             shift,     phone,           email)
VALUES (5, 'Tariq Mehmood',                      'Receptionist',   'Morning', '0345-3001005',  'tariq.m@medicore.pk');

INSERT INTO staff (dept_id, name,                role,             shift,     phone,           email)
VALUES (1, 'Faisal Usman',                       'Pharmacist',     'Evening', '0300-3001006',  'faisal.u@medicore.pk');

INSERT INTO staff (dept_id, name,                role,             shift,     phone,           email)
VALUES (5, 'Saadia Hussain',                     'Nurse',          'Night',   '0336-3001007',  'saadia.h@medicore.pk');

INSERT INTO staff (dept_id, name,                role,             shift,     phone,           email)
VALUES (2, 'Omer Khalid',                        'Admin',          'Morning', '0311-3001008',  'omer.k@medicore.pk');

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 8  :  PATIENTS  (15 rows)
--  No FK dependencies
-- ??????????????????????????????????????????????

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Ayesha Khan',                   TO_DATE('1992-03-14','YYYY-MM-DD'),'B+',        '0300-4001001',  'ayesha.khan@gmail.com',     'House 12, Block 5, Gulshan-e-Iqbal',  'Tariq Khan',            '0321-4001001');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Muhammad Usman',                TO_DATE('1985-07-22','YYYY-MM-DD'),'O+',        '0321-4001002',  'usman85@hotmail.com',       'Flat 3B, Clifton Block 2',            'Nadia Usman',           '0333-4001002');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Sadia Rehman',                  TO_DATE('1998-11-05','YYYY-MM-DD'),'A-',        '0333-4001003',  'sadia.r@yahoo.com',         'Plot 44, North Nazimabad Block J',    'Asif Rehman',           '0312-4001003');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Kamil Zuberi',                  TO_DATE('1970-01-30','YYYY-MM-DD'),'AB+',       '0312-4001004',  NULL,                        'House 7, PECHS Block 6',              'Rabia Zuberi',          '0345-4001004');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Noor Fatima',                   TO_DATE('2000-09-18','YYYY-MM-DD'),'O-',        '0345-4001005',  'noorfatima@gmail.com',      'Apartment 5C, Defence Phase 6',       'Zafar Fatima',          '0300-4001005');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Hassan Raza',                   TO_DATE('1988-04-12','YYYY-MM-DD'),'B-',        '0336-4001006',  'hassan.raza@outlook.com',   'Street 9, Landhi Industrial Area',    'Mehwish Raza',          '0311-4001006');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Mariam Akhtar',                 TO_DATE('1995-06-25','YYYY-MM-DD'),'A+',        '0311-4001007',  'mariam.akhtar@gmail.com',   'House 88, Bahadurabad',               'Salman Akhtar',         '0300-4001007');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Junaid Malik',                  TO_DATE('1979-12-03','YYYY-MM-DD'),'O+',        '0300-4001008',  NULL,                        'Bungalow 2, KDA Scheme 1',            'Amber Malik',           '0321-4001008');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Fareeha Siddiqui',              TO_DATE('2003-08-17','YYYY-MM-DD'),'AB-',       '0321-4001009',  'fareeha.s@gmail.com',       'Flat 12, Gulistan-e-Jauhar Block 15', 'Irfan Siddiqui',        '0333-4001009');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Adnan Shaikh',                  TO_DATE('1967-02-28','YYYY-MM-DD'),'B+',        '0333-4001010',  'adnan.shaikh@hotmail.com',  'House 34, Model Colony',              'Rubina Shaikh',         '0312-4001010');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Zara Hafeez',                   TO_DATE('1993-05-09','YYYY-MM-DD'),'A+',        '0312-4001011',  'zara.hafeez@gmail.com',     'Plot 7, Malir Cantonment',            'Bilal Hafeez',          '0345-4001011');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Rizwan Ahmed',                  TO_DATE('1982-10-14','YYYY-MM-DD'),'O+',        '0345-4001012',  'rizwan.ahmed@yahoo.com',    'House 19, Korangi Crossing',          'Shahida Ahmed',         '0336-4001012');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Bushra Nawaz',                  TO_DATE('1975-03-21','YYYY-MM-DD'),'B+',        '0336-4001013',  NULL,                        'Apartment 8A, Askari 4, Karachi',     'Nawaz Ahmad',           '0311-4001013');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Saad Farhan',                   TO_DATE('2001-07-11','YYYY-MM-DD'),'AB+',       '0311-4001014',  'saad.farhan@gmail.com',     'Street 3, Federal B Area Block 18',   'Huma Farhan',           '0300-4001014');

INSERT INTO patient (name,               dob,                               blood_group, phone,           email,                       address,                               emergency_contact_name,  emergency_contact_phone)
VALUES ('Lubna Tariq',                   TO_DATE('1960-11-30','YYYY-MM-DD'),'O-',        '0300-4001015',  'lubna.tariq@outlook.com',   'House 55, Nazimabad No.3',            'Tariq Hussain',         '0321-4001015');

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 9  :  APPOINTMENTS  (20 rows)
--  FK: patient_id, doctor_id, room_id
--  doctor_id: 1=Murtaza(Card), 2=Sana(Card), 3=Farhan(Neuro),
--             4=Nadia(Neuro),  5=Imran(Ortho), 6=Zainab(Gyn),
--             7=Bilal(ER),     8=Hina(Gyn)
--  room_id:   1=Card GW, 2=Card ICU, 3=Neuro Consult, 4=Neuro GW,
--             5=Ortho OT, 6=Ortho Recovery, 7=Gyn GW, 8=ER
-- ??????????????????????????????????????????????

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (1,  1, 1,  TO_TIMESTAMP('2025-01-10 09:00:00','YYYY-MM-DD HH24:MI:SS'), 'Consultation', 'Completed',   'Initial cardiac assessment. ECG ordered.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (2,  1, 1,  TO_TIMESTAMP('2025-01-10 10:00:00','YYYY-MM-DD HH24:MI:SS'), 'Follow-up',    'Completed',   'Post-angioplasty follow-up. BP stable.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (3,  2, 3,  TO_TIMESTAMP('2025-01-11 09:30:00','YYYY-MM-DD HH24:MI:SS'), 'Consultation', 'Completed',   'Palpitations and dizziness reported.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (4,  3, 3,  TO_TIMESTAMP('2025-01-11 11:00:00','YYYY-MM-DD HH24:MI:SS'), 'Consultation', 'Completed',   'Severe migraines since 2 weeks.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (5,  3, 4,  TO_TIMESTAMP('2025-01-12 08:00:00','YYYY-MM-DD HH24:MI:SS'), 'Emergency',    'Completed',   'Seizure episode. Admitted for observation.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (6,  5, 5,  TO_TIMESTAMP('2025-01-13 07:30:00','YYYY-MM-DD HH24:MI:SS'), 'Surgery',      'Completed',   'Right knee replacement surgery.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (7,  6, 7,  TO_TIMESTAMP('2025-01-14 10:00:00','YYYY-MM-DD HH24:MI:SS'), 'Consultation', 'Completed',   'Antenatal checkup at 28 weeks.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (8,  7, 8,  TO_TIMESTAMP('2025-01-14 14:00:00','YYYY-MM-DD HH24:MI:SS'), 'Emergency',    'Completed',   'Road traffic accident. Laceration & fracture.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (9,  4, 3,  TO_TIMESTAMP('2025-01-15 09:00:00','YYYY-MM-DD HH24:MI:SS'), 'Consultation', 'Completed',   'MRI brain recommended for recurring headache.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (10, 1, 2,  TO_TIMESTAMP('2025-01-15 11:30:00','YYYY-MM-DD HH24:MI:SS'), 'Follow-up',    'Completed',   'Heart failure management. Diuretics adjusted.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (11, 8, 7,  TO_TIMESTAMP('2025-01-16 09:00:00','YYYY-MM-DD HH24:MI:SS'), 'Consultation', 'Completed',   'Abnormal cervical smear follow-up.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (12, 2, 1,  TO_TIMESTAMP('2025-01-16 10:30:00','YYYY-MM-DD HH24:MI:SS'), 'Lab Visit',    'Completed',   'Holter monitor fitting for arrhythmia.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (13, 5, 6,  TO_TIMESTAMP('2025-01-17 08:30:00','YYYY-MM-DD HH24:MI:SS'), 'Follow-up',    'Completed',   'Post-op recovery review after spinal fusion.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (14, 6, 7,  TO_TIMESTAMP('2025-01-17 11:00:00','YYYY-MM-DD HH24:MI:SS'), 'Consultation', 'Completed',   'Menstrual irregularity and hormone panel.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (15, 7, 8,  TO_TIMESTAMP('2025-01-18 02:00:00','YYYY-MM-DD HH24:MI:SS'), 'Emergency',    'Completed',   'Acute appendicitis. Referred to surgery.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (1,  1, 1,  TO_TIMESTAMP('2025-02-05 09:00:00','YYYY-MM-DD HH24:MI:SS'), 'Follow-up',    'Completed',   'Monthly cardiac review. Cholesterol improved.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (3,  2, NULL, TO_TIMESTAMP('2025-02-10 10:00:00','YYYY-MM-DD HH24:MI:SS'),'Follow-up',   'Scheduled',   'Holter monitor results review.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (7,  6, 7,  TO_TIMESTAMP('2025-02-12 10:00:00','YYYY-MM-DD HH24:MI:SS'), 'Follow-up',    'Confirmed',   'Antenatal checkup at 32 weeks.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (9,  4, 3,  TO_TIMESTAMP('2025-02-14 09:00:00','YYYY-MM-DD HH24:MI:SS'), 'Imaging',      'Scheduled',   'MRI brain results discussion.');

INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime,                                       appointment_type, status,       notes)
VALUES (11, 8, 7,  TO_TIMESTAMP('2025-02-18 09:30:00','YYYY-MM-DD HH24:MI:SS'), 'Follow-up',    'Scheduled',   'Colposcopy biopsy results review.');

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 10  :  PRESCRIPTIONS  (8 rows)
--  FK: appointment_id ? appointment(appointment_id)
--  Only for completed appointments (one prescription per appointment)
-- ??????????????????????????????????????????????

INSERT INTO prescription (appointment_id, prescribed_date, notes)
VALUES (1,  TO_DATE('2025-01-10','YYYY-MM-DD'), 'Take with meals. Avoid NSAIDs. Follow-up in 4 weeks.');

INSERT INTO prescription (appointment_id, prescribed_date, notes)
VALUES (2,  TO_DATE('2025-01-10','YYYY-MM-DD'), 'Continue antiplatelets. Low-sodium diet advised.');

INSERT INTO prescription (appointment_id, prescribed_date, notes)
VALUES (3,  TO_DATE('2025-01-11','YYYY-MM-DD'), 'Beta-blocker initiated. Avoid caffeine.');

INSERT INTO prescription (appointment_id, prescribed_date, notes)
VALUES (4,  TO_DATE('2025-01-11','YYYY-MM-DD'), 'Analgesic prescribed. Neurology review in 2 weeks.');

INSERT INTO prescription (appointment_id, prescribed_date, notes)
VALUES (6,  TO_DATE('2025-01-13','YYYY-MM-DD'), 'Post-surgical pain management. Physiotherapy referral.');

INSERT INTO prescription (appointment_id, prescribed_date, notes)
VALUES (7,  TO_DATE('2025-01-14','YYYY-MM-DD'), 'Prenatal vitamins. Iron supplementation added.');

INSERT INTO prescription (appointment_id, prescribed_date, notes)
VALUES (8,  TO_DATE('2025-01-14','YYYY-MM-DD'), 'IV antibiotics for 5 days. Pain management.');

INSERT INTO prescription (appointment_id, prescribed_date, notes)
VALUES (10, TO_DATE('2025-01-15','YYYY-MM-DD'), 'Furosemide dose increased. Salt restriction.');

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 11  :  PRESCRIPTION_DETAIL  (12 rows)
--  FK: prescription_id, medicine_id
--  prescription_id: 1-8 (from above), medicine_id: 1-10
-- ??????????????????????????????????????????????

-- Prescription 1 (Appt 1 - Ayesha - Cardiology)
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (1, 1,  '75mg once daily after breakfast',              30,  30);
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (1, 2,  '20mg once daily at night',                     30,  30);

-- Prescription 2 (Appt 2 - Usman - Cardiology follow-up)
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (2, 1,  '75mg once daily',                              30,  30);
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (2, 4,  '5mg once daily at night',                      30,  30);

-- Prescription 3 (Appt 3 - Sadia - Cardiology)
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (3, 3,  '50mg twice daily with meals',                  14,  28);
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (3, 6,  '20mg once daily before breakfast',             14,  14);

-- Prescription 4 (Appt 4 - Kamil - Neurology)
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (4, 5,  '75mg twice daily after meals',                 7,   14);
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (4, 10, '500mg every 6 hours if needed',                5,   20);

-- Prescription 5 (Appt 6 - Hassan - Orthopaedics)
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (5, 8,  '10mg IV every 4 hours as needed',              3,   18);
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (5, 7,  '500ml IV infusion over 6 hours',               5,   5);

-- Prescription 6 (Appt 7 - Mariam - Gynaecology)
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (6, 10, '500mg twice daily',                            30,  60);

-- Prescription 8 (Appt 10 - Adnan - Cardiology)
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (8, 4,  '10mg once daily',                              30,  30);
INSERT INTO prescription_detail (prescription_id, medicine_id, dosage,                  duration_days, quantity_issued)
VALUES (8, 2,  '40mg once daily at night',                     30,  30);

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 12  :  LAB_TESTS  (8 rows)
--  FK: patient_id, ordered_by (doctor_id), appointment_id
-- ??????????????????????????????????????????????

INSERT INTO lab_test (patient_id, ordered_by, appointment_id, test_name,                    result,                                  result_date,                          status)
VALUES (1,  1, 1,  'Lipid Profile',                           'LDL: 145 mg/dL (High)',     TO_DATE('2025-01-12','YYYY-MM-DD'),   'Completed');

INSERT INTO lab_test (patient_id, ordered_by, appointment_id, test_name,                    result,                                  result_date,                          status)
VALUES (2,  1, 2,  '12-Lead ECG',                             'Sinus rhythm, no ST changes', TO_DATE('2025-01-10','YYYY-MM-DD'), 'Completed');

INSERT INTO lab_test (patient_id, ordered_by, appointment_id, test_name,                    result,                                  result_date,                          status)
VALUES (4,  3, 4,  'MRI Brain with Contrast',                 NULL,                         NULL,                                  'Pending');

INSERT INTO lab_test (patient_id, ordered_by, appointment_id, test_name,                    result,                                  result_date,                          status)
VALUES (5,  3, 5,  'EEG - Electroencephalogram',              'Abnormal sharp waves, left temporal lobe', TO_DATE('2025-01-13','YYYY-MM-DD'), 'Completed');

INSERT INTO lab_test (patient_id, ordered_by, appointment_id, test_name,                    result,                                  result_date,                          status)
VALUES (8,  7, 8,  'X-Ray Right Femur',                       'Hairline fracture at neck of femur', TO_DATE('2025-01-14','YYYY-MM-DD'), 'Completed');

INSERT INTO lab_test (patient_id, ordered_by, appointment_id, test_name,                    result,                                  result_date,                          status)
VALUES (9,  4, 9,  'MRI Brain Without Contrast',              NULL,                         NULL,                                  'In Progress');

INSERT INTO lab_test (patient_id, ordered_by, appointment_id, test_name,                    result,                                  result_date,                          status)
VALUES (12, 2, 12, 'Holter Monitor 24hr',                     NULL,                         NULL,                                  'In Progress');

INSERT INTO lab_test (patient_id, ordered_by, appointment_id, test_name,                    result,                                  result_date,                          status)
VALUES (11, 8, 11, 'Colposcopy & Biopsy',                     'CIN Grade 1 - Low risk',    TO_DATE('2025-01-20','YYYY-MM-DD'),   'Completed');

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 13  :  INVOICES  (8 rows)
--  FK: patient_id ? patient(patient_id)
-- ??????????????????????????????????????????????

INSERT INTO invoice (patient_id, issue_date,                          due_date,                             total_amount, amount_paid, payment_status)
VALUES (1,  TO_DATE('2025-01-10','YYYY-MM-DD'), TO_DATE('2025-02-10','YYYY-MM-DD'), 5500.00,   5500.00,  'Paid');

INSERT INTO invoice (patient_id, issue_date,                          due_date,                             total_amount, amount_paid, payment_status)
VALUES (2,  TO_DATE('2025-01-10','YYYY-MM-DD'), TO_DATE('2025-02-10','YYYY-MM-DD'), 3200.00,   1600.00,  'Partially Paid');

INSERT INTO invoice (patient_id, issue_date,                          due_date,                             total_amount, amount_paid, payment_status)
VALUES (6,  TO_DATE('2025-01-13','YYYY-MM-DD'), TO_DATE('2025-02-13','YYYY-MM-DD'), 85000.00,  85000.00, 'Paid');

INSERT INTO invoice (patient_id, issue_date,                          due_date,                             total_amount, amount_paid, payment_status)
VALUES (7,  TO_DATE('2025-01-14','YYYY-MM-DD'), TO_DATE('2025-02-14','YYYY-MM-DD'), 2800.00,   0.00,     'Unpaid');

INSERT INTO invoice (patient_id, issue_date,                          due_date,                             total_amount, amount_paid, payment_status)
VALUES (8,  TO_DATE('2025-01-14','YYYY-MM-DD'), TO_DATE('2025-02-14','YYYY-MM-DD'), 15000.00,  15000.00, 'Paid');

INSERT INTO invoice (patient_id, issue_date,                          due_date,                             total_amount, amount_paid, payment_status)
VALUES (10, TO_DATE('2025-01-15','YYYY-MM-DD'), TO_DATE('2025-02-15','YYYY-MM-DD'), 4200.00,   4200.00,  'Paid');

INSERT INTO invoice (patient_id, issue_date,                          due_date,                             total_amount, amount_paid, payment_status)
VALUES (11, TO_DATE('2025-01-16','YYYY-MM-DD'), TO_DATE('2025-02-16','YYYY-MM-DD'), 12000.00,  6000.00,  'Partially Paid');

INSERT INTO invoice (patient_id, issue_date,                          due_date,                             total_amount, amount_paid, payment_status)
VALUES (15, TO_DATE('2025-01-18','YYYY-MM-DD'), TO_DATE('2025-02-18','YYYY-MM-DD'), 22000.00,  0.00,     'Unpaid');

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 14  :  INSURANCE_CLAIMS  (4 rows)
--  FK: invoice_id ? invoice(invoice_id)
--  1 claim per invoice (UNIQUE constraint)
-- ??????????????????????????????????????????????

INSERT INTO insurance_claim (invoice_id, provider_name,                  claim_amount, claim_status,      submitted_at,                                               resolved_at)
VALUES (1,  'EFU Life Assurance Ltd',            4500.00,  'Paid',            TO_TIMESTAMP('2025-01-11 10:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-01-20 14:00:00','YYYY-MM-DD HH24:MI:SS'));

INSERT INTO insurance_claim (invoice_id, provider_name,                  claim_amount, claim_status,      submitted_at,                                               resolved_at)
VALUES (3,  'Jubilee Life Insurance',             70000.00, 'Approved',        TO_TIMESTAMP('2025-01-14 09:00:00','YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-01-25 11:00:00','YYYY-MM-DD HH24:MI:SS'));

INSERT INTO insurance_claim (invoice_id, provider_name,                  claim_amount, claim_status,      submitted_at,                                               resolved_at)
VALUES (5,  'State Life Insurance Pakistan',      12000.00, 'Under Review',    TO_TIMESTAMP('2025-01-15 08:30:00','YYYY-MM-DD HH24:MI:SS'), NULL);

INSERT INTO insurance_claim (invoice_id, provider_name,                  claim_amount, claim_status,      submitted_at,                                               resolved_at)
VALUES (7,  'Adamjee Insurance Company',          10000.00, 'Submitted',       TO_TIMESTAMP('2025-01-17 12:00:00','YYYY-MM-DD HH24:MI:SS'), NULL);

COMMIT;


-- ??????????????????????????????????????????????
--  SECTION 15  :  ALERTS  (3 rows)
--  Normally auto-populated by trigger, but sample data added manually
--  FK: medicine_id ? medicine_inventory(medicine_id)
-- ??????????????????????????????????????????????

INSERT INTO alerts (medicine_id, triggered_at,                                               alert_message,                                                                                    resolved, resolved_at)
VALUES (8, TO_TIMESTAMP('2025-01-16 07:00:00','YYYY-MM-DD HH24:MI:SS'), 'LOW STOCK: Morphine Sulphate 10mg has fallen to 8 ampoules (threshold: 15).',     1, TO_TIMESTAMP('2025-01-16 11:00:00','YYYY-MM-DD HH24:MI:SS'));

INSERT INTO alerts (medicine_id, triggered_at,                                               alert_message,                                                                                    resolved, resolved_at)
VALUES (9, TO_TIMESTAMP('2025-01-17 08:00:00','YYYY-MM-DD HH24:MI:SS'), 'LOW STOCK: Ceftriaxone 1g has fallen to 15 vials (threshold: 20).',               0, NULL);

INSERT INTO alerts (medicine_id, triggered_at,                                               alert_message,                                                                                    resolved, resolved_at)
VALUES (7, TO_TIMESTAMP('2025-01-18 06:30:00','YYYY-MM-DD HH24:MI:SS'), 'LOW STOCK: Normal Saline 0.9% has fallen to 18 ml units (threshold: 20).',        0, NULL);

COMMIT;


-- =============================================================================
--  VERIFICATION QUERIES  (Run these to confirm data inserted correctly)
-- =============================================================================

-- Quick row count check
SELECT 'department'        AS tbl, COUNT(*) AS rows FROM department        UNION ALL
SELECT 'doctor'            AS tbl, COUNT(*) AS rows FROM doctor            UNION ALL
SELECT 'supplier'          AS tbl, COUNT(*) AS rows FROM supplier          UNION ALL
SELECT 'medicine_inventory'AS tbl, COUNT(*) AS rows FROM medicine_inventory UNION ALL
SELECT 'room'              AS tbl, COUNT(*) AS rows FROM room              UNION ALL
SELECT 'staff'             AS tbl, COUNT(*) AS rows FROM staff             UNION ALL
SELECT 'patient'           AS tbl, COUNT(*) AS rows FROM patient           UNION ALL
SELECT 'appointment'       AS tbl, COUNT(*) AS rows FROM appointment       UNION ALL
SELECT 'prescription'      AS tbl, COUNT(*) AS rows FROM prescription      UNION ALL
SELECT 'prescription_detail'AS tbl,COUNT(*) AS rows FROM prescription_detail UNION ALL
SELECT 'lab_test'          AS tbl, COUNT(*) AS rows FROM lab_test          UNION ALL
SELECT 'invoice'           AS tbl, COUNT(*) AS rows FROM invoice           UNION ALL
SELECT 'insurance_claim'   AS tbl, COUNT(*) AS rows FROM insurance_claim   UNION ALL
SELECT 'alerts'            AS tbl, COUNT(*) AS rows FROM alerts;

-- =============================================================================
--  END OF DML
-- =============================================================================













--phase 3:


-- ?????????????????????????????????????????
-- VIEW 1: Doctor Roster with Department
-- ?????????????????????????????????????????
CREATE OR REPLACE VIEW v_doctor_roster AS
SELECT
    d.doctor_id,
    d.name            AS doctor_name,
    d.specialization,
    d.license_no,
    dep.dept_name     AS department
FROM doctor d
JOIN department dep ON d.dept_id = dep.dept_id;


-- ?????????????????????????????????????????
-- VIEW 2: Patient Privacy (hides phone & address)
-- ?????????????????????????????????????????
CREATE OR REPLACE VIEW v_patient_privacy AS
SELECT
    patient_id,
    name              AS patient_name,
    dob,
    blood_group,
    email
FROM patient;


-- ?????????????????????????????????????????
-- VIEW 3: Unpaid Invoices with Patient Names
-- ?????????????????????????????????????????
-- ?????????????????????????????????????????
-- VIEW 1: Doctor Roster with Department
-- ?????????????????????????????????????????
CREATE OR REPLACE VIEW v_doctor_roster AS
SELECT
    d.doctor_id,
    d.name            AS doctor_name,
    d.specialization,
    d.license_no,
    dep.dept_name     AS department
FROM doctor d
JOIN department dep ON d.dept_id = dep.dept_id;


-- ?????????????????????????????????????????
-- VIEW 2: Patient Privacy (hides phone & address)
-- ?????????????????????????????????????????
CREATE OR REPLACE VIEW v_patient_privacy AS
SELECT
    patient_id,
    name              AS patient_name,
    dob,
    blood_group,
    email
FROM patient;


-- ?????????????????????????????????????????
-- VIEW 3: Unpaid Invoices with Patient Names
-- ?????????????????????????????????????????
CREATE OR REPLACE VIEW v_unpaid_invoices AS
SELECT
    i.invoice_id,
    p.name            AS patient_name,
    i.issue_date,
    i.due_date,
    i.total_amount,
    i.amount_paid,
    i.payment_status
FROM invoice i
JOIN patient p ON i.patient_id = p.patient_id
WHERE i.payment_status = 'Unpaid';


SELECT * FROM v_doctor_roster;
SELECT * FROM v_patient_privacy;
SELECT * FROM v_unpaid_invoices;










--PHASE 3(A):


-- =============================================================================
--  MediCore HMS  --  PHASE 3A : STORED PROCEDURES
--  Course : CS-2005 Database Systems | FAST NUCES Karachi
--  Run this AFTER DDL and INSERT files have been executed
-- =============================================================================


-- ??????????????????????????????????????????????
--  PROCEDURE 1 : Book an Appointment
--  Prevents double-booking at procedure level too.
--  Usage: EXEC sp_book_appointment(1, 2, 1, TIMESTAMP, 'Consultation');
-- ??????????????????????????????????????????????
CREATE OR REPLACE PROCEDURE sp_book_appointment (
    p_patient_id      IN NUMBER,
    p_doctor_id       IN NUMBER,
    p_room_id         IN NUMBER,
    p_appt_datetime   IN TIMESTAMP,
    p_appt_type       IN VARCHAR2
)
AS
    v_conflict NUMBER;
BEGIN
    -- Check for doctor double-booking
    SELECT COUNT(*) INTO v_conflict
    FROM appointment
    WHERE doctor_id = p_doctor_id
      AND appt_datetime = p_appt_datetime;

    IF v_conflict > 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'ERROR: Doctor is already booked at this time slot.');
    END IF;

    -- Check for room double-booking
    SELECT COUNT(*) INTO v_conflict
    FROM appointment
    WHERE room_id = p_room_id
      AND appt_datetime = p_appt_datetime;

    IF v_conflict > 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'ERROR: Room is already booked at this time slot.');
    END IF;

    -- Insert the appointment
    INSERT INTO appointment (
        patient_id, doctor_id, room_id,
        appt_datetime, appointment_type, status
    ) VALUES (
        p_patient_id, p_doctor_id, p_room_id,
        p_appt_datetime, p_appt_type, 'Scheduled'
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Appointment booked. ID = ' ||
                          TO_CHAR(seq_appointment.CURRVAL));
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_book_appointment;
/


-- ??????????????????????????????????????????????
--  PROCEDURE 2 : Process Billing (ACID Transaction)
--  Creates invoice + insurance claim atomically.
--  If claim INSERT fails, invoice INSERT is rolled back.
-- ??????????????????????????????????????????????
CREATE OR REPLACE PROCEDURE sp_process_billing (
    p_patient_id      IN NUMBER,
    p_total_amount    IN NUMBER,
    p_amount_paid     IN NUMBER,
    p_provider_name   IN VARCHAR2,   -- Insurance provider (NULL if no insurance)
    p_claim_amount    IN NUMBER      -- 0 if no insurance claim
)
AS
    v_invoice_id   NUMBER;
    v_status       VARCHAR2(20);
BEGIN
    -- Determine payment status
    IF p_amount_paid = 0 THEN
        v_status := 'Unpaid';
    ELSIF p_amount_paid >= p_total_amount THEN
        v_status := 'Paid';
    ELSE
        v_status := 'Partially Paid';
    END IF;

    -- SAVEPOINT before invoice insert
    SAVEPOINT sp_before_invoice;

    INSERT INTO invoice (patient_id, total_amount, amount_paid, payment_status)
    VALUES (p_patient_id, p_total_amount, p_amount_paid, v_status)
    RETURNING invoice_id INTO v_invoice_id;

    DBMS_OUTPUT.PUT_LINE('Invoice created. ID = ' || v_invoice_id);

    -- Insert insurance claim only if provider is given
    IF p_provider_name IS NOT NULL AND p_claim_amount > 0 THEN

        SAVEPOINT sp_before_claim;

        BEGIN
            INSERT INTO insurance_claim (
                invoice_id, provider_name, claim_amount, claim_status
            ) VALUES (
                v_invoice_id, p_provider_name, p_claim_amount, 'Submitted'
            );
            DBMS_OUTPUT.PUT_LINE('Insurance claim submitted for Rs. ' ||
                                  TO_CHAR(p_claim_amount));
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK TO sp_before_claim;
                DBMS_OUTPUT.PUT_LINE('WARNING: Claim insert failed. Invoice retained.');
        END;

    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Billing completed successfully.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_before_invoice;
        DBMS_OUTPUT.PUT_LINE('ERROR: Billing failed. All changes rolled back.');
        RAISE;
END sp_process_billing;
/


-- ??????????????????????????????????????????????
--  PROCEDURE 3 : Dispense Medicine (triggers low-stock alert)
--  Deducts quantity from medicine_inventory.
--  The low_stock_alert TRIGGER fires automatically after this.
-- ??????????????????????????????????????????????
CREATE OR REPLACE PROCEDURE sp_dispense_medicine (
    p_medicine_id    IN NUMBER,
    p_quantity       IN NUMBER
)
AS
    v_available NUMBER;
    v_name      VARCHAR2(200);
BEGIN
    SELECT quantity_available, medicine_name
    INTO v_available, v_name
    FROM medicine_inventory
    WHERE medicine_id = p_medicine_id;

    IF v_available < p_quantity THEN
        RAISE_APPLICATION_ERROR(-20003,
            'ERROR: Insufficient stock for ' || v_name ||
            '. Available: ' || v_available);
    END IF;

    UPDATE medicine_inventory
    SET quantity_available = quantity_available - p_quantity
    WHERE medicine_id = p_medicine_id;

    -- low_stock_alert TRIGGER fires automatically here if threshold crossed

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Dispensed ' || p_quantity || ' units of ' || v_name);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'ERROR: Medicine ID not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_dispense_medicine;
/


-- ??????????????????????????????????????????????
--  PROCEDURE 4 : Resolve an Alert
--  Marks an alert as resolved (sets resolved=1, resolved_at=SYSTIMESTAMP)
-- ??????????????????????????????????????????????
CREATE OR REPLACE PROCEDURE sp_resolve_alert (p_alert_id IN NUMBER)
AS
BEGIN
    UPDATE alerts
    SET resolved    = 1,
        resolved_at = SYSTIMESTAMP
    WHERE alert_id  = p_alert_id;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'ERROR: Alert ID not found.');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Alert ' || p_alert_id || ' marked as resolved.');
END sp_resolve_alert;
/


-- =============================================================================
-- PHASE 3A: ACID-COMPLIANT STORED PROCEDURE
-- Handles the complex transaction of discharging a patient
-- =============================================================================

CREATE OR REPLACE PROCEDURE PROC_PATIENT_DISCHARGE (
    p_patient_id IN NUMBER
) AS
    v_room_id NUMBER;
BEGIN
    -- 1. Identify the room assigned to the patient's latest appointment
    SELECT room_id INTO v_room_id
    FROM (SELECT room_id FROM appointment 
          WHERE patient_id = p_patient_id 
          AND status IN ('Confirmed', 'In Progress')
          ORDER BY appt_datetime DESC)
    WHERE ROWNUM = 1;

    -- 2. Transaction Start: Update Room Occupancy
    UPDATE room 
    SET current_occupancy = current_occupancy - 1
    WHERE room_id = v_room_id;

    -- 3. Update Invoice Status
    UPDATE invoice
    SET payment_status = 'Paid',
        amount_paid = total_amount
    WHERE patient_id = p_patient_id 
    AND payment_status != 'Paid';

    -- 4. Update Appointment Status
    UPDATE appointment
    SET status = 'Completed'
    WHERE patient_id = p_patient_id 
    AND status IN ('Confirmed', 'In Progress');

    -- Commit the entire transaction
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Patient ' || p_patient_id || ' discharged successfully. Room ' || v_room_id || ' freed.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: No active appointment/room found for this patient.');
    WHEN OTHERS THEN
        -- Standard ACID Rollback on any failure
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Transaction Failed: Rolling back all changes. Error: ' || SQLERRM);
END;
/

-- ??????????????????????????????????????????????
--  HOW TO CALL STORED PROCEDURES
-- ??????????????????????????????????????????????
-- SET SERVEROUTPUT ON;
--
-- EXEC sp_book_appointment(3, 2, 3,
--      TO_TIMESTAMP('2025-03-01 09:00:00','YYYY-MM-DD HH24:MI:SS'),
--      'Consultation');
--
-- EXEC sp_process_billing(5, 8000, 4000, 'EFU Life Assurance', 3000);
--
-- EXEC sp_dispense_medicine(8, 5);   -- Dispense 5 ampoules of Morphine
--
-- EXEC sp_resolve_alert(2);


-- =============================================================================
--  END OF STORED PROCEDURES
-- =============================================================================














--PHASE 3(B):


-- =============================================================================
--  MediCore HMS  --  PHASE 3B : RBAC VIEWS
--  Role-Based Access Control enforced at the DATABASE level via SQL Views
--  Course : CS-2005 Database Systems | FAST NUCES Karachi
-- =============================================================================


-- ??????????????????????????????????????????????
--  VIEW 1 : vw_doctor_view
--  Role    : DOCTOR
--  Access  : Full medical history, prescriptions, lab results, appointments
--  Hidden  : Financial data (invoices, insurance), addresses
-- ??????????????????????????????????????????????
CREATE OR REPLACE VIEW vw_doctor_view AS
SELECT
    p.patient_id,
    p.name                      AS patient_name,
    p.dob,
    p.blood_group,
    p.email                     AS patient_email,
    a.appointment_id,
    a.appt_datetime,
    a.appointment_type,
    a.status                    AS appointment_status,
    a.notes                     AS appointment_notes,
    d.name                      AS doctor_name,
    d.specialization,
    pr.prescription_id,
    pr.prescribed_date,
    pr.notes                    AS prescription_notes,
    mi.medicine_name,
    pd.dosage,
    pd.duration_days,
    lt.test_name,
    lt.result                   AS lab_result,
    lt.result_date,
    lt.status                   AS lab_status
FROM patient p
JOIN appointment  a  ON p.patient_id      = a.patient_id
JOIN doctor       d  ON a.doctor_id       = d.doctor_id
LEFT JOIN prescription    pr ON a.appointment_id  = pr.appointment_id
LEFT JOIN prescription_detail pd ON pr.prescription_id = pd.prescription_id
LEFT JOIN medicine_inventory  mi ON pd.medicine_id     = mi.medicine_id
LEFT JOIN lab_test  lt ON a.appointment_id = lt.appointment_id;

COMMENT ON TABLE vw_doctor_view IS 'RBAC View for Doctor role. Full medical access. No financial data.';


-- ??????????????????????????????????????????????
--  VIEW 2 : vw_nurse_view
--  Role    : NURSE
--  Access  : Patient name, room, appointment status, current medications
--  Hidden  : Full diagnosis, lab results, financial data, personal contact
-- ??????????????????????????????????????????????
CREATE OR REPLACE VIEW vw_nurse_view AS
SELECT
    p.patient_id,
    p.name                      AS patient_name,
    p.blood_group,
    p.emergency_contact_name,
    p.emergency_contact_phone,
    a.appointment_id,
    a.appt_datetime,
    a.appointment_type,
    a.status                    AS appointment_status,
    r.room_type,
    r.room_id,
    dep.dept_name,
    mi.medicine_name,
    pd.dosage,
    pd.duration_days,
    pd.quantity_issued
FROM patient p
JOIN appointment     a   ON p.patient_id       = a.patient_id
LEFT JOIN room       r   ON a.room_id          = r.room_id
LEFT JOIN department dep ON r.dept_id          = dep.dept_id
LEFT JOIN prescription    pr ON a.appointment_id   = pr.appointment_id
LEFT JOIN prescription_detail pd ON pr.prescription_id  = pd.prescription_id
LEFT JOIN medicine_inventory  mi ON pd.medicine_id      = mi.medicine_id;

COMMENT ON TABLE vw_nurse_view IS 'RBAC View for Nurse role. Ward, meds, emergency contacts only. No diagnosis or financials.';


-- ??????????????????????????????????????????????
--  VIEW 3 : vw_accountant_view
--  Role    : ACCOUNTANT
--  Access  : Invoices, payments, insurance claims, patient name only
--  Hidden  : Medical data, diagnosis, prescriptions, lab results
-- ??????????????????????????????????????????????
CREATE OR REPLACE VIEW vw_accountant_view AS
SELECT
    p.patient_id,
    p.name                      AS patient_name,
    i.invoice_id,
    i.issue_date,
    i.due_date,
    i.total_amount,
    i.amount_paid,
    (i.total_amount - i.amount_paid) AS balance_due,
    i.payment_status,
    ic.claim_id,
    ic.provider_name,
    ic.claim_amount,
    ic.claim_status,
    ic.submitted_at,
    ic.resolved_at
FROM patient p
JOIN invoice        i  ON p.patient_id  = i.patient_id
LEFT JOIN insurance_claim ic ON i.invoice_id = ic.invoice_id;

COMMENT ON TABLE vw_accountant_view IS 'RBAC View for Accountant role. Financial data only. No medical records exposed.';


-- ??????????????????????????????????????????????
--  VIEW 4 : vw_pharmacy_view
--  Role    : PHARMACIST
--  Access  : Medicine stock, alerts, prescription details
--  Hidden  : Patient personal info, financials
-- ??????????????????????????????????????????????
CREATE OR REPLACE VIEW vw_pharmacy_view AS
SELECT
    mi.medicine_id,
    mi.medicine_name,
    mi.quantity_available,
    mi.minimum_threshold,
    mi.unit,
    mi.unit_price,
    s.company_name              AS supplier_name,
    s.contact_phone             AS supplier_phone,
    s.lead_time_days,
    CASE
        WHEN mi.quantity_available < mi.minimum_threshold
        THEN 'LOW STOCK'
        ELSE 'OK'
    END                         AS stock_status,
    al.alert_id,
    al.alert_message,
    al.triggered_at,
    al.resolved
FROM medicine_inventory mi
JOIN supplier s ON mi.supplier_id = s.supplier_id
LEFT JOIN alerts al ON mi.medicine_id = al.medicine_id AND al.resolved = 0;

COMMENT ON TABLE vw_pharmacy_view IS 'RBAC View for Pharmacist role. Inventory and unresolved alerts only.';


-- ??????????????????????????????????????????????
--  TEST THE VIEWS
-- ??????????????????????????????????????????????
-- SELECT * FROM vw_doctor_view      WHERE patient_id = 1;
-- SELECT * FROM vw_nurse_view       WHERE appointment_status = 'Confirmed';
-- SELECT * FROM vw_accountant_view  WHERE payment_status = 'Unpaid';
-- SELECT * FROM vw_pharmacy_view    WHERE stock_status = 'LOW STOCK';


-- =============================================================================
--  END OF RBAC VIEWS
-- =============================================================================


















--PHASE 04

-- =============================================================================
--  MediCore HMS  --  PHASE 4 : ADVANCED SQL QUERIES
--  Includes: Joins, Subqueries, Aggregates, Concurrency Control Demo
--  Course : CS-2005 Database Systems | FAST NUCES Karachi
-- =============================================================================


-- ??????????????????????????????????????????????
--  QUERY SET 1 : BASIC JOIN QUERIES
-- ??????????????????????????????????????????????

-- Q1: List all doctors with their department name
-- Relational Algebra: ?(name, specialization, dept_name)(doctor ? department)
SELECT d.name          AS doctor_name,
       d.specialization,
       dep.dept_name   AS department
FROM   doctor d
JOIN   department dep ON d.dept_id = dep.dept_id
ORDER  BY dep.dept_name, d.name;


-- Q2: All appointments with patient name, doctor name, room type
-- Relational Algebra: ?(...)( patient ? appointment ? doctor ? room )
SELECT p.name                AS patient_name,
       d.name                AS doctor_name,
       a.appt_datetime,
       a.appointment_type,
       a.status,
       r.room_type
FROM   appointment a
JOIN   patient     p  ON a.patient_id = p.patient_id
JOIN   doctor      d  ON a.doctor_id  = d.doctor_id
LEFT JOIN room     r  ON a.room_id    = r.room_id
ORDER  BY a.appt_datetime;


-- Q3: Patients with their unpaid invoice amounts
-- Relational Algebra: ?(name, total_amount)( ?(payment_status='Unpaid')(invoice) ? patient )
SELECT p.name          AS patient_name,
       i.invoice_id,
       i.total_amount,
       i.due_date
FROM   invoice  i
JOIN   patient  p ON i.patient_id = p.patient_id
WHERE  i.payment_status = 'Unpaid'
ORDER  BY i.due_date;


-- Q4: Full prescription details — patient, doctor, medicine, dosage
SELECT p.name               AS patient_name,
       d.name               AS prescribed_by,
       mi.medicine_name,
       pd.dosage,
       pd.duration_days,
       pd.quantity_issued,
       pr.prescribed_date
FROM   prescription_detail pd
JOIN   prescription         pr  ON pd.prescription_id = pr.prescription_id
JOIN   appointment          a   ON pr.appointment_id  = a.appointment_id
JOIN   patient              p   ON a.patient_id       = p.patient_id
JOIN   doctor               d   ON a.doctor_id        = d.doctor_id
JOIN   medicine_inventory   mi  ON pd.medicine_id     = mi.medicine_id
ORDER  BY pr.prescribed_date, p.name;


-- ??????????????????????????????????????????????
--  QUERY SET 2 : AGGREGATE & GROUP BY QUERIES
-- ??????????????????????????????????????????????

-- Q5: Number of appointments per doctor
SELECT d.name           AS doctor_name,
       d.specialization,
       COUNT(a.appointment_id) AS total_appointments
FROM   doctor      d
LEFT JOIN appointment a ON d.doctor_id = a.doctor_id
GROUP  BY d.doctor_id, d.name, d.specialization
ORDER  BY total_appointments DESC;


-- Q6: Total revenue collected per department
SELECT dep.dept_name,
       SUM(i.amount_paid)   AS total_collected,
       SUM(i.total_amount)  AS total_billed,
       SUM(i.total_amount - i.amount_paid) AS outstanding
FROM   invoice     i
JOIN   patient     p   ON i.patient_id  = p.patient_id
JOIN   appointment a   ON p.patient_id  = a.patient_id
JOIN   doctor      d   ON a.doctor_id   = d.doctor_id
JOIN   department  dep ON d.dept_id     = dep.dept_id
GROUP  BY dep.dept_id, dep.dept_name
ORDER  BY total_collected DESC;


-- Q7: Medicine stock status summary
SELECT medicine_name,
       quantity_available,
       minimum_threshold,
       unit,
       CASE
           WHEN quantity_available = 0              THEN 'OUT OF STOCK'
           WHEN quantity_available < minimum_threshold THEN 'LOW STOCK'
           WHEN quantity_available < minimum_threshold * 2 THEN 'MODERATE'
           ELSE 'SUFFICIENT'
       END AS stock_status
FROM   medicine_inventory
ORDER  BY quantity_available ASC;


-- Q8: Department-wise patient count (through appointments)
SELECT dep.dept_name,
       COUNT(DISTINCT a.patient_id) AS unique_patients
FROM   appointment  a
JOIN   doctor       d   ON a.doctor_id = d.doctor_id
JOIN   department   dep ON d.dept_id   = dep.dept_id
GROUP  BY dep.dept_id, dep.dept_name
ORDER  BY unique_patients DESC;


-- ??????????????????????????????????????????????
--  QUERY SET 3 : SUBQUERIES
-- ??????????????????????????????????????????????

-- Q9: Patients who have NEVER had a lab test
-- Relational Algebra: patient - ?(patient_id)(lab_test)
SELECT patient_id, name, phone
FROM   patient
WHERE  patient_id NOT IN (SELECT DISTINCT patient_id FROM lab_test)
ORDER  BY name;


-- Q10: Doctors who have NOT issued any prescription
SELECT d.doctor_id, d.name, d.specialization
FROM   doctor d
WHERE  d.doctor_id NOT IN (
    SELECT DISTINCT a.doctor_id
    FROM   appointment  a
    JOIN   prescription p ON a.appointment_id = p.appointment_id
)
ORDER  BY d.name;


-- Q11: Medicines dispensed more than 30 units total
SELECT mi.medicine_name,
       SUM(pd.quantity_issued) AS total_dispensed
FROM   prescription_detail  pd
JOIN   medicine_inventory   mi ON pd.medicine_id = mi.medicine_id
GROUP  BY mi.medicine_id, mi.medicine_name
HAVING SUM(pd.quantity_issued) > 30
ORDER  BY total_dispensed DESC;


-- Q12: Patients who have appointments in more than one department
SELECT p.name              AS patient_name,
       COUNT(DISTINCT d.dept_id) AS departments_visited
FROM   patient      p
JOIN   appointment  a   ON p.patient_id = a.patient_id
JOIN   doctor       d   ON a.doctor_id  = d.doctor_id
GROUP  BY p.patient_id, p.name
HAVING COUNT(DISTINCT d.dept_id) > 1
ORDER  BY departments_visited DESC;


-- ??????????????????????????????????????????????
--  QUERY SET 4 : CONCURRENCY CONTROL DEMO
--  Demonstrates pessimistic locking (SELECT FOR UPDATE)
--  to prevent the double-booking problem described in proposal Section 5
-- ??????????????????????????????????????????????

-- HOW TO TEST (Run in two separate SQL Worksheet sessions simultaneously):
--
-- ?????? SESSION 1 ??????
-- BEGIN
--     -- Acquire exclusive lock on the room's time slot
--     SELECT * FROM appointment
--     WHERE  room_id = 5
--     AND    appt_datetime = TO_TIMESTAMP('2025-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS')
--     FOR UPDATE;
--
--     -- Simulate processing delay (Session 2 will be BLOCKED here)
--     DBMS_LOCK.SLEEP(10);
--
--     INSERT INTO appointment (patient_id, doctor_id, room_id, appt_datetime, appointment_type, status)
--     VALUES (1, 5, 5, TO_TIMESTAMP('2025-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS'), 'Surgery', 'Scheduled');
--
--     COMMIT;   -- Lock is released here; Session 2 unblocks
-- END;
-- /
--
-- ?????? SESSION 2 (run during Session 1's SLEEP) ??????
-- BEGIN
--     -- This will BLOCK until Session 1 commits
--     SELECT * FROM appointment
--     WHERE  room_id = 5
--     AND    appt_datetime = TO_TIMESTAMP('2025-06-01 10:00:00','YYYY-MM-DD HH24:MI:SS')
--     FOR UPDATE;
--
--     -- After Session 1 commits, Session 2 sees the row — detects conflict
--     -- Application layer should ROLLBACK here
--     ROLLBACK;
-- END;
-- /


-- ??????????????????????????????????????????????
--  QUERY SET 5 : OPTIMISTIC CONCURRENCY DEMO
--  Version-stamp approach for low-conflict updates
-- ??????????????????????????????????????????????

-- Step 1: Add a version_stamp column to patient (run once)
-- ALTER TABLE patient ADD version_stamp NUMBER DEFAULT 1 NOT NULL;

-- Step 2: Optimistic Update Pattern
-- Read the row and note the version stamp
-- SELECT patient_id, name, version_stamp FROM patient WHERE patient_id = 1;
-- (assume version_stamp = 3 was read)

-- Step 3: Update only if version matches (no lock held between read and write)
-- UPDATE patient
-- SET    name = 'Ayesha Khan Updated',
--        version_stamp = version_stamp + 1
-- WHERE  patient_id    = 1
-- AND    version_stamp = 3;   -- If another session already updated, this returns 0 rows
--
-- IF SQL%ROWCOUNT = 0 THEN
--     -- Version mismatch: another user updated first ? RETRY
--     RAISE_APPLICATION_ERROR(-20010, 'Conflict detected. Please retry.');
-- END IF;
-- COMMIT;


-- ??????????????????????????????????????????????
--  QUERY SET 6 : USEFUL REPORTING QUERIES
-- ??????????????????????????????????????????????

-- Q13: Monthly appointment summary
SELECT TO_CHAR(appt_datetime, 'YYYY-MM') AS month,
       COUNT(*)                           AS total_appointments,
       SUM(CASE WHEN status = 'Completed'  THEN 1 ELSE 0 END) AS completed,
       SUM(CASE WHEN status = 'Cancelled'  THEN 1 ELSE 0 END) AS cancelled,
       SUM(CASE WHEN status = 'No-Show'    THEN 1 ELSE 0 END) AS no_shows
FROM   appointment
GROUP  BY TO_CHAR(appt_datetime, 'YYYY-MM')
ORDER  BY month;


-- Q14: Top 3 busiest doctors
SELECT d.name, d.specialization, COUNT(a.appointment_id) AS appts
FROM   doctor d JOIN appointment a ON d.doctor_id = a.doctor_id
GROUP  BY d.doctor_id, d.name, d.specialization
ORDER  BY appts DESC
FETCH FIRST 3 ROWS ONLY;


-- Q15: Insurance claim recovery rate per provider
SELECT provider_name,
       COUNT(*)                                        AS total_claims,
       SUM(CASE WHEN claim_status = 'Paid'     THEN 1 ELSE 0 END) AS paid_claims,
       SUM(CASE WHEN claim_status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_claims,
       SUM(claim_amount)                               AS total_claimed,
       SUM(CASE WHEN claim_status = 'Paid' THEN claim_amount ELSE 0 END) AS recovered
FROM   insurance_claim
GROUP  BY provider_name
ORDER  BY recovered DESC;


-- =============================================================================
--  END OF ADVANCED QUERIES
-- =============================================================================



SELECT sys_context('USERENV','SERVICE_NAME') FROM dual;


select *
from patient;
