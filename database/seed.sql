-- ==============================================================================
-- SehatKu HMS Complete Initial Seed Data (Standard UUID v4)
-- ==============================================================================

-- 1. Default Hospital
INSERT INTO hospitals (id, code, name, timezone, address, phone, email, status)
VALUES (
    '00000001-0000-4000-8000-000000000001',
    'SEHATKU-JKT',
    'SehatKu Medical Center Jakarta',
    'Asia/Jakarta',
    'Jl. Jenderal Sudirman Kav. 52-53, Jakarta Selatan',
    '+62-21-555-8900',
    'info@sehatku-hospital.id',
    'active'
) ON CONFLICT (code) DO NOTHING;

-- 2. Default Roles
INSERT INTO roles (id, code, name, description)
VALUES 
    ('00000002-0000-4000-8000-000000000001', 'super_admin', 'Super Administrator', 'Akses penuh seluruh konfigurasi sistem lintas hospital'),
    ('00000002-0000-4000-8000-000000000002', 'hospital_admin', 'Hospital Administrator', 'Manajemen operasional dan master data rumah sakit'),
    ('00000002-0000-4000-8000-000000000003', 'doctor', 'Dokter Spesialis / Umum', 'Akses rekam medis, antrean poli, dan peresepan'),
    ('00000002-0000-4000-8000-000000000004', 'receptionist', 'Resepsionis & Admisi', 'Pendaftaran pasien, verifikasi appointment, dan check-in antrean'),
    ('00000002-0000-4000-8000-000000000005', 'cashier', 'Kasir & Billing', 'Penerbitan invoice dan verifikasi pembayaran'),
    ('00000002-0000-4000-8000-000000000006', 'patient', 'Pasien', 'Akses portal pasien, riwayat medis, dan booking slot')
ON CONFLICT (code) DO NOTHING;

-- 3. Default Users (Password: 'password123' bcrypt hash)
INSERT INTO users (id, email, phone, password_hash, full_name, status)
VALUES 
    ('10000000-0000-4000-8000-000000000001', 'admin@sehatku.id', '0811-0000-0001', '$2a$10$wN9rI.hD2v61f5L8C9M6E.8l5vR/U3Jt0pQ7Z.Qy3R8i5sW7X8mXW', 'Budi Santoso (Admin)', 'active'),
    ('10000000-0000-4000-8000-000000000002', 'doctor@sehatku.id', '0812-3456-7890', '$2a$10$wN9rI.hD2v61f5L8C9M6E.8l5vR/U3Jt0pQ7Z.Qy3R8i5sW7X8mXW', 'dr. Maya Pratama, Sp.JP', 'active'),
    ('10000000-0000-4000-8000-000000000003', 'rafi@sehatku.id', '0813-9876-5432', '$2a$10$wN9rI.hD2v61f5L8C9M6E.8l5vR/U3Jt0pQ7Z.Qy3R8i5sW7X8mXW', 'drg. Rafi Akbar, Sp.KG', 'active'),
    ('10000000-0000-4000-8000-000000000004', 'patient@sehatku.id', '0812-9988-7766', '$2a$10$wN9rI.hD2v61f5L8C9M6E.8l5vR/U3Jt0pQ7Z.Qy3R8i5sW7X8mXW', 'Nadia Putri', 'active')
ON CONFLICT (email) DO NOTHING;

-- 4. User Role Mapping
INSERT INTO user_roles (id, user_id, role_id, hospital_id)
VALUES
    ('00000003-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', '00000002-0000-4000-8000-000000000002', '00000001-0000-4000-8000-000000000001'),
    ('00000003-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', '00000002-0000-4000-8000-000000000003', '00000001-0000-4000-8000-000000000001'),
    ('00000003-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000003', '00000002-0000-4000-8000-000000000003', '00000001-0000-4000-8000-000000000001'),
    ('00000003-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000004', '00000002-0000-4000-8000-000000000006', '00000001-0000-4000-8000-000000000001')
ON CONFLICT (user_id, role_id, hospital_id) DO NOTHING;

