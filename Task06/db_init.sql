PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS completed_procedures;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS service_categories;
DROP TABLE IF EXISTS specializations;

CREATE TABLE specializations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE service_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE doctors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    specialization_id INTEGER NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    salary_percent REAL NOT NULL CHECK (salary_percent > 0 AND salary_percent <= 100),
    hire_date TEXT NOT NULL,
    dismissal_date TEXT DEFAULT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'dismissed')),
    CHECK (dismissal_date IS NULL OR dismissal_date >= hire_date),
    CHECK (
        (status = 'active' AND dismissal_date IS NULL) OR
        (status = 'dismissed' AND dismissal_date IS NOT NULL)
    ),
    FOREIGN KEY (specialization_id) REFERENCES specializations(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE patients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    birth_date TEXT
);

CREATE TABLE services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER NOT NULL,
    title TEXT NOT NULL UNIQUE,
    price REAL NOT NULL CHECK (price > 0),
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    FOREIGN KEY (category_id) REFERENCES service_categories(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE appointments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    doctor_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')),
    CHECK (end_time > start_time),
    FOREIGN KEY (doctor_id) REFERENCES doctors(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE completed_procedures (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id INTEGER DEFAULT NULL,
    doctor_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    performed_at TEXT NOT NULL,
    actual_price REAL NOT NULL CHECK (actual_price > 0),
    doctor_percent REAL NOT NULL CHECK (doctor_percent > 0 AND doctor_percent <= 100),
    FOREIGN KEY (appointment_id) REFERENCES appointments(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

BEGIN TRANSACTION;

INSERT INTO specializations (id, name) VALUES
    (1, 'Терапевт'),
    (2, 'Хирург'),
    (3, 'Ортодонт');

INSERT INTO service_categories (id, name) VALUES
    (1, 'Терапевтическая стоматология'),
    (2, 'Хирургическая стоматология'),
    (3, 'Имплантация');

INSERT INTO doctors (id, specialization_id, full_name, phone, salary_percent, hire_date, dismissal_date, status) VALUES
    (1, 1, 'Иванов Алексей Сергеевич', '+79001112233', 35.0, '2022-03-01', NULL, 'active'),
    (2, 2, 'Петрова Мария Ивановна', '+79002223344', 40.0, '2023-01-15', NULL, 'active'),
    (3, 3, 'Сидоров Дмитрий Олегович', '+79003334455', 30.0, '2021-05-10', '2024-12-20', 'dismissed');

INSERT INTO patients (id, full_name, phone, birth_date) VALUES
    (1, 'Смирнов Павел Андреевич', '+79111111111', '1990-07-14'),
    (2, 'Козлова Анна Викторовна', '+79112222222', '1985-11-03');

INSERT INTO services (id, category_id, title, price, duration_minutes) VALUES
    (1, 1, 'Лечение кариеса', 4500.0, 60),
    (2, 2, 'Удаление зуба', 3500.0, 30),
    (3, 3, 'Установка импланта', 35000.0, 90);

INSERT INTO appointments (id, doctor_id, patient_id, service_id, start_time, end_time, status) VALUES
    (1, 1, 1, 1, '2025-02-10 10:00', '2025-02-10 11:00', 'completed'),
    (2, 2, 2, 2, '2025-02-11 12:00', '2025-02-11 12:30', 'scheduled'),
    (3, 1, 2, 1, '2025-02-11 14:00', '2025-02-11 15:00', 'cancelled');

INSERT INTO completed_procedures (appointment_id, doctor_id, patient_id, service_id, performed_at, actual_price, doctor_percent) VALUES
    (1, 1, 1, 1, '2025-02-10 10:55', 4500.0, 35.0),
    (NULL, 2, 1, 2, '2025-02-10 15:20', 3500.0, 40.0),
    (NULL, 3, 2, 1, '2024-11-15 11:00', 4000.0, 30.0);

COMMIT;