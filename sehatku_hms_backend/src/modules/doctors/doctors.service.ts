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

  async create(dto: CreateDoctorDto, hospitalId = 'hosp-001') {
    const created = await this.prisma.doctor.create({
      data: {
        ...dto,
        hospitalId,
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
