import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateProcedureDto {
  @ApiPropertyOptional({ description: 'UUID Tindakan (opsional)' })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({ example: 'PROC-011', description: 'Kode unik tindakan klinik' })
  @IsNotEmpty()
  @IsString()
  code: string;

  @ApiProperty({ example: 'Injeksi Neurobion 5000', description: 'Nama tindakan medis' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Tindakan Medis', description: 'Kategori tindakan' })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({ example: 'Injeksi vitamin B kompleks intramuskular.', description: 'Deskripsi' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 65000, description: 'Tarif tindakan dalam Rupiah' })
  @IsNotEmpty()
  @IsNumber()
  price: number;

  @ApiPropertyOptional({ example: 'active', description: 'Status tindakan: active/inactive' })
  @IsOptional()
  @IsString()
  status?: string;
}

export class UpdateProcedureDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  price?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  status?: string;
}
