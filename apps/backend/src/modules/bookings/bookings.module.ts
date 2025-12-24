import { Module } from '@nestjs/common';
import { BookingsController, ProviderBookingsController } from './bookings.controller';
import { BookingsService } from './bookings.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { ConversationsModule } from '../conversations/conversations.module';

@Module({
  imports: [PrismaModule, ConversationsModule],
  controllers: [BookingsController, ProviderBookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
