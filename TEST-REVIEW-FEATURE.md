# 📝 Hướng dẫn Test Tính năng Review & Rating

## ✅ Điều kiện tiên quyết
- ✅ Backend chạy trên `http://localhost:3000`
- ✅ Frontend Flutter chạy trên emulator/device
- ✅ Review API endpoints đã được tạo
- ✅ Database đã được seed với test data

---

## 📋 Thông tin Test Data

### Test User 1 - Reviewer (Customer)
```
Email: reviewer@test.com
Name: Test Reviewer
Role: customer
User ID: (sẽ được hiển thị khi login)
```

### Test User 2 - Provider
```
Email: provider@test.com
Name: Test Provider
Role: provider
User ID: (sẽ được hiển thị khi login)
```

### Test Booking
- **Status**: `completed` (quan trọng - chỉ có thể review bookings đã hoàn thành)
- **Created by**: Test Reviewer user
- **Service provided by**: Test Provider user
- **Created**: 7 ngày trước

---

## 🚀 Các bước test

### **BƯỚC 1: Seed Test Data vào Database**

1. Kết nối PostgreSQL:
```bash
psql -U postgres -d local_service_platform_dev -h localhost
```

2. Chạy SQL seed script:
```sql
-- Copy nội dung từ: apps/backend/prisma/seed-review-test-data.sql
-- Sau đó paste vào psql terminal
```

3. Verify data được tạo:
```sql
SELECT * FROM users WHERE email IN ('reviewer@test.com', 'provider@test.com');
SELECT * FROM bookings WHERE status = 'completed';
```

---

### **BƯỚC 2: Test Review Submission Flow**

#### 2.1 Login with Test Reviewer
1. Mở app Flutter
2. Go to Login screen
3. Đăng nhập:
   - Email: `reviewer@test.com`
   - Password: (dùng password đã set cho test user)
4. Login thành công

#### 2.2 Điều hướng đến Booking Detail
1. Go to "My Bookings" hoặc "Booking History"
2. Tìm booking với status "Completed" (test booking vừa tạo)
3. Nhấn vào booking để mở Booking Detail Screen

#### 2.3 Submit Review
1. Trên Booking Detail Screen, tìm nút "Leave Review" hoặc "Share Feedback"
2. Nhấn nút → Mở ReviewDialog hoặc ReviewFormWidget
3. **Fill form:**
   - **Rating**: Chọn 4-5 stars
   - **Title**: "Excellent service!" (yêu cầu, max 100 chars)
   - **Comment**: "Very professional and on time. Highly recommended!" (tùy chọn, max 500 chars)
4. Nhấn "Submit Review"

#### 2.4 Verify Success
- ✅ Toast notification: "Review submitted successfully!"
- ✅ Dialog đóng tự động
- ✅ Form reset

#### 2.5 Verify Backend API
1. Mở Swagger API docs: `http://localhost:3000/api`
2. Tìm `POST /api/reviews/bookings/{bookingId}`
3. Check response:
```json
{
  "id": 1,
  "bookingId": <booking-id>,
  "reviewerId": <reviewer-id>,
  "revieweeId": <provider-id>,
  "rating": 4,
  "title": "Excellent service!",
  "comment": "Very professional and on time...",
  "createdAt": "2025-12-11T10:30:00Z"
}
```

---

### **BƯỚC 3: Test Duplicate Review Prevention**

1. **Quay lại Booking Detail Screen** (cùng booking)
2. Nhấn "Leave Review" lần thứ 2
3. Thử submit review khác
4. **Expected Error**: "You have already reviewed this booking" hoặc tương tự
5. ✅ Hệ thống không cho phép submit

---

### **BƯỚC 4: Test Review Display**

#### 4.1 View Review on Booking Detail
1. Trên Booking Detail Screen
2. Scroll down để xem section "Reviews"
3. Verify review vừa tạo hiển thị:
   - Rating: 4 stars (filled)
   - Title: "Excellent service!"
   - Comment: (nếu có)
   - Date: "Today" hoặc "Just now"

