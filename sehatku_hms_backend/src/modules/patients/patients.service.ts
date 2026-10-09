import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreatePatientDto, UpdatePatientDto } from './dto/patient.dto';

@Injectable()
export class PatientsService {
  constructor(private prisma: PrismaService) {}

  async findAll(query?: string, insurance?: string) {
    return this.prisma.patient.findMany({
      where: {
        ...(insurance && insurance !== 'all'
          ? { insuranceProvider: { contains: insurance, mode: 'insensitive' } }
          : {}),
        ...(query
          ? {
              OR: [
                { name: { contains: query, mode: 'insensitive' } },
                { medicalRecordNumber: { contains: query, mode: 'insensitive' } },
                { nik: { contains: query, mode: 'insensitive' } },
                { phone: { contains: query, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    const patient = await this.prisma.patient.findUnique({
      where: { id },
      include: {
        appointments: { orderBy: { createdAt: 'desc' }, take: 5 },
        encounters: { orderBy: { createdAt: 'desc' }, take: 5 },
      },
    });
    if (!patient) throw new NotFoundException('Pasien tidak ditemukan');
    return patient;
  }

  async create(dto: CreatePatientDto, hospitalId = '00000001-0000-4000-8000-000000000001') {
    let targetHospitalId = hospitalId;
    if (targetHospitalId === 'hosp-001' || !targetHospitalId) {
      const hosp = await this.prisma.hospital.findFirst();
      targetHospitalId = hosp?.id || '00000001-0000-4000-8000-000000000001';
    }

    let mrn = dto.medicalRecordNumber;
    if (!mrn || !mrn.trim()) {
      const year = new Date().getFullYear();
      const count = await this.prisma.patient.count();
      mrn = `MRN-${year}-${(count + 101).toString().padStart(3, '0')}`;
    }

    return this.prisma.patient.create({
      data: {
        ...dto,
        medicalRecordNumber: mrn,
        birthDate: new Date(dto.birthDate),
        hospitalId: targetHospitalId,
      },
    });
  }

  async update(id: string, dto: UpdatePatientDto) {
    await this.findOne(id);
    return this.prisma.patient.update({
      where: { id },
      data: {
        ...dto,
        birthDate: new Date(dto.birthDate),
      },
    });
  }

  async toggleStatus(id: string) {
    const patient = await this.findOne(id);
    const newStatus = patient.status === 'Aktif' ? 'Nonaktif' : 'Aktif';
    return this.prisma.patient.update({
      where: { id },
      data: { status: newStatus },
    });
  }
}
