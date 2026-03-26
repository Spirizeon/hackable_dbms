-- =============================================================
--  metro_pd.sql
--  Spy Game — "Metro Police Department" fictional database
--  MariaDB 10.6+
-- =============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. DATABASE
-- ─────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS metro_pd
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE metro_pd;

-- ─────────────────────────────────────────────────────────────
-- 2. TABLES
-- ─────────────────────────────────────────────────────────────

CREATE TABLE officers (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    badge_number  VARCHAR(12)  NOT NULL UNIQUE,
    full_name     VARCHAR(100) NOT NULL,
    rank          VARCHAR(50)  NOT NULL,
    department    VARCHAR(80)  NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active     TINYINT(1)   DEFAULT 1,
    created_at    DATETIME     DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE suspects (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    full_name          VARCHAR(100) NOT NULL,
    dob                DATE,
    nationality        VARCHAR(60),
    known_aliases      VARCHAR(255),
    last_known_address TEXT,
    threat_level       ENUM('low','medium','high','critical') DEFAULT 'low',
    notes              TEXT,
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cases (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    case_number     VARCHAR(20)  NOT NULL UNIQUE,
    title           VARCHAR(200) NOT NULL,
    status          ENUM('open','closed','classified','cold') DEFAULT 'open',
    lead_officer_id INT,
    suspect_id      INT,
    opened_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
    closed_at       DATETIME,
    FOREIGN KEY (lead_officer_id) REFERENCES officers(id),
    FOREIGN KEY (suspect_id)      REFERENCES suspects(id)
);

CREATE TABLE evidence (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    case_id        INT          NOT NULL,
    description    VARCHAR(255) NOT NULL,
    file_path      VARCHAR(500),
    classification ENUM('public','restricted','top_secret') DEFAULT 'restricted',
    collected_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (case_id) REFERENCES cases(id)
);

CREATE TABLE surveillance_reports (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    case_id     INT NOT NULL,
    officer_id  INT NOT NULL,
    notes       TEXT,
    location    VARCHAR(255),
    reported_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (case_id)    REFERENCES cases(id),
    FOREIGN KEY (officer_id) REFERENCES officers(id)
);

-- The spy's jackpot: plaintext creds "accidentally" left in the DB
CREATE TABLE internal_credentials (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    system_name VARCHAR(100),
    username    VARCHAR(100),
    password    VARCHAR(255),
    notes       TEXT,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────
-- 3. USERS  (created after tables so table-level GRANTs work)
-- ─────────────────────────────────────────────────────────────

-- Read-only webapp user (what the vulnerable website runs as)
CREATE USER IF NOT EXISTS 'pd_webapp'@'localhost'  IDENTIFIED BY 'W3bApp#2024!';
GRANT SELECT ON metro_pd.* TO 'pd_webapp'@'localhost';

-- Internal analyst — limited write access
CREATE USER IF NOT EXISTS 'pd_analyst'@'localhost' IDENTIFIED BY 'An@lyst$ecure99';
GRANT SELECT, INSERT, UPDATE ON metro_pd.officers  TO 'pd_analyst'@'localhost';
GRANT SELECT, INSERT, UPDATE ON metro_pd.cases     TO 'pd_analyst'@'localhost';
GRANT SELECT                  ON metro_pd.suspects TO 'pd_analyst'@'localhost';

-- Admin — full control (the jackpot account)
CREATE USER IF NOT EXISTS 'pd_admin'@'localhost'   IDENTIFIED BY 'Adm1n!C0nf1d3nt14l';
GRANT ALL PRIVILEGES ON metro_pd.* TO 'pd_admin'@'localhost';

FLUSH PRIVILEGES;

-- ─────────────────────────────────────────────────────────────
-- 4. SEED DATA
-- ─────────────────────────────────────────────────────────────

-- Officers (password_hash values are bcrypt — crackable for gameplay)
INSERT INTO officers (badge_number, full_name, rank, department, email, password_hash) VALUES
('MPD-0042', 'James Harlow',    'Detective',      'Homicide',         'j.harlow@metropd.gov',    '$2b$12$KIX8zLq3J2Nv5mP0cT1uReG6dFwYhQxAoVs4nZjBlCpDt7RkWeMu'),
('MPD-0117', 'Sandra Voss',     'Sergeant',       'Organized Crime',  's.voss@metropd.gov',      '$2b$12$Lm3NpQ7rS9Kt4wX1yU2vHbA5cEiOj6dFlGsZnRkCpDt8WeMuXoVq'),
('MPD-0208', 'Marcus Oyelaran', 'Lieutenant',     'Internal Affairs', 'm.oyelaran@metropd.gov',  '$2b$12$Pq4RsT8uV0Lw5yN2zA3bIc6dEjFkGlHmOnXpQrStUvWxYzAaBbCcD'),
('MPD-0333', 'Elena Petrov',    'Chief Inspector','Cyber Crimes',     'e.petrov@metropd.gov',    '$2b$12$Qq5StU9vW1Mx6zO3aB4cJd7eEkFlGmHnIoYpRrSsUtVwXyZaAbBcCd'),
('MPD-0501', 'Tom Callahan',    'Officer',        'Patrol',           't.callahan@metropd.gov',  '$2b$12$Rr6TuV0wX2Ny7aP4bC5dKe8fFlGmHnIoJpZqSsTtUuVvWwXxYyZzAa');

-- Suspects
INSERT INTO suspects (full_name, dob, nationality, known_aliases, last_known_address, threat_level, notes) VALUES
('Viktor Kasarov',  '1971-03-14', 'Russian',  'The Architect, V.K.',  '14 Dockside Ave, Apt 3B',       'critical', 'Believed to lead the Kasarov syndicate. Multiple warrants outstanding.'),
('Lena Marchetti',  '1986-07-22', 'Italian',  'Black Lena',           'Unknown — last seen Eastport',   'high',     'Key money launderer. Uses shell companies in Malta.'),
('Deon Pryce',      '1993-11-05', 'British',  'D, The Fixer',         '88 Greystone Rd',                'medium',   'Courier and logistics. Suspected of three armed robberies.'),
('Amara Nwosu',     '1979-09-30', 'Nigerian', 'The Accountant',       'Southside Business Tower #14F',  'high',     'Forged financial documents. Interpol notice issued.'),
('Ghost (Unknown)', NULL,         'Unknown',  'Ghost, Specter, Zero', NULL,                             'critical', 'Identity unverified. Believed to be a state-sponsored operative.');

-- Cases
INSERT INTO cases (case_number, title, status, lead_officer_id, suspect_id, opened_at) VALUES
('MPD-2023-0441', 'Operation Ironveil',         'classified', 4, 5, '2023-06-01 09:00:00'),
('MPD-2023-0198', 'Kasarov Syndicate Takedown', 'open',       2, 1, '2023-01-15 08:30:00'),
('MPD-2024-0077', 'Eastport Money Trail',       'open',       1, 2, '2024-02-20 11:00:00'),
('MPD-2022-0512', 'Greystone Robberies',        'closed',     5, 3, '2022-11-10 14:00:00'),
('MPD-2024-0210', 'Blackbook Financial Fraud',  'open',       3, 4, '2024-05-05 10:15:00');

-- Evidence
INSERT INTO evidence (case_id, description, file_path, classification, collected_at) VALUES
(1, 'Encrypted USB drive — contents unknown',       '/srv/pd-files/classified/op_ironveil/usb_contents.enc',  'top_secret', '2023-06-15 00:00:00'),
(1, 'Satellite imagery — Warehouse District',       '/srv/pd-files/classified/op_ironveil/sat_img_06.jpg',    'top_secret', '2023-07-01 00:00:00'),
(2, 'Wiretap transcript 2023-03-22',                '/srv/pd-files/restricted/kasarov/wire_2023-03-22.txt',   'restricted', '2023-03-25 00:00:00'),
(2, 'Photograph — Kasarov meeting at harbour',      '/srv/pd-files/restricted/kasarov/photo_harbour.jpg',     'restricted', '2023-04-10 00:00:00'),
(3, 'Bank transfer records — offshore accounts',    '/srv/pd-files/restricted/eastport/bank_records.pdf',     'restricted', '2024-03-01 00:00:00'),
(5, 'Ledger — encrypted spreadsheet',               '/srv/pd-files/restricted/blackbook/ledger_enc.xlsx',     'top_secret', '2024-05-20 00:00:00'),
(4, 'Ballistic report — Greystone robbery #3',      '/srv/pd-files/public/greystone/ballistic_r3.pdf',        'public',     '2022-12-01 00:00:00');

-- Surveillance reports
INSERT INTO surveillance_reports (case_id, officer_id, notes, location, reported_at) VALUES
(2, 2, 'Subject observed meeting two unknown males at the Harbour Club. Duration ~40 min. No exchange visible.',  'Harbour Club, Pier 7',          '2023-03-22 22:15:00'),
(2, 1, 'Tail lost near Dockside Ave. Subject uses counter-surveillance — vehicle switch confirmed.',              'Dockside Ave / 5th',            '2023-04-18 19:45:00'),
(1, 4, 'Signal intercept at grid ref 44.2N/18.9E. Encryption AES-256. Forwarded to SIGINT unit.',                'Classified — see report #IR-77', '2023-08-05 03:00:00'),
(3, 1, 'Marchetti entered Southside Business Tower. Left with briefcase after 20 min. Tailed to airport.',       'Southside Business Tower',      '2024-03-15 16:30:00'),
(5, 3, 'Anonymous tip re: shell company "Novaris Holdings." Account links to suspect Nwosu.',                    'Internal Affairs, Room 4B',     '2024-06-01 09:00:00');

-- Internal credentials (discoverable via UNION-based injection)
INSERT INTO internal_credentials (system_name, username, password, notes) VALUES
('CCTV Management Portal', 'admin',         'M3troPD_cctv!',    'Main CCTV dashboard — all city cameras'),
('Evidence Server (SFTP)',  'evd_transfer',  'Ev!d3nce$FTP2024', 'SFTP server at 10.0.1.44'),
('Payroll System',          'payroll_admin', 'P@yR0ll#Secure',   'HR and payroll — Kronos system'),
('Informant Registry',      'inf_reader',    'Inf0rm@nt$Only',   'READ-ONLY access to CI database'),
('Secure Radio Network',    'radio_sys',     'R@d10Syst3m!Net',  'Dispatch and encrypted comms');

-- =============================================================
-- END OF FILE
-- =============================================================
