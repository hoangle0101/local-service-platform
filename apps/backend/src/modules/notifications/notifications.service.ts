import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  async create(
    userId: bigint,
    type: string,
    title: string,
    body: string,
    payload?: any,
  ) {
    // 1. Create in DB
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        type,
        title,
        body,
        payload: payload || {},
      },
    });

    // 2. Ideally send via Socket/Push here
    console.log(`[Notification] Created for user ${userId}: ${title}`);

    return notification;
  }
}
