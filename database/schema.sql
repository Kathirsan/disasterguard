-- DisasterGuard Database Schema

-- Drop existing tables if needed (in reverse dependency order)
DROP TABLE IF EXISTS crew_assignments;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS alerts;
DROP TABLE IF EXISTS hazard_checks;
DROP TABLE IF EXISTS weather_readings;
DROP TABLE IF EXISTS hazards;
DROP TABLE IF EXISTS users;

-- 1. Users table (Citizens, Officers, Crew)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('citizen', 'officer', 'crew', 'admin') DEFAULT 'citizen',
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Hazards reported by Citizens
CREATE TABLE hazards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    status ENUM('reported', 'verified', 'in_progress', 'resolved', 'rejected') DEFAULT 'reported',
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. Verification & AI analysis results for hazards
CREATE TABLE hazard_checks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hazard_id INT NOT NULL,
    check_type ENUM('ai_vision', 'duplicate_detection', 'manual_officer') NOT NULL,
    verdict ENUM('pass', 'fail', 'suspicious') NOT NULL,
    confidence_score DECIMAL(4, 3), -- e.g. 0.940
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hazard_id) REFERENCES hazards(id) ON DELETE CASCADE
);

-- 4. Weather readings
CREATE TABLE weather_readings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    region VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    temperature DECIMAL(4, 1),
    humidity DECIMAL(4, 1),
    rainfall_mm DECIMAL(5, 2),
    wind_speed_kmh DECIMAL(5, 2),
    condition_text VARCHAR(100),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Broadcast alerts triggered by hazards or weather
CREATE TABLE alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hazard_id INT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    severity ENUM('low', 'moderate', 'high', 'critical') DEFAULT 'moderate',
    area VARCHAR(100) NOT NULL,
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    FOREIGN KEY (hazard_id) REFERENCES hazards(id) ON DELETE SET NULL
);

-- 6. Officer dispatch tickets created from hazards
CREATE TABLE tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hazard_id INT NOT NULL,
    officer_id INT NOT NULL,
    priority ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    status ENUM('open', 'assigned', 'resolved', 'closed') DEFAULT 'open',
    instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hazard_id) REFERENCES hazards(id) ON DELETE CASCADE,
    FOREIGN KEY (officer_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 7. Field crew assignments for tickets
CREATE TABLE crew_assignments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT NOT NULL,
    crew_user_id INT NOT NULL,
    status ENUM('assigned', 'accepted', 'in_progress', 'completed') DEFAULT 'assigned',
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    resolution_notes TEXT,
    proof_image_url VARCHAR(255),
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (crew_user_id) REFERENCES users(id) ON DELETE CASCADE
);