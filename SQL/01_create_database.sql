/* =========================================================
   SMART CLINIC DATABASE SYSTEM
   Database Creation Script
   DBMS: MySQL 8.0
   ========================================================= */


/* ---------------------------------------------------------
   1. Delete the database if it already exists
   --------------------------------------------------------- */

DROP DATABASE IF EXISTS SmartClinicDB;


/* ---------------------------------------------------------
   2. Create the database
   --------------------------------------------------------- */

CREATE DATABASE SmartClinicDB
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;


/* ---------------------------------------------------------
   3. Select the database
   --------------------------------------------------------- */

USE SmartClinicDB;


/* =========================================================
   TABLE 1: PERSON
   Superclass for Patient and Employee
   ========================================================= */

CREATE TABLE Person (
    PersonID INT UNSIGNED AUTO_INCREMENT,

    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,

    Phone VARCHAR(20),
    Email VARCHAR(100),
    Address VARCHAR(255),

    CONSTRAINT pk_person
        PRIMARY KEY (PersonID),

    CONSTRAINT uq_person_email
        UNIQUE (Email)

) ENGINE = InnoDB;


/* =========================================================
   TABLE 2: PATIENT
   Subclass of Person
   ========================================================= */

CREATE TABLE Patient (
    PatientID INT UNSIGNED,

    DateOfBirth DATE NOT NULL,

    Gender ENUM(
        'Male',
        'Female'
    ) NOT NULL,

    BloodType ENUM(
        'A+',
        'A-',
        'B+',
        'B-',
        'AB+',
        'AB-',
        'O+',
        'O-',
        'Unknown'
    ) DEFAULT 'Unknown',

    CONSTRAINT pk_patient
        PRIMARY KEY (PatientID),

    CONSTRAINT fk_patient_person
        FOREIGN KEY (PatientID)
        REFERENCES Person(PersonID)
        ON UPDATE CASCADE
        ON DELETE CASCADE

) ENGINE = InnoDB;


/* =========================================================
   TABLE 3: EMPLOYEE
   Subclass of Person

   EmployeeType is a discriminator attribute used to implement
   the disjoint specialization between Doctor and Receptionist.
   ========================================================= */

