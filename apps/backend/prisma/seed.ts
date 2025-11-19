import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Start seeding...');

  // ============================================
  // Seed Roles
  // ============================================
  console.log('📝 Seeding roles...');
  const roles = await Promise.all([
    prisma.role.upsert({
      where: { name: 'customer' },
      update: {},
      create: { name: 'customer', description: 'Khách hàng' },
    }),
    prisma.role.upsert({
      where: { name: 'provider' },
      update: {},
      create: { name: 'provider', description: 'Nhà cung cấp dịch vụ' },
    }),
    prisma.role.upsert({
      where: { name: 'moderator' },
      update: {},
      create: { name: 'moderator', description: 'Quản trị viên cấp thấp' },
    }),
    prisma.role.upsert({
      where: { name: 'super_admin' },
      update: {},
      create: { name: 'super_admin', description: 'Quản trị viên hệ thống' },
    }),
  ]);
  console.log(`✅ Created ${roles.length} roles`);

  // ============================================
  // Seed Permissions
  // ============================================
  console.log('📝 Seeding permissions...');
  const permissionsData = [
    { action: 'bookings.create', description: 'Tạo đặt lịch' },
    { action: 'bookings.update', description: 'Cập nhật đặt lịch' },
    { action: 'bookings.cancel', description: 'Hủy đặt lịch' },
    { action: 'bookings.view', description: 'Xem đặt lịch' },
    { action: 'providers.verify', description: 'Xác thực nhà cung cấp' },
    { action: 'providers.suspend', description: 'Tạm ngưng nhà cung cấp' },
    { action: 'disputes.manage', description: 'Quản lý tranh chấp' },
    { action: 'disputes.resolve', description: 'Giải quyết tranh chấp' },
    { action: 'users.ban', description: 'Cấm người dùng' },
    { action: 'users.unban', description: 'Bỏ cấm người dùng' },
    { action: 'reports.view', description: 'Xem báo cáo' },
    { action: 'reports.export', description: 'Xuất báo cáo' },
    { action: 'settings.update', description: 'Cập nhật cài đặt hệ thống' },
  ];

  const permissions: Array<{ id: number; action: string; description: string | null; createdAt: Date }> = [];
  for (const permData of permissionsData) {
    const perm = await prisma.permission.upsert({
      where: { action: permData.action },
      update: {},
      create: permData,
    });
    permissions.push(perm);
  }
  console.log(`✅ Created ${permissions.length} permissions`);

  // ============================================
  // Seed Role Permissions
  // ============================================
  console.log('📝 Seeding role permissions...');
  const customerRole = roles.find((r) => r.name === 'customer');
  const providerRole = roles.find((r) => r.name === 'provider');
  const moderatorRole = roles.find((r) => r.name === 'moderator');
  const adminRole = roles.find((r) => r.name === 'super_admin');

  // Customer permissions
  const customerPermissions = permissions.filter((p) =>
    ['bookings.create', 'bookings.view', 'bookings.cancel'].includes(p.action),
  );
  for (const perm of customerPermissions) {
    await prisma.rolePermission.upsert({
      where: {
        roleId_permissionId: {
          roleId: customerRole!.id,
          permissionId: perm.id,
        },
      },
      update: {},
      create: {
        roleId: customerRole!.id,
        permissionId: perm.id,
      },
    });
  }

  // Provider permissions
  const providerPermissions = permissions.filter((p) =>
    ['bookings.view', 'bookings.update'].includes(p.action),
  );
  for (const perm of providerPermissions) {
    await prisma.rolePermission.upsert({
      where: {
        roleId_permissionId: {
          roleId: providerRole!.id,
          permissionId: perm.id,
        },
      },
      update: {},
      create: {
        roleId: providerRole!.id,
        permissionId: perm.id,
      },
    });
  }

  // Moderator permissions
  const moderatorPermissions = permissions.filter((p) =>
    ['disputes.manage', 'disputes.resolve', 'providers.verify', 'reports.view'].includes(p.action),
  );
  for (const perm of moderatorPermissions) {
    await prisma.rolePermission.upsert({
      where: {
        roleId_permissionId: {
          roleId: moderatorRole!.id,
          permissionId: perm.id,
        },
      },
      update: {},
      create: {
        roleId: moderatorRole!.id,
        permissionId: perm.id,
      },
    });
  }

  // Admin gets all permissions
  for (const perm of permissions) {
    await prisma.rolePermission.upsert({
      where: {
        roleId_permissionId: {
          roleId: adminRole!.id,
          permissionId: perm.id,
        },
      },
      update: {},
      create: {
        roleId: adminRole!.id,
        permissionId: perm.id,
      },
    });
  }
  console.log('✅ Role permissions assigned');

  // ============================================
  // Seed Service Categories
  // ============================================
  console.log('📝 Seeding service categories...');
  const categories = await Promise.all([
    prisma.serviceCategory.upsert({
      where: { code: 'dien_lanh' },
      update: {},
      create: {
        code: 'dien_lanh',
        name: 'Điện lạnh',
        slug: 'dien-lanh',
        description: 'Sửa chữa, bảo dưỡng điều hòa, tủ lạnh',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { code: 've_sinh' },
      update: {},
      create: {
        code: 've_sinh',
        name: 'Vệ sinh',
        slug: 've-sinh',
        description: 'Vệ sinh nhà cửa, văn phòng, công nghiệp',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { code: 'sua_chua_dien' },
      update: {},
      create: {
        code: 'sua_chua_dien',
        name: 'Sửa chữa điện',
        slug: 'sua-chua-dien',
        description: 'Sửa chữa điện dân dụng, công nghiệp',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { code: 'ong_nuoc' },
      update: {},
      create: {
        code: 'ong_nuoc',
        name: 'Ống nước',
        slug: 'ong-nuoc',
        description: 'Sửa chữa, lắp đặt hệ thống ống nước',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { code: 'noi_that' },
      update: {},
      create: {
        code: 'noi_that',
        name: 'Nội thất',
        slug: 'noi-that',
        description: 'Lắp đặt, sửa chữa nội thất',
      },
    }),
  ]);
  console.log(`✅ Created ${categories.length} service categories`);

  // ============================================
  // Seed Services
  // ============================================
  console.log('📝 Seeding services...');
  const servicesData = [
    {
      categoryId: categories[0].id,
      name: 'Sửa điều hòa tại nhà',
      description: 'Sửa chữa, bảo dưỡng điều hòa mọi loại',
      basePrice: 200000,
      durationMinutes: 120,
    },
    {
      categoryId: categories[0].id,
      name: 'Vệ sinh điều hòa',
      description: 'Vệ sinh, bảo dưỡng điều hòa định kỳ',
      basePrice: 150000,
      durationMinutes: 90,
    },
    {
      categoryId: categories[0].id,
      name: 'Sửa tủ lạnh',
      description: 'Sửa chữa tủ lạnh mọi hãng',
      basePrice: 250000,
      durationMinutes: 120,
    },
    {
      categoryId: categories[1].id,
      name: 'Vệ sinh tổng thể',
      description: 'Vệ sinh toàn bộ nhà cửa, văn phòng',
      basePrice: 500000,
      durationMinutes: 180,
    },
    {
      categoryId: categories[1].id,
      name: 'Vệ sinh sau xây dựng',
      description: 'Vệ sinh sau khi xây dựng, sửa chữa',
      basePrice: 800000,
      durationMinutes: 240,
    },
    {
      categoryId: categories[2].id,
      name: 'Sửa chữa điện dân dụng',
      description: 'Sửa chữa hệ thống điện trong nhà',
      basePrice: 180000,
      durationMinutes: 90,
    },
    {
      categoryId: categories[3].id,
      name: 'Sửa ống nước rò rỉ',
      description: 'Sửa chữa ống nước bị rò rỉ, vỡ',
      basePrice: 150000,
      durationMinutes: 60,
    },
    {
      categoryId: categories[4].id,
      name: 'Lắp đặt rèm cửa',
      description: 'Lắp đặt rèm cửa các loại',
      basePrice: 300000,
      durationMinutes: 120,
    },
  ];

  const services: Array<{ id: number }> = [];
  for (const serviceData of servicesData) {
    const service = await prisma.service.create({
      data: serviceData,
    });
    services.push(service);
  }
  console.log(`✅ Created ${services.length} services`);

  // ============================================
  // Seed Settings
  // ============================================
  console.log('📝 Seeding settings...');
  await prisma.setting.upsert({
    where: { key: 'platform_fee_percent' },
    update: {},
    create: {
      key: 'platform_fee_percent',
      value: { value: 15, type: 'percent' },
      description: 'Phí nền tảng (%)',
    },
  });

  await prisma.setting.upsert({
    where: { key: 'min_booking_amount' },
    update: {},
    create: {
      key: 'min_booking_amount',
      value: { value: 50000, currency: 'VND' },
      description: 'Giá trị đơn hàng tối thiểu',
    },
  });

  await prisma.setting.upsert({
    where: { key: 'max_service_radius_m' },
    update: {},
    create: {
      key: 'max_service_radius_m',
      value: { value: 50000 },
      description: 'Bán kính phục vụ tối đa (mét)',
    },
  });

  await prisma.setting.upsert({
    where: { key: 'payment_methods' },
    update: {},
    create: {
      key: 'payment_methods',
      value: ['momo', 'vnpay', 'card', 'wallet'],
      description: 'Phương thức thanh toán được hỗ trợ',
    },
  });

  await prisma.setting.upsert({
    where: { key: 'maintenance_mode' },
    update: {},
    create: {
      key: 'maintenance_mode',
      value: { enabled: false, message: '' },
      description: 'Chế độ bảo trì hệ thống',
    },
  });

  console.log('✅ Created settings');

  console.log('');
  console.log('🎉 Seeding completed successfully!');
  console.log('');
  console.log('Summary:');
  console.log(`  - ${roles.length} roles`);
  console.log(`  - ${permissions.length} permissions`);
  console.log(`  - ${categories.length} service categories`);
  console.log(`  - ${services.length} services`);
  console.log('  - 5 settings');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:');
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
