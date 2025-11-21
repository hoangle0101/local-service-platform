import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { LoginDto, OtpPurpose, RegisterDto, ResetPasswordDto, SendOtpDto, VerifyOtpDto } from './dto/auth.dto';
import { UserStatus } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const existingUser = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
    });
    if (existingUser) {
      throw new BadRequestException('User with this phone number already exists');
    }

    const salt = await bcrypt.genSalt();
    const passwordHash = await bcrypt.hash(dto.password, salt);

    const user = await this.prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          phone: dto.phone,
          passwordHash,
          status: UserStatus.active,
          wallet: {
            create: {
              balance: 0,
              currency: 'VND',
            },
          },
          profile: {
            create: {
              fullName: dto.fullName,
            },
          },
        },
        include: {
          wallet: true,
          profile: true,
        },
      });
      return newUser;
    });

    return this.generateTokens(user.id, user.phone);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isMatch = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (user.status !== UserStatus.active) {
      throw new UnauthorizedException('User is not active');
    }

    return this.generateTokens(user.id, user.phone);
  }

  async generateTokens(userId: bigint, phone: string) {
    const payload = { sub: userId.toString(), phone };
    
    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.accessSecret'),
      expiresIn: this.configService.get<string>('jwt.accessExpiresIn') as any,
    });
    
    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.refreshSecret'),
      expiresIn: this.configService.get<string>('jwt.refreshExpiresIn') as any,
    });

    await this.prisma.session.create({
      data: {
        userId,
        refreshTokenHash: refreshToken,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    return {
      accessToken,
      refreshToken,
    };
  }

  async sendOtp(dto: SendOtpDto) {
    // Generate random 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Hash the code for security
    const salt = await bcrypt.genSalt();
    const codeHash = await bcrypt.hash(code, salt);
    
    await this.prisma.otpCode.create({
      data: {
        phone: dto.phone,
        codeHash,
        purpose: dto.purpose,
        expiresAt: new Date(Date.now() + 5 * 60 * 1000),
        attemptCount: 0,
      },
    });
    
    // TODO: Send SMS via provider (Twilio, AWS SNS, etc.)
    console.log(`[OTP] Phone: ${dto.phone}, Code: ${code}`);
    
    // Return code only in development
    return {
      message: 'OTP sent successfully',
      ...(process.env.NODE_ENV === 'development' && { code }),
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    // Get all valid OTPs for this phone and purpose
    const otps = await this.prisma.otpCode.findMany({
      where: {
        phone: dto.phone,
        purpose: dto.purpose,
        used: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (otps.length === 0) {
      throw new BadRequestException('No valid OTP found');
    }

    // Try to verify with each OTP (in case of multiple attempts)
    for (const otp of otps) {
      // Check max attempts
      if (otp.attemptCount >= 5) {
        continue;
      }

      // Verify code using bcrypt
      const isValid = await bcrypt.compare(dto.code, otp.codeHash);

      if (isValid) {
        // Mark as used
        await this.prisma.otpCode.update({
          where: { id: otp.id },
          data: { used: true },
        });
        return { message: 'OTP verified successfully' };
      }

      // Increment attempt count
      await this.prisma.otpCode.update({
        where: { id: otp.id },
        data: {
          attemptCount: otp.attemptCount + 1,
          lastAttemptAt: new Date(),
        },
      });
    }

    throw new BadRequestException('Invalid OTP code');
  }
  
  async resetPassword(dto: ResetPasswordDto) {
      await this.verifyOtp({ phone: dto.phone, code: dto.otp, purpose: OtpPurpose.RESET_PASSWORD });

      const salt = await bcrypt.genSalt();
      const passwordHash = await bcrypt.hash(dto.newPassword, salt);

      await this.prisma.user.update({
          where: { phone: dto.phone },
          data: { passwordHash }
      });

      return { message: 'Password reset successfully' };
  }

  async refreshToken(token: string) {
      try {
          const payload = this.jwtService.verify(token, {
            secret: this.configService.get<string>('jwt.refreshSecret'),
          });
          
          const session = await this.prisma.session.findFirst({
              where: { refreshTokenHash: token, revoked: false }
          });
          
          if (!session) {
            throw new UnauthorizedException('Session not found or revoked');
          }

          const newPayload = { sub: payload.sub, phone: payload.phone };
          const accessToken = this.jwtService.sign(newPayload, {
            secret: this.configService.get<string>('jwt.accessSecret'),
            expiresIn: this.configService.get<string>('jwt.accessExpiresIn') as any,
          });
          
          return { accessToken };
      } catch (e) {
          throw new UnauthorizedException('Invalid refresh token');
      }
  }

  async logout(refreshToken: string) {
      await this.prisma.session.updateMany({
          where: { refreshTokenHash: refreshToken },
          data: { revoked: true, revokedAt: new Date() }
      });
      return { message: 'Logged out successfully' };
  }
}