CREATE TABLE Employee (
    EmployeeID INT UNSIGNED,

    HireDate DATE NOT NULL,

    Salary DECIMAL(10, 2) NOT NULL,

    EmployeeType ENUM(
        'Doctor',
        'Receptionist'
    ) NOT NULL,

    CONSTRAINT pk_employee
        PRIMARY KEY (EmployeeID),

    CONSTRAINT fk_employee_person
        FOREIGN KEY (EmployeeID)
        REFERENCES Person(PersonID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_employee_salary
        CHECK (Salary >= 0)

) ENGINE = InnoDB;


/* =========================================================
   TABLE 4: DOCTOR
   Subclass of Employee
   ========================================================= */

CREATE TABLE Doctor (
    DoctorID INT UNSIGNED,

    Specialization VARCHAR(100) NOT NULL,

    LicenseNumber VARCHAR(50) NOT NULL,

    CONSTRAINT pk_doctor
        PRIMARY KEY (DoctorID),

    CONSTRAINT uq_doctor_license
        UNIQUE (LicenseNumber),

    CONSTRAINT fk_doctor_employee
        FOREIGN KEY (DoctorID)
        REFERENCES Employee(EmployeeID)
        ON UPDATE CASCADE
        ON DELETE CASCADE

) ENGINE = InnoDB;


/* =========================================================
   TABLE 5: RECEPTIONIST
   Subclass of Employee
   ========================================================= */

CREATE TABLE Receptionist (
    ReceptionistID INT UNSIGNED,

    Shift ENUM(
        'Morning',
        'Evening',
        'Night'
    ) NOT NULL,

    CONSTRAINT pk_receptionist
        PRIMARY KEY (ReceptionistID),

    CONSTRAINT fk_receptionist_employee
        FOREIGN KEY (ReceptionistID)
        REFERENCES Employee(EmployeeID)
        ON UPDATE CASCADE
        ON DELETE CASCADE

) ENGINE = InnoDB;


/* =========================================================
   TABLE 6: APPOINTMENT
   Relationships:
   - One Patient books many Appointments
   - One Doctor handles many Appointments
   - One Receptionist schedules many Appointments
   ========================================================= */

CREATE TABLE Appointment (
    AppointmentID INT UNSIGNED AUTO_INCREMENT,

    AppointmentDate DATE NOT NULL,

    AppointmentTime TIME NOT NULL,

    Status ENUM(
        'Scheduled',
        'Confirmed',
        'Completed',
        'Cancelled',
        'No Show'
    ) NOT NULL DEFAULT 'Scheduled',

    Reason VARCHAR(500),

    PatientID INT UNSIGNED NOT NULL,

    DoctorID INT UNSIGNED NOT NULL,

    ReceptionistID INT UNSIGNED NOT NULL,

    CONSTRAINT pk_appointment
        PRIMARY KEY (AppointmentID),

    CONSTRAINT fk_appointment_patient
        FOREIGN KEY (PatientID)
        REFERENCES Patient(PatientID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_appointment_doctor
        FOREIGN KEY (DoctorID)
        REFERENCES Doctor(DoctorID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_appointment_receptionist
        FOREIGN KEY (ReceptionistID)
        REFERENCES Receptionist(ReceptionistID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    /*
       Prevents a doctor from having two appointments
       at the same date and time.
    */

    CONSTRAINT uq_doctor_appointment_time
        UNIQUE (
            DoctorID,
            AppointmentDate,
            AppointmentTime
        ),

    /*
       Prevents a patient from having two appointments
       at the same date and time.
    */

    CONSTRAINT uq_patient_appointment_time
        UNIQUE (
            PatientID,
            AppointmentDate,
            AppointmentTime
        )

) ENGINE = InnoDB;


/* =========================================================
   TABLE 7: TREATMENT
   One Appointment may include many Treatments
   ========================================================= */

CREATE TABLE Treatment (
    TreatmentID INT UNSIGNED AUTO_INCREMENT,

    TreatmentName VARCHAR(100) NOT NULL,

    Description VARCHAR(500),

    Cost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,

    AppointmentID INT UNSIGNED NOT NULL,

    CONSTRAINT pk_treatment
        PRIMARY KEY (TreatmentID),

    CONSTRAINT fk_treatment_appointment
        FOREIGN KEY (AppointmentID)
        REFERENCES Appointment(AppointmentID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_treatment_cost
        CHECK (Cost >= 0)

) ENGINE = InnoDB;


/* =========================================================
   TABLE 8: PRESCRIPTION
   One Appointment may generate zero or one Prescription
   ========================================================= */

CREATE TABLE Prescription (
    PrescriptionID INT UNSIGNED AUTO_INCREMENT,

    PrescriptionDate DATE NOT NULL,

    Notes VARCHAR(500),

    AppointmentID INT UNSIGNED NOT NULL,

    CONSTRAINT pk_prescription
        PRIMARY KEY (PrescriptionID),

    /*
       UNIQUE AppointmentID enforces a maximum of one
       prescription for each appointment.
    */

    CONSTRAINT uq_prescription_appointment
        UNIQUE (AppointmentID),

    CONSTRAINT fk_prescription_appointment
        FOREIGN KEY (AppointmentID)
        REFERENCES Appointment(AppointmentID)
        ON UPDATE CASCADE
        ON DELETE CASCADE

) ENGINE = InnoDB;


/* =========================================================
   TABLE 9: MEDICINE
   Stores medicine information and available stock
   ========================================================= */

CREATE TABLE Medicine (
    MedicineID INT UNSIGNED AUTO_INCREMENT,

    MedicineName VARCHAR(100) NOT NULL,

    DosageForm ENUM(
        'Tablet',
        'Capsule',
        'Syrup',
        'Injection',
        'Cream',
        'Ointment',
        'Drops',
        'Inhaler',
        'Other'
    ) NOT NULL,

    UnitPrice DECIMAL(10, 2) NOT NULL DEFAULT 0.00,

    StockQuantity INT UNSIGNED NOT NULL DEFAULT 0,

    CONSTRAINT pk_medicine
        PRIMARY KEY (MedicineID),

    CONSTRAINT uq_medicine_name_form
        UNIQUE (
            MedicineName,
            DosageForm
        ),

    CONSTRAINT chk_medicine_price
        CHECK (UnitPrice >= 0),

    CONSTRAINT chk_medicine_stock
        CHECK (StockQuantity >= 0)

) ENGINE = InnoDB;


/* =========================================================
   TABLE 10: PRESCRIPTION_ITEM
   Associative entity between Prescription and Medicine

   Relationships:
   - One Prescription contains many Prescription Items
   - One Medicine may appear in many Prescription Items
   ========================================================= */

CREATE TABLE Prescription_Item (
    PrescriptionID INT UNSIGNED,

    MedicineID INT UNSIGNED,

    Dosage VARCHAR(100) NOT NULL,

    Frequency VARCHAR(100) NOT NULL,

    Duration VARCHAR(100) NOT NULL,

    CONSTRAINT pk_prescription_item
        PRIMARY KEY (
            PrescriptionID,
            MedicineID
        ),

    CONSTRAINT fk_item_prescription
        FOREIGN KEY (PrescriptionID)
        REFERENCES Prescription(PrescriptionID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_item_medicine
        FOREIGN KEY (MedicineID)
        REFERENCES Medicine(MedicineID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT

) ENGINE = InnoDB;


/* =========================================================
   TABLE 11: PAYMENT
   Relationships:
   - One Patient may make many Payments
   - One Appointment may have zero or one Payment
   ========================================================= */

CREATE TABLE Payment (
    PaymentID INT UNSIGNED AUTO_INCREMENT,

    PaymentDate DATE NOT NULL,

    Amount DECIMAL(10, 2) NOT NULL,

    PaymentMethod ENUM(
        'Cash',
        'Credit Card',
        'Debit Card',
        'Bank Transfer',
        'Insurance'
    ) NOT NULL,

    PaymentStatus ENUM(
        'Pending',
        'Paid',
        'Partially Paid',
        'Cancelled',
        'Refunded'
    ) NOT NULL DEFAULT 'Pending',

    AppointmentID INT UNSIGNED NOT NULL,

    PatientID INT UNSIGNED NOT NULL,

    CONSTRAINT pk_payment
        PRIMARY KEY (PaymentID),

    /*
       UNIQUE AppointmentID enforces zero or one payment
       record for each appointment.
    */

    CONSTRAINT uq_payment_appointment
        UNIQUE (AppointmentID),

    CONSTRAINT fk_payment_appointment
        FOREIGN KEY (AppointmentID)
        REFERENCES Appointment(AppointmentID)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_payment_patient
        FOREIGN KEY (PatientID)
        REFERENCES Patient(PatientID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_payment_amount
        CHECK (Amount > 0)

) ENGINE = InnoDB;


/* =========================================================
   INDEXES
   Improve performance when searching and joining tables
   ========================================================= */

CREATE INDEX idx_person_name
    ON Person (LastName, FirstName);

CREATE INDEX idx_person_phone
    ON Person (Phone);

CREATE INDEX idx_appointment_date
    ON Appointment (AppointmentDate);

CREATE INDEX idx_appointment_status
    ON Appointment (Status);

CREATE INDEX idx_appointment_patient
    ON Appointment (PatientID);

CREATE INDEX idx_appointment_doctor
    ON Appointment (DoctorID);

CREATE INDEX idx_treatment_appointment
    ON Treatment (AppointmentID);

CREATE INDEX idx_prescription_date
    ON Prescription (PrescriptionDate);

CREATE INDEX idx_medicine_name
    ON Medicine (MedicineName);

CREATE INDEX idx_payment_date
    ON Payment (PaymentDate);

CREATE INDEX idx_payment_patient
    ON Payment (PatientID);

CREATE INDEX idx_payment_status
    ON Payment (PaymentStatus);


/* =========================================================
   TRIGGERS FOR DISJOINT SPECIALIZATION

   These triggers ensure:
   - Only employees with EmployeeType = Doctor can be inserted
     into the Doctor table.
   - Only employees with EmployeeType = Receptionist can be
     inserted into the Receptionist table.
   - The same employee cannot belong to both subclasses.
   ========================================================= */

DELIMITER $$


/* ---------------------------------------------------------
   Validate Doctor before insertion
   --------------------------------------------------------- */

CREATE TRIGGER trg_doctor_before_insert
BEFORE INSERT ON Doctor
FOR EACH ROW
BEGIN
    DECLARE employee_type_value VARCHAR(20);
    DECLARE receptionist_count INT DEFAULT 0;

    SELECT EmployeeType
    INTO employee_type_value
    FROM Employee
    WHERE EmployeeID = NEW.DoctorID;

    IF employee_type_value <> 'Doctor' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'EmployeeType must be Doctor before inserting into Doctor.';
    END IF;

    SELECT COUNT(*)
    INTO receptionist_count
    FROM Receptionist
    WHERE ReceptionistID = NEW.DoctorID;

    IF receptionist_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'An employee cannot be both Doctor and Receptionist.';
    END IF;
END$$


/* ---------------------------------------------------------
   Validate Receptionist before insertion
   --------------------------------------------------------- */

CREATE TRIGGER trg_receptionist_before_insert
BEFORE INSERT ON Receptionist
FOR EACH ROW
BEGIN
    DECLARE employee_type_value VARCHAR(20);
    DECLARE doctor_count INT DEFAULT 0;

    SELECT EmployeeType
    INTO employee_type_value
    FROM Employee
    WHERE EmployeeID = NEW.ReceptionistID;

    IF employee_type_value <> 'Receptionist' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'EmployeeType must be Receptionist before inserting into Receptionist.';
    END IF;

    SELECT COUNT(*)
    INTO doctor_count
    FROM Doctor
    WHERE DoctorID = NEW.ReceptionistID;

    IF doctor_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'An employee cannot be both Doctor and Receptionist.';
    END IF;
END$$


/* ---------------------------------------------------------
   Prevent changing a Doctor employee to Receptionist
   while the Doctor record still exists
   --------------------------------------------------------- */

CREATE TRIGGER trg_employee_before_update
BEFORE UPDATE ON Employee
FOR EACH ROW
BEGIN
    DECLARE doctor_count INT DEFAULT 0;
    DECLARE receptionist_count INT DEFAULT 0;

    IF OLD.EmployeeType <> NEW.EmployeeType THEN

        SELECT COUNT(*)
        INTO doctor_count
        FROM Doctor
        WHERE DoctorID = OLD.EmployeeID;

        SELECT COUNT(*)
        INTO receptionist_count
        FROM Receptionist
        WHERE ReceptionistID = OLD.EmployeeID;

        IF doctor_count > 0 AND NEW.EmployeeType <> 'Doctor' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Delete the Doctor subtype record before changing EmployeeType.';
        END IF;

        IF receptionist_count > 0
           AND NEW.EmployeeType <> 'Receptionist' THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Delete the Receptionist subtype record before changing EmployeeType.';
        END IF;

    END IF;
END$$


DELIMITER ;


/* =========================================================
   OPTIONAL VIEW 1:
   Displays complete patient information
   ========================================================= */

CREATE VIEW PatientDetails AS
SELECT
    P.PatientID,
    PE.FirstName,
    PE.LastName,
    PE.Phone,
    PE.Email,
    PE.Address,
    P.DateOfBirth,
    P.Gender,
    P.BloodType
FROM Patient AS P
JOIN Person AS PE
    ON P.PatientID = PE.PersonID;


/* =========================================================
   OPTIONAL VIEW 2:
   Displays complete doctor information
   ========================================================= */

CREATE VIEW DoctorDetails AS
SELECT
    D.DoctorID,
    PE.FirstName,
    PE.LastName,
    PE.Phone,
    PE.Email,
    PE.Address,
    E.HireDate,
    E.Salary,
    D.Specialization,
    D.LicenseNumber
FROM Doctor AS D
JOIN Employee AS E
    ON D.DoctorID = E.EmployeeID
JOIN Person AS PE
    ON E.EmployeeID = PE.PersonID;


/* =========================================================
   OPTIONAL VIEW 3:
   Displays appointment details with names
   ========================================================= */

CREATE VIEW AppointmentDetails AS
SELECT
    A.AppointmentID,

    A.AppointmentDate,
    A.AppointmentTime,
    A.Status,
    A.Reason,

    A.PatientID,

    CONCAT(
        PatientPerson.FirstName,
        ' ',
        PatientPerson.LastName
    ) AS PatientName,

    A.DoctorID,

    CONCAT(
        DoctorPerson.FirstName,
        ' ',
        DoctorPerson.LastName
    ) AS DoctorName,

    D.Specialization,

    A.ReceptionistID,

    CONCAT(
        ReceptionistPerson.FirstName,
        ' ',
        ReceptionistPerson.LastName
    ) AS ReceptionistName

FROM Appointment AS A

JOIN Patient AS P
    ON A.PatientID = P.PatientID

JOIN Person AS PatientPerson
    ON P.PatientID = PatientPerson.PersonID

JOIN Doctor AS D
    ON A.DoctorID = D.DoctorID

JOIN Person AS DoctorPerson
    ON D.DoctorID = DoctorPerson.PersonID

JOIN Receptionist AS R
    ON A.ReceptionistID = R.ReceptionistID

JOIN Person AS ReceptionistPerson
    ON R.ReceptionistID = ReceptionistPerson.PersonID;


/* =========================================================
   Confirm that all tables were created
   ========================================================= */

SHOW TABLES;