-- 5. Departments / Poliklinik
INSERT INTO departments (id, hospital_id, code, name, description, status)
VALUES
    ('20000000-0000-4000-8000-000000000001', '00000001-0000-4000-8000-000000000001', 'KARDIO', 'Kardiologi & Vaskular', 'Pelayanan spesialis jantung dan pembuluh darah', 'active'),
    ('20000000-0000-4000-8000-000000000002', '00000001-0000-4000-8000-000000000001', 'DENTAL', 'Kesehatan Gigi & Mulut', 'Pelayanan konservasi gigi dan bedah mulut', 'active'),
    ('20000000-0000-4000-8000-000000000003', '00000001-0000-4000-8000-000000000001', 'PEDIATRI', 'Pediatri & Tumbuh Kembang', 'Pelayanan spesialis kesehatan anak dan imunisasi', 'active'),
    ('20000000-0000-4000-8000-000000000004', '00000001-0000-4000-8000-000000000001', 'NEURO', 'Neurologi & Saraf', 'Pelayanan spesialis saraf dan gangguan motorik', 'active'),
    ('20000000-0000-4000-8000-000000000005', '00000001-0000-4000-8000-000000000001', 'INTERNA', 'Penyakit Dalam', 'Pelayanan penyakit dalam dan metabolik', 'active'),
    ('20000000-0000-4000-8000-000000000006', '00000001-0000-4000-8000-000000000001', 'MATA', 'Mata (Oftalmologi)', 'Pelayanan kesehatan mata dan refraksi', 'active')
ON CONFLICT (hospital_id, code) DO NOTHING;

