import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AuditService {
  constructor(private prisma: PrismaService) {}

  async findAll(query?: string, action?: string) {
    return this.prisma.auditLog.findMany({
      where: {
        ...(action && action !== 'all' ? { action } : {}),
        ...(query
          ? {
              OR: [
                { actorName: { contains: query, mode: 'insensitive' } },
                { details: { contains: query, mode: 'insensitive' } },
                { resourceType: { contains: query, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      orderBy: { timestamp: 'desc' },
    });
  }

  async createLog(data: {
    actorId?: string;
    actorName: string;
    actorRole: string;
    action: string;
    resourceType: string;
    resourceId: string;
    details: string;
    ipAddress?: string;
    hospitalId?: string;
  }) {
    let targetHospitalId = data.hospitalId;
    if (targetHospitalId === 'hosp-001' || !targetHospitalId) {
      const hosp = await this.prisma.hospital.findFirst();
      targetHospitalId = hosp?.id || '00000001-0000-4000-8000-000000000001';
    }

    return this.prisma.auditLog.create({
      data: {
        ...data,
        hospitalId: targetHospitalId,
      },
    });
  }
}
