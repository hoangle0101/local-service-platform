import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Seed categories
  console.log('Creating categories...');
  const categories = await Promise.all([
    prisma.serviceCategory.upsert({
      where: { slug: 'home-cleaning' },
      update: {},
      create: {
        code: 'HOME_CLEANING',
        name: 'Home Cleaning',
        slug: 'home-cleaning',
        description: 'Professional home cleaning services',
        iconUrl: 'https://example.com/icons/cleaning.png',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { slug: 'plumbing' },
      update: {},
      create: {
        code: 'PLUMBING',
        name: 'Plumbing',
        slug: 'plumbing',
        description: 'Plumbing repair and installation',
        iconUrl: 'https://example.com/icons/plumbing.png',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { slug: 'electrical' },
      update: {},
      create: {
        code: 'ELECTRICAL',
        name: 'Electrical',
        slug: 'electrical',
        description: 'Electrical services',
        iconUrl: 'https://example.com/icons/electrical.png',
      },
    }),
    prisma.serviceCategory.upsert({
      where: { slug: 'gardening' },
      update: {},
      create: {
        code: 'GARDENING',
        name: 'Gardening',
        slug: 'gardening',
        description: 'Garden maintenance',
        iconUrl: 'https://example.com/icons/garden.png',
      },
    }),
  ]);
  console.log(`✅ Created ${categories.length} categories`);

  // Seed services
  console.log('Creating services...');
  const services = await Promise.all([
    prisma.service.upsert({
      where: { id: 1 },
      update: {},
      create: {
        id: 1,
        categoryId: categories[0].id,
        name: 'Basic House Cleaning',
        description: 'General house cleaning service',
        basePrice: 200000,
        durationMinutes: 120,
      },
    }),
    prisma.service.upsert({
      where: { id: 2 },
      update: {},
      create: {
        id: 2,
        categoryId: categories[0].id,
        name: 'Deep Cleaning',
        description: 'Thorough deep cleaning',
        basePrice: 350000,
        durationMinutes: 180,
      },
    }),
    prisma.service.upsert({
      where: { id: 3 },
      update: {},
      create: {
        id: 3,
        categoryId: categories[1].id,
        name: 'Pipe Repair',
        description: 'Fix leaking pipes',
        basePrice: 150000,
        durationMinutes: 60,
      },
    }),
    prisma.service.upsert({
      where: { id: 4 },
      update: {},
      create: {
        id: 4,
        categoryId: categories[1].id,
        name: 'Toilet Installation',
        description: 'Install new toilet',
        basePrice: 300000,
        durationMinutes: 90,
      },
    }),
    prisma.service.upsert({
      where: { id: 5 },
      update: {},
      create: {
        id: 5,
        categoryId: categories[2].id,
        name: 'Wiring Repair',
        description: 'Fix electrical wiring',
        basePrice: 180000,
        durationMinutes: 90,
      },
    }),
    prisma.service.upsert({
      where: { id: 6 },
      update: {},
      create: {
        id: 6,
        categoryId: categories[3].id,
        name: 'Lawn Mowing',
        description: 'Mow lawn and trim edges',
        basePrice: 120000,
        durationMinutes: 60,
      },
    }),
  ]);
  console.log(`✅ Created ${services.length} services`);

  // Check if user exists
  const user = await prisma.user.findFirst();
  if (!user) {
    console.log('⚠️  No users found. Please register a user first.');
    return;
  }

  // Create provider profile
  console.log('Creating provider profile...');
  const provider = await prisma.providerProfile.upsert({
    where: { userId: user.id },
    update: {},
    create: {
      userId: user.id,
      displayName: 'John Cleaning Services',
      bio: 'Professional cleaner with 5 years experience',
      ratingAvg: 4.5,
      ratingCount: 20,
      isAvailable: true,
      verificationStatus: 'verified',
      serviceRadiusM: 10000,
    },
  });
  console.log(`✅ Created provider profile for user ${user.id}`);

  // Add services to provider
  console.log('Adding services to provider...');
  await prisma.providerService.upsert({
    where: {
      providerUserId_serviceId: {
        providerUserId: user.id,
        serviceId: 1,
      },
    },
    update: {},
    create: {
      providerUserId: user.id,
      serviceId: 1,
      price: 200000,
      currency: 'VND',
      isActive: true,
    },
  });

  await prisma.providerService.upsert({
    where: {
      providerUserId_serviceId: {
        providerUserId: user.id,
        serviceId: 2,
      },
    },
    update: {},
    create: {
      providerUserId: user.id,
      serviceId: 2,
      price: 350000,
      currency: 'VND',
      isActive: true,
    },
  });
  console.log(`✅ Added 2 services to provider`);

  console.log('🎉 Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
