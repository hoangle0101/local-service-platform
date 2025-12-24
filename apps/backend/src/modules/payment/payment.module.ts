import { Module } from '@nestjs/common';
import { PaymentController } from './payment.controller';
import { PaymentService } from './payment.service';
import { MomoService } from './momo.service';
import { WithdrawalController } from './withdrawal.controller';
import { WithdrawalService } from './withdrawal.service';
import { BookingPaymentController } from './booking-payment.controller';
import { BookingPaymentService } from './booking-payment.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [
    PaymentController,
    WithdrawalController,
    BookingPaymentController,
  ],
  providers: [
    PaymentService,
    MomoService,
    WithdrawalService,
    BookingPaymentService,
  ],
  exports: [
    PaymentService,
    MomoService,
    WithdrawalService,
    BookingPaymentService,
  ],
})
export class PaymentModule {}
