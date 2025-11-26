import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SettingsService {
  constructor(private prisma: PrismaService) {}

  async getPublicSettings() {
    // Get all settings (no isPublic field in schema)
    // TODO: Add isPublic field to schema or filter by key prefix
    const settings = await this.prisma.setting.findMany();

    // Convert to key-value object
    const settingsObject = settings.reduce((acc, setting) => {
      acc[setting.key] = setting.value;
      return acc;
    }, {} as Record<string, any>);

    return settingsObject;
  }
}
