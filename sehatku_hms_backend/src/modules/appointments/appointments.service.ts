import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CancelAppointmentDto, CreateAppointmentDto } from './dto/appointment.dto';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class AppointmentsService {
  constructor(private prisma: PrismaService) {}

  private parseDateString(str: string): Date | null {
    if (!str) return null;
    const clean = str.trim();
    const iso = new Date(clean);
    if (!isNaN(iso.getTime()) && clean.includes('-')) return iso;

    const lower = clean.toLowerCase();
    if (lower.includes('hari ini')) return new Date();
    if (lower.includes('besok')) return new Date(Date.now() + 86400000);
    if (lower.includes('lusa')) return new Date(Date.now() + 2 * 86400000);

    const months: Record<string, number> = {
      jan: 0, januari: 0,
      feb: 1, februari: 1,
      mar: 2, maret: 2,
      apr: 3, april: 3,
      mei: 4,
      jun: 5, juni: 5,
      jul: 6, juli: 6,
      agu: 7, ags: 7, agustus: 7,
      sep: 8, september: 8,
      okt: 9, oct: 9, oktober: 9,
      nov: 10, november: 10,
      des: 11, dec: 11, desember: 11,
    };

    const match = clean.match(/(\d{1,2})\s+([A-Za-z]+)(?:\s+(\d{4}))?/);
    if (match) {
      const day = parseInt(match[1], 10);
      const mName = match[2].toLowerCase();
      const year = match[3] ? parseInt(match[3], 10) : new Date().getFullYear();
      if (months[mName] !== undefined) {
        return new Date(year, months[mName], day);
      }
    }

    const slashMatch = clean.match(/(\d{1,2})[/-](\d{1,2})[/-](\d{4})/);
    if (slashMatch) {
      const d = parseInt(slashMatch[1], 10);
      const m = parseInt(slashMatch[2], 10) - 1;
      const y = parseInt(slashMatch[3], 10);
      return new Date(y, m, d);
    }

    return null;
  }

  private async autoExpirePastAppointments() {
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      await this.prisma.appointment.updateMany({
        where: {
          appointmentDate: { lt: today },
          status: { in: ['Menunggu', 'Terkonfirmasi', 'Checked-in'] },
        },
        data: {
          status: 'Tidak Berlaku',
          cancellationReason: 'Melewati tanggal reservasi (Hari H telah lewat)',
        },
      });
    } catch (e) {
      // Graceful fallback
    }
  }

  async findAll(query?: string, status?: string, patientId?: string) {
    await this.autoExpirePastAppointments();
    return this.prisma.appointment.findMany({
      where: {
        ...(status && status !== 'all' ? { status } : {}),
        ...(patientId
          ? {
              OR: [
                { patientId },
                { patient: { name: { contains: patientId, mode: 'insensitive' } } },
                { patient: { medicalRecordNumber: { contains: patientId, mode: 'insensitive' } } },
              ],
            }
          : {}),
        ...(query
          ? {
              OR: [
                { queueNumber: { contains: query, mode: 'insensitive' } },
                { patient: { name: { contains: query, mode: 'insensitive' } } },
                { doctor: { name: { contains: query, mode: 'insensitive' } } },
                { departmentName: { contains: query, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      include: {
        doctor: true,
        patient: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    await this.autoExpirePastAppointments();
    const appt = await this.prisma.appointment.findFirst({
      where: {
        OR: [{ id }, { queueNumber: id }],
      },
      include: { doctor: true, patient: true, queueTicket: true },
    });
    if (!appt) throw new NotFoundException('Appointment tidak ditemukan');
    return appt;
  }

  async create(dto: CreateAppointmentDto, hospitalId = '00000001-0000-4000-8000-000000000001') {
    let targetHospitalId = hospitalId;
    if (targetHospitalId === 'hosp-001' || !targetHospitalId) {
      const hosp = await this.prisma.hospital.findFirst();
      targetHospitalId = hosp?.id || '00000001-0000-4000-8000-000000000001';
    }

    // Determine target appointmentDate
    let appointmentDate = new Date();
    if (dto.appointmentDate) {
      const parsed = new Date(dto.appointmentDate);
      if (!isNaN(parsed.getTime())) appointmentDate = parsed;
    } else if (dto.dateLabel) {
      const parsed = this.parseDateString(dto.dateLabel);
      if (parsed) appointmentDate = parsed;
    }

    // Generate sequential queue number
    const count = await this.prisma.appointment.count();
    const queueNumber = `A-${(count + 1).toString().padStart(3, '0')}`;

    const created = await this.prisma.appointment.create({
      data: {
        id: dto.id || undefined,
        hospitalId: targetHospitalId,
        doctorId: dto.doctorId,
        patientId: dto.patientId,
        dateLabel: dto.dateLabel,
        appointmentDate,
        appointmentTime: dto.appointmentTime,
        departmentName: dto.departmentName,
        reason: dto.reason || 'Konsultasi Poli',
        queueNumber,
        status: 'Menunggu',
      },
      include: { doctor: true, patient: true },
    });

    // Auto-trigger notifications
    try {
      await this.prisma.notification.createMany({
        data: [
          {
            role: 'patient',
            title: 'Reservasi Dokter Berhasil',
            message: `Reservasi Anda di Poli ${created.departmentName} dengan ${created.doctor?.name || 'Dokter Spesialis'} (${created.dateLabel}, ${created.appointmentTime}) telah terdaftar dengan Nomor Antrean ${created.queueNumber}.`,
            type: 'appointment',
            targetId: created.id,
            isRead: false,
          },
          {
            role: 'doctor',
            title: 'Pasien Reservasi Baru Masuk',
            message: `Pasien ${created.patient?.name || 'Pasien'} telah memesan sesi konsultasi di Poli ${created.departmentName} (${created.dateLabel}, ${created.appointmentTime}).`,
            type: 'appointment',
            targetId: created.id,
            isRead: false,
          },
          {
            role: 'admin',
            title: 'Reservasi Baru Terdaftar',
            message: `Tiket antrean ${created.queueNumber} terbit untuk ${created.patient?.name || 'Pasien'} (${created.doctor?.name || 'Dokter'}).`,
            type: 'appointment',
            targetId: created.id,
            isRead: false,
          },
        ],
      });
    } catch (e) {
      // Non-blocking notification failure
    }

    return created;
  }

  async checkIn(id: string) {
    const appt = await this.prisma.appointment.findFirst({
      where: {
        OR: [{ id }, { queueNumber: id }],
      },
    });

    if (!appt) {
      throw new NotFoundException('Reservasi tidak ditemukan.');
    }

    if (appt.status === 'Selesai') {
      throw new BadRequestException('Pemeriksaan telah selesai. Tidak dapat melakukan check-in.');
    }
    if (appt.status === 'Dibatalkan') {
      throw new BadRequestException('Reservasi telah dibatalkan. Tidak dapat melakukan check-in.');
    }
    if (appt.status === 'Checked-in') {
      throw new BadRequestException('Pasien sudah melakukan check-in sebelumnya.');
    }
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (
      appt.status === 'Kadaluarsa' ||
      appt.status === 'Tidak Berlaku' ||
      appt.dateLabel?.toLowerCase().includes('kemarin') ||
      (appt.appointmentDate && new Date(appt.appointmentDate) < today)
    ) {
      if (appt.status !== 'Tidak Berlaku') {
        try {
          await this.prisma.appointment.update({
            where: { id: appt.id },
            data: {
              status: 'Tidak Berlaku',
              cancellationReason: 'Melewati tanggal reservasi (Hari H telah lewat)',
            },
          });
        } catch (_) {}
      }
      throw new BadRequestException('Jadwal reservasi sudah tidak berlaku lagi karena telah melewati tanggal janji temu (hari H telah lewat).');
    }

    // Update queue ticket status as well
    try {
      await this.prisma.queueTicket.updateMany({
        where: { appointmentId: appt.id },
        data: { status: 'called' },
      });
    } catch (e) {}

    return this.prisma.appointment.update({
      where: { id: appt.id },
      data: { status: 'Checked-in' },
      include: { doctor: true, patient: true },
    });
  }

  async complete(id: string) {
    const appt = await this.prisma.appointment.findFirst({
      where: {
        OR: [{ id }, { queueNumber: id }],
      },
    });

    if (!appt) {
      return { id, status: 'Selesai' };
    }

    return this.prisma.appointment.update({
      where: { id: appt.id },
      data: { status: 'Selesai' },
      include: { doctor: true, patient: true },
    });
  }

  async cancel(id: string, dto: CancelAppointmentDto) {
    const appt = await this.prisma.appointment.findFirst({
      where: {
        OR: [{ id }, { queueNumber: id }],
      },
      include: { doctor: true, patient: true },
    });

    if (!appt) {
      return { id, status: 'Dibatalkan', cancellationReason: dto.cancellationReason };
    }

    const updated = await this.prisma.appointment.update({
      where: { id: appt.id },
      data: {
        status: 'Dibatalkan',
        cancellationReason: dto.cancellationReason,
      },
      include: { doctor: true, patient: true },
    });

    // Auto-trigger notifications
    try {
      await this.prisma.notification.createMany({
        data: [
          {
            role: 'patient',
            title: 'Reservasi Telah Dibatalkan',
            message: `Reservasi konsultasi ${appt.queueNumber} dengan ${appt.doctor?.name || 'Dokter'} telah dibatalkan. Alasan: ${dto.cancellationReason || 'Permintaan pembatalan'}.`,
            type: 'appointment',
            targetId: appt.id,
            isRead: false,
          },
          {
            role: 'doctor',
            title: 'Pasien Membatalkan Reservasi',
            message: `Antrean ${appt.queueNumber} atas nama ${appt.patient?.name || 'Pasien'} telah dibatalkan.`,
            type: 'appointment',
            targetId: appt.id,
            isRead: false,
          },
        ],
      });
    } catch (e) {}

    return updated;
  }

  // ===================== APPOINTMENT CONFIG & SLOTS =====================

  private readonly configFilePath = path.join(process.cwd(), 'data', 'appointment_config.json');

  private defaultTimeSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '18:30', '19:00', '19:30', '20:00',
  ];

  private defaultQuickReasons = [
    'Konsultasi Rutin',
    'Demam & Flu',
    'Nyeri Dada & Sesak',
    'Pemeriksaan Gigi',
    'Kontrol Pasca Obat',
    'Pusing / Sakit Kepala',
    'Medical Checkup',
  ];

  private loadConfigFromFile(): { timeSlots: string[]; quickReasons: string[] } {
    try {
      if (fs.existsSync(this.configFilePath)) {
        const raw = fs.readFileSync(this.configFilePath, 'utf-8');
        const parsed = JSON.parse(raw);
        if (parsed.timeSlots && parsed.quickReasons) {
          return parsed;
        }
      }
    } catch (e) {
      console.error('[AppointmentsService] Error reading config file:', e);
    }
    return {
      timeSlots: this.defaultTimeSlots,
      quickReasons: this.defaultQuickReasons,
    };
  }

  private saveConfigToFile(config: { timeSlots: string[]; quickReasons: string[] }) {
    try {
      const dir = path.dirname(this.configFilePath);
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(this.configFilePath, JSON.stringify(config, null, 2), 'utf-8');
    } catch (e) {
      console.error('[AppointmentsService] Error saving config file:', e);
    }
  }

  async getAppointmentConfig() {
    try {
      const dbConfig = await this.prisma.appointmentConfig.findFirst();
      if (dbConfig) {
        const result = {
          timeSlots: dbConfig.timeSlots,
          quickReasons: dbConfig.quickReasons,
        };
        this.saveConfigToFile(result);
        return result;
      }
      // If table exists but empty, create seed row
      const hosp = await this.prisma.hospital.findFirst();
      const created = await this.prisma.appointmentConfig.create({
        data: {
          hospitalId: hosp?.id || null,
          timeSlots: this.defaultTimeSlots,
          quickReasons: this.defaultQuickReasons,
        },
      });
      return {
        timeSlots: created.timeSlots,
        quickReasons: created.quickReasons,
      };
    } catch (e) {
      // Graceful fallback to persistent JSON file
      return this.loadConfigFromFile();
    }
  }

  async updateAppointmentConfig(dto: { timeSlots?: string[]; quickReasons?: string[] }) {
    const current = await this.getAppointmentConfig();
    const updated = {
      timeSlots: dto.timeSlots && dto.timeSlots.length > 0 ? dto.timeSlots : current.timeSlots,
      quickReasons: dto.quickReasons && dto.quickReasons.length > 0 ? dto.quickReasons : current.quickReasons,
    };

    try {
      const dbConfig = await this.prisma.appointmentConfig.findFirst();
      if (dbConfig) {
        await this.prisma.appointmentConfig.update({
          where: { id: dbConfig.id },
          data: {
            timeSlots: updated.timeSlots,
            quickReasons: updated.quickReasons,
          },
        });
      } else {
        const hosp = await this.prisma.hospital.findFirst();
        await this.prisma.appointmentConfig.create({
          data: {
            hospitalId: hosp?.id || null,
            timeSlots: updated.timeSlots,
            quickReasons: updated.quickReasons,
          },
        });
      }
    } catch (e) {
      console.warn('[AppointmentsService] DB update skipped, falling back to disk:', e);
    }

    this.saveConfigToFile(updated);
    return updated;
  }
}
