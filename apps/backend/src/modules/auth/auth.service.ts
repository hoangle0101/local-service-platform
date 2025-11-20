import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { LoginDto, OtpPurpose, RegisterDto, ResetPasswordDto, SendOtpDto, VerifyOtpDto } from './dto/auth.dto';
import { UserStatus } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
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
    const accessToken = this.jwtService.sign(payload, { expiresIn: '15m', secret: 'access-secret' });
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d', secret: 'refresh-secret' });

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
    const code = '123456'; 
    await this.prisma.otpCode.create({
      data: {
        phone: dto.phone,
        codeHash: code,
        purpose: dto.purpose,
        expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      },
    });
    return { message: 'OTP sent successfully (Mock: 123456)' };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const otp = await this.prisma.otpCode.findFirst({
      where: {
        phone: dto.phone,
        purpose: dto.purpose,
        used: false,
        codeHash: dto.code,
        expiresAt: { gt: new Date() },
      },
    });

    if (!otp) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    await this.prisma.otpCode.update({
      where: { id: otp.id },
      data: { used: true },
    });

    return { message: 'OTP verified successfully' };
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
          const payload = this.jwtService.verify(token, { secret: 'refresh-secret' });
          const session = await this.prisma.session.findFirst({
              where: { refreshTokenHash: token, revoked: false }
          });
          if (!session) throw new UnauthorizedException('Session not found or revoked');

          const newPayload = { sub: payload.sub, phone: payload.phone };
          const accessToken = this.jwtService.sign(newPayload, { expiresIn: '15m', secret: 'access-secret' });
          
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
