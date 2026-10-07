import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateProcedureDto, UpdateProcedureDto } from './dto/procedure.dto';

@Injectable()
export class ProceduresService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(category?: string, status?: string) {
    return this.prisma.procedure.findMany({
      where: {
        ...(category && category !== 'all' ? { category } : {}),
        ...(status && status !== 'all' ? { status } : {}),
      },
      orderBy: { code: 'asc' },
    });
  }

  async findOne(id: string) {
    const procedure = await this.prisma.procedure.findFirst({
      where: { OR: [{ id }, { code: id }] },
    });
    if (!procedure) throw new NotFoundException('Tindakan medis tidak ditemukan');
    return procedure;
  }

  async create(dto: CreateProcedureDto) {
    const existing = await this.prisma.procedure.findUnique({
      where: { code: dto.code },
    });
    if (existing) {
      throw new BadRequestException(`Kode tindakan ${dto.code} sudah digunakan.`);
    }

    const hosp = await this.prisma.hospital.findFirst();
    const hospitalId = hosp?.id || '00000001-0000-4000-8000-000000000001';

    return this.prisma.procedure.create({
      data: {
        id: dto.id || undefined,
        hospitalId,
        code: dto.code,
        name: dto.name,
        category: dto.category || 'Umum',
        description: dto.description,
        price: dto.price,
        status: dto.status || 'active',
      },
    });
  }

  async update(id: string, dto: UpdateProcedureDto) {
    const proc = await this.findOne(id);
    return this.prisma.procedure.update({
      where: { id: proc.id },
      data: {
        ...(dto.name ? { name: dto.name } : {}),
        ...(dto.category ? { category: dto.category } : {}),
        ...(dto.description !== undefined ? { description: dto.description } : {}),
        ...(dto.price !== undefined ? { price: dto.price } : {}),
        ...(dto.status ? { status: dto.status } : {}),
      },
    });
  }

  async remove(id: string) {
    const proc = await this.findOne(id);
    return this.prisma.procedure.delete({
      where: { id: proc.id },
    });
  }
}