#### 4.2 View Reviews on Provider Profile
1. Go to Provider Profile screen (của Test Provider)
2. Look for "Rating & Reviews" section
3. Verify:
   - ✅ Average rating: 4.0
   - ✅ Total reviews: 1
   - ✅ Rating distribution (1★: 0, 2★: 0, 3★: 0, 4★: 1, 5★: 0)
   - ✅ List reviews với review vừa submit

---

### **BƯỚC 5: Test Statistics API**

1. Mở Swagger: `http://localhost:3000/api`
2. Test `GET /api/reviews/users/{userId}/statistics`
3. Set `userId` = Test Provider ID
4. Expected response:
```json
{
  "averageRating": 4,
  "totalReviews": 1,
  "ratingDistribution": {
    "1": 0,
    "2": 0,
    "3": 0,
    "4": 1,
    "5": 0
  }
}
```

---

### **BƯỚC 6: Test Star Rating Input**

1. Mở ReviewFormWidget
2. Test các rating levels:
   - Hover/tap trên từng star
   - Check animate scale effect (1.0 → 1.1)
   - Click star:
     - Khi click 1 star → text "Poor - Needs improvement"
     - Khi click 2 stars → text "Fair - Could be better"
     - Khi click 3 stars → text "Good - Satisfied"
     - Khi click 4 stars → text "Very Good - Impressed"
     - Khi click 5 stars → text "Excellent - Highly recommended"
3. ✅ Tất cả rating descriptions display chính xác

---

## 🐛 Debugging Tips

### Problem: "Can only review completed bookings"
- **Solution**: Booking status phải là "completed"
- Check: `SELECT status FROM bookings WHERE id = <booking-id>;`

### Problem: "Cannot review yourself"
- **Solution**: `revieweeId` (provider) không được bằng `reviewerId` (reviewer)

### Problem: Form không gửi được
- **Check**:
  1. Rating > 0 (bắt buộc)
  2. Title không trống (bắt buộc)
  3. Comment max 500 chars (nếu có)
  4. Internet connection OK

### Problem: API 404 error
- Verify endpoint: `http://localhost:3000/api/reviews/bookings/{bookingId}`
- Check bookingId là number không phải string

### Problem: Rating distribution sai
- SQL check:
```sql
SELECT rating, COUNT(*) FROM reviews 
WHERE reviewee_id = <provider-id> 
GROUP BY rating;
```

---

## 📊 Test Checklist

### Review Submission ✅
- [ ] Form displays correctly
- [ ] All fields validate properly
- [ ] Star rating works with animation
- [ ] Submit button enabled only when valid
- [ ] Success toast appears
- [ ] Form resets after submit
- [ ] API response 201 Created

### Duplicate Prevention ✅
- [ ] Cannot submit 2nd review for same booking
- [ ] Error message displays
- [ ] Database has only 1 review per booking

### Review Display ✅
- [ ] Reviews show on Booking Detail
- [ ] Reviews show on Provider Profile
- [ ] Star display renders correctly
- [ ] Reviewer name/date shows
- [ ] Comment truncates at 5 lines

### Statistics ✅
- [ ] Average rating calculates correctly
- [ ] Total count accurate
- [ ] Distribution counts match reviews

### Validation ✅
- [ ] Title required
- [ ] Rating required (1-5)
- [ ] Comment optional, max 500 chars
- [ ] Title max 100 chars
- [ ] Cannot submit empty form

---

## 🔗 API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/reviews/bookings/{bookingId}` | Create review |
| GET | `/api/reviews/bookings/{id}` | Get reviews for booking |
| GET | `/api/reviews/users/{id}/received` | Get reviews as provider |
| GET | `/api/reviews/users/{id}/given` | Get reviews as customer |
| GET | `/api/reviews/users/{id}/statistics` | Get rating stats |
| GET | `/api/reviews/bookings/{id}/user/{uid}/has-reviewed` | Check if reviewed |
| DELETE | `/api/reviews/{id}` | Delete review |

---

## 💡 Notes

- Review chỉ có thể submit sau khi booking completed
- Mỗi booking chỉ được review 1 lần (1 reviewer)
- Rating: 1-5 stars
- Title: Bắt buộc, max 255 chars
- Comment: Tùy chọn, max 5000 chars
- Reviews sorted by date (mới nhất trước)

