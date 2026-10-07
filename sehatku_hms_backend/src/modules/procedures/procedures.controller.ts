import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CreateProcedureDto, UpdateProcedureDto } from './dto/procedure.dto';
import { ProceduresService } from './procedures.service';

@ApiTags('Clinic Procedures')
@Controller('procedures')
export class ProceduresController {
  constructor(private readonly proceduresService: ProceduresService) {}

  @Get()
  @ApiOperation({ summary: 'Daftar katalog tindakan medis & tarif klinik' })
  @ApiQuery({ name: 'category', required: false, example: 'Tindakan Medis' })
  @ApiQuery({ name: 'status', required: false, example: 'active' })
  @ApiResponse({ status: 200, description: 'Berhasil memuat daftar tindakan' })
  findAll(@Query('category') category?: string, @Query('status') status?: string) {
    return this.proceduresService.findAll(category, status);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Detail tindakan medis berdasarkan ID atau Kode' })
  findOne(@Param('id') id: string) {
    return this.proceduresService.findOne(id);
  }

  @Post()
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Tambah master tindakan medis & tarif baru' })
  create(@Body() dto: CreateProcedureDto) {
    return this.proceduresService.create(dto);
  }

  @Patch(':id')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Perbarui tarif atau nama tindakan medis' })
  update(@Param('id') id: string, @Body() dto: UpdateProcedureDto) {
    return this.proceduresService.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(AuthGuard('jwt'))
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Hapus tindakan medis dari katalog' })
  remove(@Param('id') id: string) {
    return this.proceduresService.remove(id);
  }
}