-- 6. Doctors
INSERT INTO doctors (id, user_id, hospital_id, department_id, license_number, name, specialist, experience_years, rating, available_today, status, phone, email, avatar_url, schedule_days)
VALUES
    ('30000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', '00000001-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'SIP.449.1/023/2021', 'dr. Maya Pratama, Sp.JP', 'Kardiologi & Vaskular', 12, 4.95, true, 'active', '0812-3456-7890', 'maya.pratama@sehatku-hospital.id', '/public/doctors/dr_maya_pratama.jpg', ARRAY['Senin', 'Rabu', 'Jumat']),
    ('30000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000003', '00000001-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002', 'SIP.449.1/045/2020', 'drg. Rafi Akbar, Sp.KG', 'Kesehatan Gigi & Mulut', 8, 4.90, true, 'active', '0813-9876-5432', 'rafi.akbar@sehatku-hospital.id', '/public/doctors/drg_rafi_akbar.jpg', ARRAY['Selasa', 'Kamis', 'Sabtu']),
    ('30000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000004', '00000001-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003', 'SIP.449.1/089/2022', 'dr. Sarah Olivia, Sp.A', 'Pediatri & Tumbuh Kembang', 10, 4.88, false, 'active', '0811-2233-4455', 'sarah.olivia@sehatku-hospital.id', '/public/doctors/dr_sarah_olivia.jpg', ARRAY['Senin', 'Selasa', 'Rabu']),
    ('30000000-0000-4000-8000-000000000004', NULL, '00000001-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000004', 'SIP.449.1/012/2018', 'dr. Bima Santoso, Sp.S', 'Neurologi & Saraf', 15, 4.70, true, 'active', '0815-6677-8899', 'bima.santoso@sehatku-hospital.id', '/public/doctors/dr_bima_santoso.jpg', ARRAY['Rabu', 'Kamis', 'Jumat']),
    ('30000000-0000-4000-8000-000000000005', NULL, '00000001-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000005', 'SIP.449.1/077/2019', 'dr. Hendra Wijaya, Sp.PD', 'Penyakit Dalam', 14, 4.85, true, 'inactive', '0817-1122-3344', 'hendra.wijaya@sehatku-hospital.id', '/public/doctors/dr_hendra_wijaya.jpg', ARRAY['Senin', 'Selasa', 'Rabu', 'Kamis'])
ON CONFLICT (hospital_id, license_number) DO NOTHING;

-- 7. Patients
INSERT INTO patients (id, user_id, hospital_id, medical_record_number, nik, name, birth_date, gender, blood_type, insurance_provider, phone, email, address, emergency_contact, status)
VALUES
    ('40000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000004', '00000001-0000-4000-8000-000000000001', 'MRN-2026-001', '3201123456780001', 'Nadia Putri', '1995-04-12', 'Perempuan', 'O+', 'BPJS Kesehatan Mandiri', '0812-9988-7766', 'nadia.putri@gmail.com', 'Jl. Melati No. 14, Jakarta Selatan', 'Dimas (Suami) - 0812-9988-7700', 'Aktif'),
    ('40000000-0000-4000-8000-000000000002', NULL, '00000001-0000-4000-8000-000000000001', 'MRN-2026-002', '3201123456780002', 'Raka Mahendra', '1988-11-23', 'Laki-laki', 'A+', 'Prudential Health', '0813-1122-3344', 'raka.mahendra@gmail.com', 'Jl. Kebon Jeruk No. 88, Jakarta Barat', 'Rina (Istri) - 0813-1122-3300', 'Aktif'),
    ('40000000-0000-4000-8000-000000000003', NULL, '00000001-0000-4000-8000-000000000001', 'MRN-2026-003', '3201123456780003', 'Siti Rahmawati', '2000-08-15', 'Perempuan', 'B+', 'Umum / Mandiri', '0817-5566-7788', 'siti.rahmawati@gmail.com', 'Jl. Kemang Raya No. 45, Jakarta Selatan', 'Budi (Ayah) - 0817-5566-7700', 'Aktif')
ON CONFLICT (hospital_id, medical_record_number) DO NOTHING;

-- 8. Master Procedures
INSERT INTO procedures (id, hospital_id, code, name, category, description, price, status)
VALUES
    ('25000000-0000-4000-8000-000000000001', '00000001-0000-4000-8000-000000000001', 'PROC-001', 'Konsultasi Dokter & Pemeriksaan Fisik', 'Umum', 'Pemeriksaan tanda vital, konsultasi keluhan, dan diagnosa dokter.', 50000, 'active'),
    ('25000000-0000-4000-8000-000000000002', '00000001-0000-4000-8000-000000000001', 'PROC-002', 'Scaling Gigi (Pembersihan Karang)', 'Gigi', 'Pembersihan plak dan kalkulus supragingival seluruh regio gigi.', 150000, 'active'),
    ('25000000-0000-4000-8000-000000000003', '00000001-0000-4000-8000-000000000001', 'PROC-003', 'Injeksi Obat / Vitamin Booster', 'Tindakan Medis', 'Pemberian injeksi intramuskular/intravena multivitamin atau pereda nyeri.', 45000, 'active'),
    ('25000000-0000-4000-8000-000000000004', '00000001-0000-4000-8000-000000000001', 'PROC-004', 'Nebulizer Inhalasi Saluran Nafas', 'Tindakan Medis', 'Terapi uap bronkodilator untuk pasien asma atau sesak batuk berdahak.', 75000, 'active'),
    ('25000000-0000-4000-8000-000000000005', '00000001-0000-4000-8000-000000000001', 'PROC-005', 'Rawat Luka & Ganti Verban', 'Keperawatan', 'Pembersihan luka terbuka, antiseptik, dan penggantian balutan kasa steril.', 35000, 'active'),
    ('25000000-0000-4000-8000-000000000006', '00000001-0000-4000-8000-000000000001', 'PROC-006', 'Penjahitan Luka (Hecting)', 'Tindakan Medis', 'Anestesi lokal dan penjahitan luka robek sederhana 1-3 jahitan.', 120000, 'active'),
    ('25000000-0000-4000-8000-000000000007', '00000001-0000-4000-8000-000000000001', 'PROC-007', 'Cek Gula Darah Sewaktu (Strip)', 'Laboratorium Rapid', 'Pemeriksaan glukosa darah kapiler instan (1 menit).', 25000, 'active'),
    ('25000000-0000-4000-8000-000000000008', '00000001-0000-4000-8000-000000000001', 'PROC-008', 'Cek Asam Urat (Strip)', 'Laboratorium Rapid', 'Pemeriksaan kadar asam urat kapiler instan.', 25000, 'active'),
    ('25000000-0000-4000-8000-000000000009', '00000001-0000-4000-8000-000000000001', 'PROC-009', 'Cek Kolesterol Total (Strip)', 'Laboratorium Rapid', 'Pemeriksaan skrining lipid kolesterol kapiler cepat.', 35000, 'active'),
    ('25000000-0000-4000-8000-000000000010', '00000001-0000-4000-8000-000000000001', 'PROC-010', 'Pemeriksaan Rekam Jantung (EKG)', 'Tindakan Medis', 'Perekaman aktivitas listrik jantung 12-lead lengkap dengan interpretasi.', 100000, 'active')
ON CONFLICT (code) DO NOTHING;

-- 9. Appointments & Queue Tickets
INSERT INTO appointments (id, hospital_id, doctor_id, patient_id, date_label, appointment_date, appointment_time, queue_number, department_name, reason, status)
VALUES
    ('50000000-0000-4000-8000-000000000001', '00000001-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', 'Hari ini', CURRENT_DATE, '09:30 WIB', 'A-001', 'Kardiologi & Vaskular', 'Kontrol rutin hipertensi dan cek EKG berkala', 'Checked-in'),
    ('50000000-0000-4000-8000-000000000002', '00000001-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000002', 'Hari ini', CURRENT_DATE, '10:00 WIB', 'A-002', 'Kardiologi & Vaskular', 'Nyeri dada saat berolahraga ringan', 'Menunggu'),
    ('50000000-0000-4000-8000-000000000003', '00000001-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000003', 'Hari ini', CURRENT_DATE, '10:30 WIB', 'B-001', 'Kesehatan Gigi & Mulut', 'Pembersihan karang gigi & scaling rutin', 'Menunggu'),
    ('50000000-0000-4000-8000-000000000004', '00000001-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000003', '40000000-0000-4000-8000-000000000001', 'Besok', CURRENT_DATE + INTERVAL '1 day', '11:00 WIB', 'C-005', 'Pediatri & Tumbuh Kembang', 'Imunisasi lanjutan & konsultasi gizi anak', 'Terkonfirmasi'),
    ('50000000-0000-4000-8000-000000000005', '00000001-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000004', '40000000-0000-4000-8000-000000000002', 'Kemarin', CURRENT_DATE - INTERVAL '1 day', '14:00 WIB', 'D-012', 'Neurologi & Saraf', 'Migrain berulang sisi kanan', 'Selesai')
ON CONFLICT (id) DO NOTHING;

INSERT INTO queue_tickets (id, appointment_id, service_date, prefix, sequence, queue_number, status)
VALUES
    ('55000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', CURRENT_DATE, 'A', 1, 'A-001', 'called'),
    ('55000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000002', CURRENT_DATE, 'A', 2, 'A-002', 'waiting'),
    ('55000000-0000-4000-8000-000000000003', '50000000-0000-4000-8000-000000000003', CURRENT_DATE, 'B', 1, 'B-001', 'waiting'),
    ('55000000-0000-4000-8000-000000000004', '50000000-0000-4000-8000-000000000004', CURRENT_DATE + INTERVAL '1 day', 'C', 5, 'C-005', 'waiting'),
    ('55000000-0000-4000-8000-000000000005', '50000000-0000-4000-8000-000000000005', CURRENT_DATE - INTERVAL '1 day', 'D', 12, 'D-012', 'completed')
ON CONFLICT (appointment_id) DO NOTHING;

-- 10. Clinical Encounters, Diagnoses & Prescriptions
INSERT INTO encounters (id, appointment_id, patient_id, doctor_id, anamnesis, physical_exam, diagnosis_summary, status, signed_at)
VALUES
    ('60000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'Pasien datang untuk kontrol tensi berkala. Mengeluhkan pusing ringan di bagian tengkuk leher jika lembur kerja.', 'Keadaan Umum: Baik, Compos Mentis. TD: 135/85 mmHg, Nadi: 78x/menit regular, RR: 18x/menit, Suhu: 36.6 C, SpO2: 99%. Jantung: S1-S2 murni regular, murmur (-), gallop (-).', 'Hipertensi Primer Esensial (ICD-10: I10)', 'signed', CURRENT_TIMESTAMP),
    ('60000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000005', '40000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000004', 'Keluhan sakit kepala berdenyut sebelah kanan sejak 2 hari yang lalu, disertai mual ringan.', 'TD: 120/80 mmHg, Nadi: 80x/menit, Suhu: 36.8 C. Pemeriksaan neurologis kranial dalam batas normal.', 'Migraine without aura (ICD-10: G43.0)', 'signed', CURRENT_TIMESTAMP - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO diagnoses (id, encounter_id, icd10_code, description, type)
VALUES
    ('65000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', 'I10', 'Essential (primary) hypertension', 'primary'),
    ('65000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000002', 'G43.0', 'Migraine without aura', 'primary')
ON CONFLICT (id) DO NOTHING;

INSERT INTO prescriptions (id, encounter_id, patient_id, doctor_id, notes, status)
VALUES
    ('70000000-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'Minum obat teratur di pagi hari, kurangi konsumsi garam berlebih & kelola stres.', 'ready'),
    ('70000000-0000-4000-8000-000000000002', '60000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000004', 'Istirahat di ruangan redup, minum pereda nyeri jika serangan timbul.', 'dispensed')
ON CONFLICT (id) DO NOTHING;

INSERT INTO prescription_items (id, prescription_id, medicine_name, dosage, frequency, route, duration_days, instruction)
VALUES
    ('75000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000001', 'Amlodipine Besylate 5mg', '5 mg', '1x sehari pagi', 'oral', 30, 'Diminum sesudah makan pagi'),
    ('75000000-0000-4000-8000-000000000002', '70000000-0000-4000-8000-000000000001', 'Candesartan 8mg', '8 mg', '1x sehari malam', 'oral', 30, 'Diminum sebelum tidur'),
    ('75000000-0000-4000-8000-000000000003', '70000000-0000-4000-8000-000000000002', 'Paracetamol 500mg', '500 mg', '3x sehari prn', 'oral', 5, 'Bila nyeri kepala kambuh')
ON CONFLICT (id) DO NOTHING;

-- 11. Medical Certificates (SKD)
INSERT INTO medical_certificates (id, certificate_number, type, hospital_id, encounter_id, patient_id, doctor_id, diagnosis, start_date, end_date, duration_days, notes, status)
VALUES
    ('68000000-0000-4000-8000-000000000001', 'SKD/2026/08/001', 'sick_leave', '00000001-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'Hipertensi Primer & Kelelahan Fisik Akut', CURRENT_DATE, CURRENT_DATE + INTERVAL '2 days', 2, 'Pasien memerlukan istirahat tirah baring selama 2 hari untuk stabilisasi tekanan darah.', 'issued')
ON CONFLICT (certificate_number) DO NOTHING;

-- 12. Invoices
INSERT INTO invoices (id, invoice_number, hospital_id, appointment_id, patient_id, patient_name, doctor_name, service_name, amount, status, payment_method, paid_at)
VALUES
    ('80000000-0000-4000-8000-000000000001', 'INV-2026-101', '00000001-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', 'Nadia Putri', 'dr. Maya Pratama, Sp.JP', 'Konsultasi Poli Kardiologi & EKG', 350000.00, 'Lunas', 'QRIS Dinamis', CURRENT_TIMESTAMP),
    ('80000000-0000-4000-8000-000000000002', 'INV-2026-102', '00000001-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000002', 'Raka Mahendra', 'dr. Maya Pratama, Sp.JP', 'Konsultasi Poli Kardiologi', 250000.00, 'Menunggu', 'Tunai', NULL),
    ('80000000-0000-4000-8000-000000000003', 'INV-2026-103', '00000001-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000003', '40000000-0000-4000-8000-000000000003', 'Siti Rahmawati', 'drg. Rafi Akbar, Sp.KG', 'Tindakan Scaling Gigi & Konsultasi', 450000.00, 'Menunggu', 'Debit BCA', NULL),
    ('80000000-0000-4000-8000-000000000004', 'INV-2026-104', '00000001-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000005', '40000000-0000-4000-8000-000000000002', 'Raka Mahendra', 'dr. Bima Santoso, Sp.S', 'Konsultasi Poli Saraf & Resep', 320000.00, 'Lunas', 'Transfer Bank Mandiri', CURRENT_TIMESTAMP - INTERVAL '1 day')
ON CONFLICT (invoice_number) DO NOTHING;

-- 13. Audit Logs
INSERT INTO audit_logs (id, hospital_id, actor_name, actor_role, action, resource_type, resource_id, details)
VALUES
    ('99000000-0000-4000-8000-000000000001', '00000001-0000-4000-8000-000000000001', 'Budi Santoso', 'hospital_admin', 'LOGIN', 'User', '10000000-0000-4000-8000-000000000001', 'Login berhasil ke Dashboard Operations Console'),
    ('99000000-0000-4000-8000-000000000002', '00000001-0000-4000-8000-000000000001', 'dr. Maya Pratama, Sp.JP', 'doctor', 'CREATE', 'Encounter', '60000000-0000-4000-8000-000000000001', 'Pemeriksaan selesai untuk Nadia Putri (MRN-2026-001) - Diagnosa: Hipertensi Primer'),
    ('99000000-0000-4000-8000-000000000003', '00000001-0000-4000-8000-000000000001', 'Siti Rahma', 'receptionist', 'CREATE', 'Patient', '40000000-0000-4000-8000-000000000001', 'Pendaftaran pasien baru MRN-2026-001 (Nadia Putri)'),
    ('99000000-0000-4000-8000-000000000004', '00000001-0000-4000-8000-000000000001', 'Siti Rahma', 'receptionist', 'CHECK_IN', 'Appointment', '50000000-0000-4000-8000-000000000001', 'Pasien Nadia Putri melakukan check-in antrean A-001')
ON CONFLICT (id) DO NOTHING;
