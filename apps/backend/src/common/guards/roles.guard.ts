import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma/prisma.service';
import { ROLES_KEY } from '../decorators/roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    
    if (!requiredRoles) {
      return true;
    }
    
    const { user } = context.switchToHttp().getRequest();
    
    if (!user || !user.userId) {
      return false;
    }
    
    // Get user roles from database
    const userRoles = await this.prisma.userRole.findMany({
      where: { userId: BigInt(user.userId) },
      include: { role: true },
    });
    
    const roleNames = userRoles.map((ur) => ur.role.name);
    
    // Check if user has any of the required roles
    return requiredRoles.some((role) => roleNames.includes(role));
  }
}
