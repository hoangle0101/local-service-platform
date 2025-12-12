import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { SystemModule } from './modules/system/system.module';
import { ServicesModule } from './modules/services/services.module';
import { MarketplaceModule } from './modules/marketplace/marketplace.module';
import { ProviderModule } from './modules/provider/provider.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { WalletsModule } from './modules/wallets/wallets.module';
import { ConversationsModule } from './modules/conversations/conversations.module';
import { DisputesModule } from './modules/disputes/disputes.module';
import { AdminModule } from './modules/admin/admin.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import configuration from './config/configuration';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    SystemModule,
    ServicesModule,
    MarketplaceModule,
    ProviderModule,
    BookingsModule,
    PaymentsModule,
    WalletsModule,
    ConversationsModule,
    DisputesModule,
    AdminModule,
    ReviewsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }