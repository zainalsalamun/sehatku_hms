import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateDoctorDto, UpdateDoctorDto } from './dto/doctor.dto';

@Injectable()
export class DoctorsService {
  constructor(private prisma: PrismaService) {}

  private mapDoctorWithPhoto(doc: any) {
    if (!doc) return doc;
    const avatar = doc.avatarUrl || doc.photoUrl || '';
    return {
      ...doc,
      avatarUrl: avatar,
      photoUrl: avatar,
    };
  }

  async findAll(query?: string, departmentId?: string) {
    const doctors = await this.prisma.doctor.findMany({
      where: {
        ...(departmentId && departmentId !== 'all' ? { departmentId } : {}),
        ...(query
          ? {
              OR: [
                { name: { contains: query, mode: 'insensitive' } },
                { specialist: { contains: query, mode: 'insensitive' } },
                { licenseNumber: { contains: query, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      include: {
        department: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return doctors.map((d) => this.mapDoctorWithPhoto(d));
  }

  async findOne(id: string) {
    const doctor = await this.prisma.doctor.findUnique({
      where: { id },
      include: { department: true, schedules: true },
    });
    if (!doctor) throw new NotFoundException('Dokter tidak ditemukan');
    return this.mapDoctorWithPhoto(doctor);
  }

  async create(dto: CreateDoctorDto, hospitalId = '00000001-0000-4000-8000-000000000001') {
    let targetHospitalId = hospitalId;
    if (targetHospitalId === 'hosp-001' || !targetHospitalId) {
      const hosp = await this.prisma.hospital.findFirst();
      targetHospitalId = hosp?.id || '00000001-0000-4000-8000-000000000001';
    }

    // Resolve targetDepartmentId to ensure valid FK relation
    let targetDeptId = dto.departmentId;
    let dept = targetDeptId
      ? await this.prisma.department.findUnique({ where: { id: targetDeptId } })
      : null;

    if (!dept) {
      dept = await this.prisma.department.findFirst({
        where: {
          OR: [
            ...(targetDeptId ? [{ code: targetDeptId }] : []),
            ...(dto.specialist ? [{ name: { contains: dto.specialist, mode: 'insensitive' as const } }] : []),
          ],
        },
      });
      if (!dept) {
        dept = await this.prisma.department.findFirst();
      }
      targetDeptId = dept?.id || '20000000-0000-4000-8000-000000000001';
    }

    let licenseNumber = dto.licenseNumber;
    if (!licenseNumber || licenseNumber.trim() === '') {
      licenseNumber = `SIP.449.1/${Date.now().toString().slice(-4)}/${new Date().getFullYear()}`;
    }

    const created = await this.prisma.doctor.create({
      data: {
        id: dto.id || undefined,
        hospitalId: targetHospitalId,
        departmentId: targetDeptId,
        name: dto.name,
        licenseNumber,
        specialist: dto.specialist || dept?.name || 'Dokter Umum',
        experienceYears: dto.experienceYears || 5,
        phone: dto.phone || null,
        email: dto.email || null,
        scheduleDays: dto.scheduleDays || ['Senin', 'Rabu', 'Jumat'],
        avatarUrl: dto.avatarUrl || null,
        status: 'active',
      },
      include: { department: true },
    });
    return this.mapDoctorWithPhoto(created);
  }

  async update(id: string, dto: UpdateDoctorDto) {
    await this.findOne(id);
    const updated = await this.prisma.doctor.update({
      where: { id },
      data: dto,
      include: { department: true },
    });
    return this.mapDoctorWithPhoto(updated);
  }

  async toggleActive(id: string) {
    const doctor = await this.findOne(id);
    const newStatus = doctor.status === 'active' ? 'inactive' : 'active';
    const updated = await this.prisma.doctor.update({
      where: { id },
      data: { status: newStatus },
      include: { department: true },
    });
    return this.mapDoctorWithPhoto(updated);
  }

  async uploadAvatar(base64Data: string, originalFileName = 'doctor_avatar.jpg') {
    const publicDoctorsDir = require('path').join(process.cwd(), 'public', 'doctors');
    const fs = require('fs');
    if (!fs.existsSync(publicDoctorsDir)) {
      fs.mkdirSync(publicDoctorsDir, { recursive: true });
    }

    const matches = base64Data.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    const dataBuffer = matches && matches.length === 3
      ? Buffer.from(matches[2], 'base64')
      : Buffer.from(base64Data, 'base64');

    const cleanName = originalFileName.replace(/[^a-zA-Z0-9._-]/g, '_');
    const filename = `upload_${Date.now()}_${cleanName}`;
    const filePath = require('path').join(publicDoctorsDir, filename);

    fs.writeFileSync(filePath, dataBuffer);

    return {
      url: `/public/doctors/${filename}`,
      filename,
      size: dataBuffer.length,
      success: true,
    };
  }
}
