import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import * as fs from 'fs';
import * as path from 'path';

export interface MedicineInventoryItem {
  id: string;
  name: string;
  category: string;
  form: string;
  stock: number;
  minStock: number;
  unit: string;
  batchNumber: string;
  expirationDate: string;
  price: number;
  status: 'normal' | 'low' | 'critical';
}

@Injectable()
export class PharmacyService implements OnModuleInit {
  constructor(private readonly prisma: PrismaService) {}

  private readonly dataFilePath = path.join(process.cwd(), 'data', 'pharmacy_inventory.json');

  onModuleInit() {
    this.loadInventoryFromDisk();
  }

  private loadInventoryFromDisk() {
    try {
      if (fs.existsSync(this.dataFilePath)) {
        const raw = fs.readFileSync(this.dataFilePath, 'utf-8');
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed) && parsed.length > 0) {
          this.inventory = parsed;
          return;
        }
      }
      this.saveInventoryToDisk();
    } catch (e) {
      console.error('[PharmacyService] Failed to load inventory from disk:', e);
    }
  }

  private saveInventoryToDisk() {
    try {
      const dir = path.dirname(this.dataFilePath);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      fs.writeFileSync(this.dataFilePath, JSON.stringify(this.inventory, null, 2), 'utf-8');
    } catch (e) {
      console.error('[PharmacyService] Failed to save inventory to disk:', e);
    }
  }

  // Persistent inventory store synced with formulary
  private inventory: MedicineInventoryItem[] = [
    {
      id: '78000000-0000-4000-8000-000000000001',
      name: 'Amlodipine Besylate 5mg',
      category: 'Antihipertensi',
      form: 'Tablet',
      stock: 450,
      minStock: 100,
      unit: 'strip (10 tab)',
      batchNumber: 'BATCH-AML-2026-08',
      expirationDate: '2028-12-31',
      price: 25000,
      status: 'normal',
    },
    {
      id: '78000000-0000-4000-8000-000000000002',
      name: 'Paracetamol 500mg',
      category: 'Analgesik & Antipiretik',
      form: 'Kaplet',
      stock: 80,
      minStock: 150,
      unit: 'strip (10 kap)',
      batchNumber: 'BATCH-PCT-2026-05',
      expirationDate: '2028-06-30',
      price: 12000,
      status: 'low',
    },
    {
      id: '78000000-0000-4000-8000-000000000003',
      name: 'Amoxicillin 500mg',
      category: 'Antibiotik',
      form: 'Kapsul',
      stock: 320,
      minStock: 100,
      unit: 'strip (10 kap)',
      batchNumber: 'BATCH-AMX-2026-03',
      expirationDate: '2027-11-30',
      price: 35000,
      status: 'normal',
    },
    {
      id: '78000000-0000-4000-8000-000000000004',
      name: 'Omeprazole 20mg',
      category: 'Antasida & Saluran Cerna',
      form: 'Kapsul lepas lambat',
      stock: 25,
      minStock: 80,
      unit: 'strip (10 kap)',
      batchNumber: 'BATCH-OMZ-2025-11',
      expirationDate: '2027-04-15',
      price: 42000,
      status: 'critical',
    },
    {
      id: '78000000-0000-4000-8000-000000000005',
      name: 'Cetirizine HCl 10mg',
      category: 'Antihistamin / Alergi',
      form: 'Tablet',
      stock: 180,
      minStock: 60,
      unit: 'strip (10 tab)',
      batchNumber: 'BATCH-CTZ-2026-01',
      expirationDate: '2028-09-30',
      price: 20000,
      status: 'normal',
    },
    {
      id: '78000000-0000-4000-8000-000000000006',
      name: 'Coenzyme Q10 100mg',
      category: 'Suplemen Kardio',
      form: 'Kapsul lunak',
      stock: 95,
      minStock: 50,
      unit: 'botol (30 kap)',
      batchNumber: 'BATCH-Q10-2026-07',
      expirationDate: '2028-03-20',
      price: 125000,
      status: 'normal',
    },
    {
      id: '78000000-0000-4000-8000-000000000007',
      name: 'Metformin HCl 500mg',
      category: 'Antidiabetes',
      form: 'Tablet',
      stock: 210,
      minStock: 80,
      unit: 'strip (10 tab)',
      batchNumber: 'BATCH-MTF-2026-04',
      expirationDate: '2028-10-31',
      price: 18000,
      status: 'normal',
    },
  ];

  async findAllPrescriptions(status?: string) {
    const prescriptions = await this.prisma.prescription.findMany({
      where: status && status !== 'all' ? { status } : undefined,
      include: {
        patient: {
          select: {
            id: true,
            name: true,
            medicalRecordNumber: true,
            birthDate: true,
            gender: true,
            insuranceProvider: true,
          },
        },
        doctor: {
          select: {
            id: true,
            name: true,
            specialist: true,
          },
        },
        items: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return prescriptions.map((p) => {
      let statusLabel = 'Menunggu Diracik';
      if (p.status === 'dispensing') statusLabel = 'Sedang Diracik';
      if (p.status === 'ready') statusLabel = 'Siap Diambil';
      if (p.status === 'completed' || p.status === 'dispensed') statusLabel = 'Selesai Diserahkan';

      return {
        id: p.id,
        prescriptionNumber: `RX-${p.id.substring(0, 8).toUpperCase()}`,
        patientId: p.patientId,
        patientName: p.patient?.name || 'Pasien',
        patientMrn: p.patient?.medicalRecordNumber || 'MRN-2026-001',
        insurance: p.patient?.insuranceProvider || 'Umum',
        doctorId: p.doctorId,
        doctorName: p.doctor?.name || 'Dokter Spesialis',
        doctorSpecialist: p.doctor?.specialist || 'Spesialis',
        status: p.status,
        statusLabel,
        notes: p.notes || '',
        createdAt: p.createdAt,
        items: p.items.map((item) => ({
          id: item.id,
          medicineName: item.medicineName,
          dosage: item.dosage,
          frequency: item.frequency,
          route: item.route,
          durationDays: item.durationDays,
          instruction: item.instruction || '',
        })),
      };
    });
  }

  async updatePrescriptionStatus(id: string, newStatus: string) {
    const prescription = await this.prisma.prescription.findUnique({
      where: { id },
      include: { items: true, patient: true },
    });

    if (!prescription) {
      throw new NotFoundException(`Resep dengan ID ${id} tidak ditemukan`);
    }

    const updated = await this.prisma.prescription.update({
      where: { id },
      data: { status: newStatus },
      include: { patient: true, doctor: true, items: true },
    });

    // If completed / handed over to patient, automatically deduct inventory
    if (newStatus === 'completed' || newStatus === 'dispensed') {
      for (const item of updated.items) {
        this.deductStockByName(item.medicineName, 1);
      }
    }

    // Auto-trigger notifications for Patient
    try {
      if (newStatus === 'ready') {
        await this.prisma.notification.create({
          data: {
            role: 'patient',
            title: 'Obat Siap Diambil di Loket Farmasi',
            message: `Resep obat Anda telah selesai diracik. Silakan menuju Loket Farmasi Rumah Sakit dengan menyebutkan No. RM ${updated.patient?.medicalRecordNumber || '-'}.`,
            type: 'prescription',
            targetId: updated.id,
            isRead: false,
          },
        });
      } else if (newStatus === 'completed' || newStatus === 'dispensed') {
        await this.prisma.notification.create({
          data: {
            role: 'patient',
            title: 'Obat Telah Diserahkan Farmasi',
            message: `Resep obat telah selesai diserahkan. Pastikan membaca aturan pakai dan meminum obat secara teratur sesuai petunjuk dokter.`,
            type: 'prescription',
            targetId: updated.id,
            isRead: false,
          },
        });
      }
    } catch (e) {}

    // Audit log
    await this.prisma.auditLog.create({
      data: {
        actorName: 'Apoteker Farmasi',
        actorRole: 'pharmacist',
        action: 'UPDATE',
        resourceType: 'Prescription',
        resourceId: updated.id,
        details: `Mengubah status resep ${updated.patient?.name} menjadi ${newStatus}`,
      },
    });

    return {
      success: true,
      message: `Status resep berhasil diubah menjadi ${newStatus}`,
      prescriptionId: updated.id,
      status: updated.status,
    };
  }

  getInventory(query?: string) {
    if (!query || query.trim() === '') {
      return this.inventory;
    }
    const q = query.toLowerCase();
    return this.inventory.filter(
      (m) =>
        m.name.toLowerCase().includes(q) ||
        m.category.toLowerCase().includes(q) ||
        m.batchNumber.toLowerCase().includes(q),
    );
  }

  addMedicine(dto: {
    name: string;
    category?: string;
    form?: string;
    stock?: number;
    minStock?: number;
    unit?: string;
    batchNumber?: string;
    expirationDate?: string;
    price?: number;
  }) {
    const stock = Number(dto.stock) || 0;
    const minStock = Number(dto.minStock) || 50;
    const newItem: MedicineInventoryItem = {
      id: require('crypto').randomUUID(),
      name: dto.name,
      category: dto.category || 'Obat Bebas',
      form: dto.form || 'Tablet',
      stock,
      minStock,
      unit: dto.unit || 'strip (10 tab)',
      batchNumber: dto.batchNumber || `BATCH-${Date.now().toString().slice(-6)}`,
      expirationDate: dto.expirationDate || '2028-12-31',
      price: Number(dto.price) || 10000,
      status: stock <= minStock / 2 ? 'critical' : stock <= minStock ? 'low' : 'normal',
    };
    this.inventory.unshift(newItem);
    this.saveInventoryToDisk();
    return newItem;
  }

  adjustStock(id: string, quantity: number) {
    const item = this.inventory.find((m) => m.id === id);
    if (!item) {
      throw new NotFoundException(`Obat dengan ID ${id} tidak ditemukan di inventori`);
    }

    item.stock = Math.max(0, item.stock + quantity);
    if (item.stock <= item.minStock / 2) {
      item.status = 'critical';
    } else if (item.stock <= item.minStock) {
      item.status = 'low';
    } else {
      item.status = 'normal';
    }

    this.saveInventoryToDisk();

    return {
      success: true,
      message: `Stok obat ${item.name} berhasil diperbarui menjadi ${item.stock} ${item.unit}`,
      item,
    };
  }

  private deductStockByName(medicineName: string, quantity = 1) {
    const item = this.inventory.find((m) =>
      m.name.toLowerCase().includes(medicineName.toLowerCase().split(' ')[0]),
    );
    if (item) {
      item.stock = Math.max(0, item.stock - quantity);
      if (item.stock <= item.minStock / 2) {
        item.status = 'critical';
      } else if (item.stock <= item.minStock) {
        item.status = 'low';
      }
      this.saveInventoryToDisk();
    }
  }

  private readonly configFilePath = path.join(process.cwd(), 'data', 'pharmacy_config.json');

  private readonly defaultCategories = [
    'Analgesik & Antipiretik',
    'Antibiotik',
    'Antihipertensi',
    'Antasida & Saluran Cerna',
    'Antihistamin / Alergi',
    'Suplemen & Vitamin',
    'Obat Luar / Topikal',
    'Obat Batuk & Flu',
    'Kardiologi & Jantung',
    'Lainnya',
  ];

  private readonly defaultForms = [
    'Tablet',
    'Kaplet',
    'Kapsul',
    'Sirup / Suspensi',
    'Salep / Krim / Gel',
    'Tetes Mata / Telinga',
    'Injeksi / Ampul',
    'Larutan Infus',
  ];

  private readonly defaultUnits = [
    'strip (10 tab)',
    'strip (10 kap)',
    'botol (60 ml)',
    'botol (100 ml)',
    'tube (10 gr)',
    'tube (15 gr)',
    'ampul',
    'vial',
    'sachet',
    'box',
  ];

  private loadConfigFromFile(): { categories: string[]; forms: string[]; units: string[] } {
    try {
      if (fs.existsSync(this.configFilePath)) {
        const raw = fs.readFileSync(this.configFilePath, 'utf-8');
        const parsed = JSON.parse(raw);
        if (parsed.categories && parsed.forms && parsed.units) {
          return parsed;
        }
      }
    } catch (e) {
      console.error('[PharmacyService] Error reading pharmacy config file:', e);
    }
    return {
      categories: this.defaultCategories,
      forms: this.defaultForms,
      units: this.defaultUnits,
    };
  }

  private saveConfigToFile(config: { categories: string[]; forms: string[]; units: string[] }) {
    try {
      const dir = path.dirname(this.configFilePath);
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(this.configFilePath, JSON.stringify(config, null, 2), 'utf-8');
    } catch (e) {
      console.error('[PharmacyService] Error saving pharmacy config file:', e);
    }
  }

  async getPharmacyConfig() {
    try {
      const dbConfig = await this.prisma.pharmacyConfig.findFirst();
      if (dbConfig) {
        const result = {
          categories: dbConfig.categories,
          forms: dbConfig.forms,
          units: dbConfig.units,
        };
        this.saveConfigToFile(result);
        return result;
      }
      // If table exists but empty, create seed row
      const hosp = await this.prisma.hospital.findFirst();
      const created = await this.prisma.pharmacyConfig.create({
        data: {
          hospitalId: hosp?.id || null,
          categories: this.defaultCategories,
          forms: this.defaultForms,
          units: this.defaultUnits,
        },
      });
      return {
        categories: created.categories,
        forms: created.forms,
        units: created.units,
      };
    } catch (e) {
      // Graceful fallback to persistent JSON file
      return this.loadConfigFromFile();
    }
  }

  async updatePharmacyConfig(dto: { categories?: string[]; forms?: string[]; units?: string[] }) {
    const current = await this.getPharmacyConfig();
    const updated = {
      categories: dto.categories && dto.categories.length > 0 ? dto.categories : current.categories,
      forms: dto.forms && dto.forms.length > 0 ? dto.forms : current.forms,
      units: dto.units && dto.units.length > 0 ? dto.units : current.units,
    };

    try {
      const dbConfig = await this.prisma.pharmacyConfig.findFirst();
      if (dbConfig) {
        await this.prisma.pharmacyConfig.update({
          where: { id: dbConfig.id },
          data: {
            categories: updated.categories,
            forms: updated.forms,
            units: updated.units,
          },
        });
      } else {
        const hosp = await this.prisma.hospital.findFirst();
        await this.prisma.pharmacyConfig.create({
          data: {
            hospitalId: hosp?.id || null,
            categories: updated.categories,
            forms: updated.forms,
            units: updated.units,
          },
        });
      }
    } catch (e) {
      console.warn('[PharmacyService] DB update skipped, falling back to disk:', e);
    }

    this.saveConfigToFile(updated);
    return updated;
  }
}
