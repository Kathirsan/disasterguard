-- Sample Seed Data for DisasterGuard

-- 1. Seed Users (1 Citizen, 1 Officer, 1 Crew)
INSERT INTO users (id, name, email, password_hash, role, phone) VALUES
(1, 'John Citizen', 'citizen@disasterguard.org', '$2b$10$w8LqA.SeedHashedPassword1', 'citizen', '+94770000001'),
(2, 'Sarah Officer', 'officer@disasterguard.org', '$2b$10$w8LqA.SeedHashedPassword2', 'officer', '+94770000002'),
(3, 'Alex Crew', 'crew@disasterguard.org', '$2b$10$w8LqA.SeedHashedPassword3', 'crew', '+94770000003');

-- 2. Seed Hazard (User 1 reports a fallen tree)
INSERT INTO hazards (id, user_id, title, description, category, status, latitude, longitude, image_url) VALUES
(1, 1, 'Fallen Tree on Main Road', 'Tree blocking both lanes near town junction', 'road_blockage', 'verified', 6.927079, 79.861244, 'https://example.com/tree.jpg');

-- 3. Seed Hazard Check (AI verification for Hazard 1)
INSERT INTO hazard_checks (hazard_id, check_type, verdict, confidence_score, notes) VALUES
(1, 'ai_vision', 'pass', 0.945, 'Clear road obstruction identified with heavy debris.');

-- 4. Seed Weather Readings
INSERT INTO weather_readings (region, latitude, longitude, temperature, humidity, rainfall_mm, wind_speed_kmh, condition_text) VALUES
('Western Province', 6.9271, 79.8612, 28.5, 85.0, 45.00, 32.00, 'Heavy Monsoon Rain');

-- 5. Seed Alert linked to Hazard 1
INSERT INTO alerts (hazard_id, title, message, severity, area, expires_at) VALUES
(1, 'Road Blockage Notice', 'Town junction impassable due to fallen tree. Take alternative routes.', 'high', 'Town Junction', DATE_ADD(NOW(), INTERVAL 6 HOUR));

-- 6. Seed Ticket (Officer 2 handles Hazard 1)
INSERT INTO tickets (id, hazard_id, officer_id, priority, status, instructions) VALUES
(1, 1, 2, 'high', 'assigned', 'Clear the fallen tree urgently and clear road access.');

-- 7. Seed Crew Assignment (Crew 3 assigned to Ticket 1)
INSERT INTO crew_assignments (ticket_id, crew_user_id, status) VALUES
(1, 3, 'assigned');