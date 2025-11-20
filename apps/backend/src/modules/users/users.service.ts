import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AddressDto, ChangePasswordDto, DeviceDto, FavoriteDto, UpdateProfileDto } from './dto/user.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: bigint) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        wallet: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    const { passwordHash, ...result } = user;
    return result;
  }

  async updateProfile(userId: bigint, dto: UpdateProfileDto) {
    return this.prisma.userProfile.update({
      where: { userId },
      data: {
        ...dto,
      },
    });
  }

  async changePassword(userId: bigint, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.passwordHash) throw new BadRequestException('User not found');

    const isMatch = await bcrypt.compare(dto.oldPassword, user.passwordHash);
    if (!isMatch) throw new BadRequestException('Incorrect old password');

    const salt = await bcrypt.genSalt();
    const newPasswordHash = await bcrypt.hash(dto.newPassword, salt);

    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: newPasswordHash },
    });

    return { message: 'Password updated successfully' };
  }

  async getAddresses(userId: bigint) {
    return this.prisma.address.findMany({ where: { userId } });
  }

  async addAddress(userId: bigint, dto: AddressDto) {
    const isDefault = dto.isDefault || false;
    
    if (isDefault) {
        await this.prisma.address.updateMany({
            where: { userId },
            data: { isDefault: false }
        });
    }

    const point = `ST_SetSRID(ST_MakePoint(0, 0), 4326)`; 
    
    await this.prisma.$executeRaw`
      INSERT INTO addresses (user_id, label, address_text, location, is_default, created_at, updated_at)
      VALUES (${userId}, ${dto.label}, ${dto.addressText}, ${point}::geography, ${isDefault}, NOW(), NOW())
    `;
    
    return { message: 'Address added successfully' };
  }

  async updateAddress(userId: bigint, addressId: bigint, dto: AddressDto) {
      await this.prisma.address.update({
          where: { id: addressId, userId },
          data: {
              label: dto.label,
              addressText: dto.addressText,
              isDefault: dto.isDefault
          }
      });
      return { message: 'Address updated' };
  }

  async deleteAddress(userId: bigint, addressId: bigint) {
      await this.prisma.address.delete({
          where: { id: addressId, userId }
      });
      return { message: 'Address deleted' };
  }

  async getFavorites(userId: bigint) {
      return this.prisma.favorite.findMany({ where: { userId } });
  }

  async addFavorite(userId: bigint, dto: FavoriteDto) {
      return this.prisma.favorite.create({
          data: {
              userId,
              targetType: dto.targetType,
              targetId: dto.targetId
          }
      });
  }

  async removeFavoriteComposite(userId: bigint, targetId: bigint, targetType: string) {
      await this.prisma.favorite.delete({
          where: {
              userId_targetType_targetId: {
                  userId,
                  targetId,
                  targetType
              }
          }
      });
      return { message: 'Favorite removed' };
  }

  async registerDevice(userId: bigint, dto: DeviceDto) {
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (!user) throw new NotFoundException('User not found');
      
      let metadata: any = user.metadata || {};
      
      let devices = metadata.devices || [];
      if (!devices.includes(dto.fcmToken)) {
          devices.push(dto.fcmToken);
      }
      
      metadata.devices = devices;
      
      await this.prisma.user.update({
          where: { id: userId },
          data: { metadata }
      });
      
      return { message: 'Device registered' };
  }
  
  async getNotifications(userId: bigint) {
      return this.prisma.notification.findMany({
          where: { userId },
          orderBy: { createdAt: 'desc' }
      });
  }
  
  async readAllNotifications(userId: bigint) {
      await this.prisma.notification.updateMany({
          where: { userId, isRead: false },
          data: { isRead: true }
      });
      return { message: 'All notifications marked as read' };
  }
}
