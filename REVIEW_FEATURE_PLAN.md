# 📋 PHƯƠNG ÁN THỰC HIỆN CHỨC NĂNG "ĐÁNH GIÁ VÀ BÌNH LUẬN"

## 🎯 PHÂN TÍCH REQUIREMENT

### Backend (Đã có)
- ✅ Model `Review` trong Prisma:
  - `id`, `bookingId`, `reviewerId`, `revieweeId`
  - `rating` (1-5 sao), `title`, `comment`
  - `createdAt`
- ✅ Module `reviews/` (nếu có) hoặc API endpoint
- ✅ API: `POST /api/bookings/{id}/reviews` (tạo review)
- ✅ API: `GET /api/reviews/booking/{id}` (lấy reviews của booking)

### Frontend (Cần xây dựng)
- ❌ UI: Review dialog/screen sau khi booking completed
- ❌ State Management: Riverpod providers for review data
- ❌ Components: Rating widget, review form
- ❌ Integration: API client cho reviews

---

## 🛠️ TECH STACK CHÍNH

| Layer | Technology | Notes |
|-------|-----------|-------|
| **State Management** | **Riverpod** | Thay BLoC |
| **Color Scheme** | **Upwork-inspired Green (#14A800)** | Primary color |
| **Typography** | **Google Fonts (Inter)** | Đã có trong theme |
| **UI Components** | **Material 3** | Tái sử dụng CardTheme, buttons |
| **API Client** | **Dio** | Đã có dependency |

---

## 📁 CẤU TRÚC FILE CẦN TẠO

```
lib/
├── data/
│   ├── datasources/
│   │   └── review_datasource.dart        # API calls
│   ├── models/
│   │   ├── review_model.dart             # JSON serialization
│   │   └── create_review_request.dart    # DTO
│   └── repositories/
│       └── review_repository.dart        # Business logic
│
├── presentation/
│   ├── providers/
│   │   ├── review_provider.dart          # Riverpod providers (main)
│   │   └── review_state.dart             # State classes
│   ├── screens/
│   │   └── review_screen.dart            # Full review screen
│   └── widgets/
│       ├── rating_input_widget.dart      # Star rating input
│       ├── review_form_widget.dart       # Form component
│       ├── review_card_widget.dart       # Display review
│       ├── review_dialog.dart            # Quick review modal
│       └── star_rating_bar.dart          # Reusable star rating
│
└── core/
    └── constants/
        └── review_constants.dart         # Min/max rating, etc
```

---

## 🔄 LUỒNG DỮ LIỆU

```
┌─────────────────────────────────────────┐
│  Booking Completed Status               │
│  (triggered after booking.completed)    │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│  Show "Leave Review" Dialog             │
│  (reviewDialog.dart)                    │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│  User Input:                            │
│  - Rating (1-5 stars)                   │
│  - Title                                │
│  - Comment                              │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│  Riverpod Provider (submitReview)       │
│  - Validate input                       │
│  - Call API POST /api/bookings/{}/      │
│    reviews                              │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│  Update State:                          │
│  - Invalidate review provider           │
│  - Show success toast                   │
│  - Close dialog                         │
└─────────────────────────────────────────┘
```

---

## 📊 RIVERPOD PROVIDERS STRUCTURE

```dart
// review_provider.dart

// 1️⃣ Repository Provider
final reviewRepositoryProvider = Provider((ref) {
  return ReviewRepository(ref.read(dioProvider));
});

// 2️⃣ Fetch Reviews for Booking
final fetchReviewsByBookingProvider = FutureProvider.family<
  List<Review>,
  int  // booking id
>((ref, bookingId) async {
  return ref.read(reviewRepositoryProvider)
    .getReviewsByBooking(bookingId);
});

// 3️⃣ Submit Review (with loading/error state)
final submitReviewProvider = FutureProvider.autoDispose.family<
  Review,
  CreateReviewRequest
>((ref, request) async {
  return ref.read(reviewRepositoryProvider)
    .createReview(request);
});

// 4️⃣ User's Reviews (for profile)
final userReviewsProvider = FutureProvider.family<
  List<Review>,
  int  // user id
>((ref, userId) async {
  return ref.read(reviewRepositoryProvider)
    .getUserReviews(userId);
});

// 5️⃣ Average Rating Provider (computed)
final averageRatingProvider = FutureProvider.family<
  double,
  int  // user id (provider id)
>((ref, providerId) async {
  final reviews = await ref.watch(
    fetchProviderReviewsProvider(providerId).future
  );
  if (reviews.isEmpty) return 0.0;
  final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
  return sum / reviews.length;
});
```

---

## 🎨 COLOR PALETTE MAPPING

| Element | Color | Hex |
|---------|-------|-----|
| **Primary Button** | Primary Green | #14A800 |
| **Star (Active)** | Primary Green | #14A800 |
| **Star (Inactive)** | Grey300 | #D1D5DB |
| **Success Message** | Success | #14A800 |
| **Card Background** | White | #FFFFFF |
| **Text Primary** | Grey900 | #111827 |
| **Text Secondary** | Grey500 | #6B7280 |
| **Border** | Grey200 | #E5E7EB |

---

## ✨ KEY FEATURES

### 1. Rating Input
- ⭐⭐⭐⭐⭐ Interactive star rating (drag or tap)
- Color change: grey → green on hover/select
- Show rating count (e.g., "4 out of 5")

### 2. Review Form
- **Required Fields**: Rating, Title
- **Optional Fields**: Comment (max 500 chars)
- **Validation**: Real-time error messages
- **Submit Button**: Disabled until rating selected

### 3. Review Display
- Show all reviews under booking details
- Review card layout:
  - Provider/Customer avatar
  - Name, date, rating
  - Title, comment
  - Can delete own review

### 4. Review Dialog (Quick entry)
- Modal dialog on booking completion
- Minimal form with rating + quick comment
- "Skip" & "Submit" buttons

---

## 🚀 PHƯƠNG ÁN THỰC HIỆN TỪNG BƯỚC

### **PHASE 1: Setup Dependencies & Models (Day 1)**
1. Cập nhật `pubspec.yaml` thêm Riverpod
2. Tạo `ReviewModel` với JSON serialization
3. Tạo `CreateReviewRequest` DTO

### **PHASE 2: Data Layer (Day 1-2)**
1. Tạo `ReviewDataSource` (API calls)
2. Tạo `ReviewRepository` (business logic)
3. Setup error handling

### **PHASE 3: State Management (Day 2)**
1. Tạo Riverpod providers (review_provider.dart)
2. Setup FutureProvider cho data fetching
3. Setup StateProvider cho form state

### **PHASE 4: UI Components (Day 2-3)**
1. Tạo `StarRatingBar` widget (reusable)
2. Tạo `ReviewFormWidget`
3. Tạo `ReviewCardWidget`
4. Tạo `ReviewDialog` (quick entry)

### **PHASE 5: Integration & Testing (Day 3)**
1. Integrate vào booking detail screen
2. Show dialog on booking completion
3. Test API integration
4. Handle edge cases (already reviewed, etc)

---

## 📝 CODING STANDARDS

- ✅ Follow Flutter best practices
- ✅ Use Riverpod recommended patterns
- ✅ Immutable models with `@immutable` or freezed
- ✅ Error handling: Try-catch + custom exceptions
- ✅ Loading states: AsyncValue (AsyncLoading, AsyncData, AsyncError)
- ✅ Color constants từ `AppColors`
- ✅ Reuse Material 3 theme styles

---

## 🎯 SUCCESS CRITERIA

- ✅ User can submit review after booking completed
- ✅ Review persisted to backend
- ✅ Reviews displayed correctly
- ✅ Proper error handling & loading states
- ✅ UI matches color scheme & design
- ✅ All validations working

---

**Ready to implement! Let's start with PHASE 1.** 🚀
