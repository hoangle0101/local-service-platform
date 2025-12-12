# 📋 Setup Guide After Merging Review & Rating Feature

**Date:** December 12, 2025  
**Branch:** `develop` (after merge from `feature/review-and-rating`)

---

## ⚠️ **IMPORTANT: Thực hiện ĐÚNG THỨ TỰ các bước dưới đây!**

### **Step 1: Pull Latest Code**
```bash
git checkout develop
git pull origin develop
```

---

### **Step 2: Backend Setup**

#### **2.1 Install Dependencies**
```bash
cd apps/backend
npm install
# hoặc nếu dùng pnpm:
pnpm install
```

#### **2.2 Run Database Migration** ⚠️ **QUAN TRỌNG**
```bash
npx prisma migrate deploy
```
**Cái gì được migrate:**
- ✅ Add `pending_completion` status to `BookingStatus` enum
- ✅ Add `address`, `latitude`, `longitude` columns to `provider_profiles` table
- ✅ Add `booking_offers` table (nếu chưa có)
- ✅ Add `reviews` table (Review & Rating feature)

#### **2.3 Regenerate Prisma Client**
```bash
npx prisma generate
```

#### **2.4 Build Backend**
```bash
npm run build
```

**Kiểm tra:** Không có TypeScript errors

#### **2.5 Run Backend**
```bash
npm run start:dev
```

**Verify:** Backend chạy port 3000, không có lỗi

#### **2.6 (Optional) Seed Test Data**
```bash
npx prisma db seed
```
Nếu bạn muốn có data để test ngay.

---

### **Step 3: Mobile/Flutter Setup**

#### **3.1 Pull Latest Dependencies**
```bash
cd apps/mobile
flutter pub get
```

**Packages mới được thêm:**
- `riverpod: ^2.6.1` - State management
- `flutter_riverpod: ^2.6.1` - Flutter integration
- `freezed_annotation: ^2.4.4` - Code generation
- `json_annotation: ^4.9.0` - JSON serialization
- `build_runner: ^2.5.4` - Code generator (dev dependency)
- `freezed: ^2.5.8` - Freezed code gen (dev dependency)
- `json_serializable: ^6.9.5` - JSON serializable (dev dependency)

#### **3.2 Generate Code (if needed)**
Nếu bạn modify model files, chạy:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### **3.3 Run the App**
```bash
flutter run
```

---

## 📊 **What's New in This Merge**

### **Backend Changes:**
1. ✅ **ReviewsModule** - 7 new endpoints:
   - `POST /api/reviews` - Create review
   - `GET /api/reviews/users/:id/statistics` - Get provider rating stats
   - `GET /api/reviews/:id` - Get review detail
   - Và 4 endpoints khác

2. ✅ **Database:**
   - New `reviews` table
   - New `booking_offers` table
   - Updated `provider_profiles` with address fields
   - New `pending_completion` booking status

3. ✅ **BookingsService Updated:**
   - Support for direct/general bookings
   - Booking offers system
   - Review workflow

### **Frontend Changes:**
1. ✅ **Riverpod Integration:**
   - New `provider_provider.dart` - Rating providers
   - New `review_provider.dart` - Review providers
   - Replaced BLoC with Riverpod for rating display

2. ✅ **UI Components:**
   - `provider_profile_screen.dart` - Show dynamic ratings
   - `provider_home_screen.dart` - Show rating stats on dashboard
   - New review widgets (review_card, review_form, review_dialog, star_rating_bar)

3. ✅ **Data Layer:**
   - `review_datasource.dart` - API calls
   - `review_repository.dart` - Business logic
   - `review_model.dart` - Data models with Freezed


| Step | Command | Purpose | Status |
|------|---------|---------|--------|
| 1 | `git pull origin develop` | Get latest code | ✅ Required |
| 2 | `npm install` (backend) | Install dependencies | ✅ Required |
| 3 | `npx prisma migrate deploy` | Sync database | ✅ **CRITICAL** |
| 4 | `npx prisma generate` | Sync types | ✅ Required |
| 5 | `npm run build` | Build backend | ✅ Verify |
| 6 | `flutter pub get` (mobile) | Install dependencies | ✅ Required |

---

## 🚀 **Development Guidelines for New Features**

### **State Management: MUST USE RIVERPOD**

**Quy tắc:**
- ✅ **PHẢI dùng Riverpod** cho tất cả new features
- ✅ **Định nghĩa Provider** trong `lib/presentation/providers/`
- ✅ **Sử dụng `ConsumerWidget` hoặc `ConsumerStatefulWidget`** khi cần Riverpod
- ✅ **Error handling** với `.when(data:, loading:, error:,)`
- ❌ **KHÔNG dùng BLoC** cho features mới (chỉ dùng cho auth)

**Example Provider Structure:**
```dart
// lib/presentation/providers/review_provider.dart
final reviewProvider = FutureProvider.family<Review, int>((ref, bookingId) async {
  final datasource = ref.watch(reviewDatasourceProvider);
  return datasource.getReview(bookingId);
});
```

**Example Widget:**
```dart
class ReviewDetailWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(reviewProvider(bookingId)).when(
      data: (review) => Text(review.comment),
      loading: () => CircularProgressIndicator(),
      error: (err, st) => Text('Error: $err'),
    );
  }
}
```

### **Task Management:**
1. ✅ **Chia nhỏ tasks** - 1 feature = multiple sub-tasks
2. ✅ **Implement từng task** - code → test → commit
3. ✅ **Compile check**: `npm run build` (backend) + `flutter analyze` (mobile)
4. ✅ **Test on real device/emulator** - verify UI + logic
5. ✅ **Commit with descriptive message**

### **No Breaking Changes:**
- ✅ **Append-only** - chỉ thêm mới, không sửa code cũ
- ✅ **Backward compatible** - tất cả old features phải hoạt động
- ✅ **Zero migration issues** - đã chạy migrations
- ✅ **Type-safe** - 0 TypeScript/Dart errors

---

## ✅ **Verification Checklist**

After merge, verify:

- [ ] Backend starts without errors: `npm run start:dev`
- [ ] Database migration successful: `npx prisma migrate deploy`
- [ ] Mobile compiles: `flutter analyze` (0 issues)
- [ ] Mobile runs: `flutter run` (no crashes)
- [ ] Login works (auth still uses BLoC)
- [ ] Provider profile shows rating (Riverpod)
- [ ] Dashboard shows rating stats (Riverpod)
- [ ] Review features work (new Riverpod providers)

---

## 📞 **Support**

Nếu gặp lỗi:
1. Check **[SETUP-AFTER-MERGE.md](./SETUP-AFTER-MERGE.md)** này
2. Check **git log** để xem các commits mới
3. Run `git status` để verify workspace clean
4. Delete `.dart_tool` và `build/` folders nếu Flutter cache bị corrupt

| 7 | `npm run start:dev` (backend) | Start server | ✅ Test |
| 8 | `flutter run` (mobile) | Launch app | ✅ Test |

---

**Good luck! 🚀**
