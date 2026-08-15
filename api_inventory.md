# Zabira Academy API Inventory (134 operations across 123 endpoints)

## Tag: Authentication (7)
- **POST** `/auth/forgot_password.php` `[PUBLIC]`: Auth: Forgot Password
  - *Body Schema*: {"type":"object","properties":{"email":{"type":"string","format":"email","example":"student@example.com"}},"required":[]}
- **POST** `/auth/google_auth.php` `[PUBLIC]`: Auth: Google Auth
  - *Body Schema*: {"type":"object","properties":{"id_token":{"type":"integer","example":1},"credential":{"type":"string","example":"credential"}},"required":[]}
- **POST** `/auth/login.php` `[PUBLIC]`: Auth: Login
  - *Body Schema*: {"type":"object","properties":{"email":{"type":"string","format":"email","example":"student@example.com"},"password":{"type":"string","format":"password","example":"********"},"portal":{"type":"string","example":"student","description":"Login portal. Use `student` for website and mobile apps."}},"required":["email","password","portal"]}
- **POST** `/auth/refresh.php` `[AUTH]`: Auth: Refresh
- **POST** `/auth/register.php` `[PUBLIC]`: Auth: Register
  - *Body Schema*: {"type":"object","properties":{"full_name":{"type":"string","example":"full_name"},"fullName":{"type":"string","example":"fullName"},"email":{"type":"string","format":"email","example":"student@example.com"},"mobile":{"type":"string","example":"mobile"},"phone":{"type":"string","example":"phone"},"contact_number":{"type":"string","example":"contact_number"},"gender":{"type":"string","example":"gender"},"date_of_birth":{"type":"string","example":"date_of_birth"},"dateOfBirth":{"type":"string","example":"dateOfBirth"},"country":{"type":"string","example":"country"},"state":{"type":"string","example":"state"},"city":{"type":"string","example":"city"},"password":{"type":"string","format":"password","example":"********"},"accept_terms":{"type":"string","example":"accept_terms"},"acceptTerms":{"type":"string","example":"acceptTerms"}},"required":["country","state","city"]}
- **POST** `/auth/reset_password.php` `[PUBLIC]`: Auth: Reset Password
  - *Body Schema*: {"type":"object","properties":{"password":{"type":"string","format":"password","example":"********"}},"required":[]}
- **POST** `/auth/validate_reset_token.php` `[PUBLIC]`: Auth: Validate Reset Token

## Tag: Books (5)
- **GET** `/library/my_books.php` `[AUTH]`: Library: My Books
- **GET** `/library/pdf.php` `[AUTH]`: Library: Pdf
  - *Params*: book_id (query, req), mode (query)
- **POST** `/library/purchase.php` `[AUTH]`: Library: Purchase
  - *Body Schema*: {"type":"object","properties":{"book_id":{"type":"integer","example":1},"format":{"type":"string","example":"format"}},"required":[]}
- **GET** `/library/purchase_status.php` `[AUTH]`: Library: Purchase Status
  - *Params*: book_id (query), format (query)
- **POST** `/library/save_shipping.php` `[AUTH]`: Library: Save Shipping
  - *Body Schema*: {"type":"object","properties":{"order_id":{"type":"integer","example":1}},"required":["order_id"]}

## Tag: Cart (8)
- **POST** `/cart/add.php` `[AUTH]`: Cart: Add
  - *Body Schema*: {"type":"object","properties":{"store_product_id":{"type":"integer","example":1},"product_id":{"type":"integer","example":1},"product_type":{"type":"string","example":"product_type"},"store_variant_id":{"type":"integer","example":1},"variant_id":{"type":"integer","example":1},"quantity":{"type":"string","example":"quantity"},"book_id":{"type":"integer","example":1},"format":{"type":"string","example":"format"},"book_format":{"type":"string","example":"book_format"},"course_id":{"type":"integer","example":1},"payment_plan":{"type":"string","example":"payment_plan"},"plan_type":{"type":"string","example":"plan_type"}},"required":["store_product_id","product_id","book_id","format"]}
- **POST** `/cart/checkout.php` `[AUTH]`: Cart: Checkout
- **DELETE** `/cart/clear.php` `[AUTH]`: Cart: Clear
- **GET** `/cart/count.php` `[AUTH]`: Cart: Count
- **GET** `/cart/list.php` `[AUTH]`: Cart: List
- **POST** `/cart/move_to_wishlist.php` `[AUTH]`: Cart: Move To Wishlist
  - *Body Schema*: {"type":"object","properties":{"course_id":{"type":"integer","example":1}},"required":["course_id"]}
- **DELETE** `/cart/remove.php` `[AUTH]`: Cart: Remove
  - *Params*: cart_id (query), book_id (query), format (query, req), book_format (query), course_id (query)
- **GET** `/cart/status.php` `[AUTH]`: Cart: Status
  - *Params*: book_id (query, req), format (query, req), book_format (query), course_id (query)

## Tag: Certificates (3)
- **GET** `/certificates/verify.php` `[PUBLIC]`: Certificates: Verify
  - *Params*: code (query)
- **GET** `/student/certificate_pdf.php` `[AUTH]`: Student: Certificate Pdf
  - *Params*: code (query), id (query, req)
- **GET** `/student/certificates.php` `[AUTH]`: Student: Certificates

## Tag: Courses (12)
- **GET** `/categories/list.php` `[PUBLIC]`: Categories: List
- **GET** `/courses/preview_media.php` `[PUBLIC]`: Courses: Preview Media
  - *Params*: lesson_id (query)
- **GET** `/courses/public_details.php` `[AUTH]`: Courses: Public Details
  - *Params*: slug (query), id (query, req)
- **GET** `/courses/public_list.php` `[PUBLIC]`: Courses: Public List
  - *Params*: page (query), limit (query), search (query), category_id (query), level (query), language (query), price (query), sort (query)
- **POST** `/enrollment/enroll.php` `[AUTH]`: Enrollment: Enroll
  - *Body Schema*: {"type":"object","properties":{"course_id":{"type":"integer","example":1},"payment_plan":{"type":"string","example":"payment_plan"},"plan_type":{"type":"string","example":"plan_type"},"email":{"type":"string","format":"email","example":"student@example.com"}},"required":["course_id"]}
- **GET** `/enrollment/my_courses.php` `[AUTH]`: Enrollment: My Courses
- **GET** `/enrollment/wishlist.php` `[AUTH]`: Enrollment: Wishlist
  - *Params*: course_id (query, req)
- **POST** `/enrollment/wishlist.php` `[AUTH]`: Enrollment: Wishlist
  - *Body Schema*: {"type":"object","properties":{"course_id":{"type":"integer","example":1}},"required":["course_id"]}
- **DELETE** `/enrollment/wishlist.php` `[AUTH]`: Enrollment: Wishlist
  - *Params*: course_id (query, req)
- **POST** `/quiz/submit.php` `[AUTH]`: Quiz: Submit
  - *Body Schema*: {"type":"object","properties":{"lesson_id":{"type":"integer","example":1},"course_id":{"type":"integer","example":1},"answers":{"type":"string","example":"answers"}},"required":[]}
- **GET** `/reviews/list.php` `[PUBLIC]`: Reviews: List
  - *Params*: course_id (query, req), slug (query, req)
- **POST** `/reviews/list.php` `[AUTH]`: Reviews: List
  - *Body Schema*: {"type":"object","properties":{"course_id":{"type":"integer","example":1},"rating":{"type":"number","example":0},"review_text":{"type":"string","example":"review_text"},"id":{"type":"integer","example":1},"status":{"type":"string","example":"status"}},"required":["course_id","id"]}

## Tag: Events (6)
- **GET** `/events/featured.php` `[PUBLIC]`: Events: Featured
- **GET** `/events/my_registrations.php` `[AUTH]`: Events: My Registrations
- **GET** `/events/public_details.php` `[PUBLIC]`: Events: Public Details
  - *Params*: slug (query), id (query, req)
- **GET** `/events/public_list.php` `[PUBLIC]`: Events: Public List
  - *Params*: page (query), limit (query), search (query), category (query), event_type (query), filter (query), price (query)
- **POST** `/events/register.php` `[AUTH]`: Events: Register
  - *Body Schema*: {"type":"object","properties":{"website":{"type":"string","example":"website"},"event_id":{"type":"integer","example":1},"student_name":{"type":"string","example":"student_name"},"parent_name":{"type":"string","example":"parent_name"},"school_name":{"type":"string","example":"school_name"},"grade":{"type":"string","example":"grade"},"mobile":{"type":"string","example":"mobile"},"whatsapp":{"type":"string","example":"whatsapp"},"email":{"type":"string","format":"email","example":"student@example.com"},"city":{"type":"string","example":"city"}},"required":["email","city"]}
- **GET** `/events/registration_status.php` `[AUTH]`: Events: Registration Status
  - *Params*: event_id (query, req)

## Tag: Games (4)
- **POST** `/kids/game_play.php` `[PUBLIC]`: Kids: Game Play
  - *Body Schema*: {"type":"object","properties":{"game_id":{"type":"integer","example":1}},"required":["game_id"]}
- **POST** `/kids/game_result.php` `[PUBLIC]`: Kids: Game Result
  - *Body Schema*: {"type":"object","properties":{"attempt_token":{"type":"string","example":"attempt_token"},"score":{"type":"string","example":"score"},"max_score":{"type":"string","example":"max_score"},"time_taken_seconds":{"type":"string","example":"time_taken_seconds"},"result":{"type":"string","example":"result"}},"required":["attempt_token","time_taken_seconds"]}
- **GET** `/kids/public_game.php` `[PUBLIC]`: Kids: Public Game
  - *Params*: slug (query, req), id (query)
- **GET** `/kids/public_games.php` `[PUBLIC]`: Kids: Public Games
  - *Params*: page (query), limit (query), search (query), q (query), category (query), age (query), age_group (query), difficulty (query), featured (query), game_type (query)

## Tag: Kids (1)
- **GET** `/kids/public_categories.php` `[PUBLIC]`: Kids: Public Categories

## Tag: Library (5)
- **GET** `/library/public_categories.php` `[PUBLIC]`: Library: Public Categories
- **GET** `/library/public_collections.php` `[PUBLIC]`: Library: Public Collections
- **GET** `/library/public_details.php` `[PUBLIC]`: Library: Public Details
  - *Params*: id (query), slug (query)
- **GET** `/library/public_list.php` `[PUBLIC]`: Library: Public List
  - *Params*: page (query), limit (query), search (query), category_id (query), category (query), sort (query), dir (query)
- **GET** `/library/public_stats.php` `[PUBLIC]`: Library: Public Stats

## Tag: Notifications (3)
- **GET** `/student/notifications.php` `[AUTH]`: Student: Notifications
- **POST** `/student/notifications.php` `[AUTH]`: Student: Notifications
  - *Body Schema*: {"type":"object","properties":{"mark_all":{"type":"string","example":"mark_all"},"id":{"type":"integer","example":1}},"required":["id"]}
- **PATCH** `/student/notifications.php` `[AUTH]`: Student: Notifications
  - *Body Schema*: {"type":"object","properties":{"mark_all":{"type":"string","example":"mark_all"},"id":{"type":"integer","example":1}},"required":["id"]}

## Tag: Orders (6)
- **GET** `/oms/public_track.php` `[PUBLIC]`: Oms: Public Track
  - *Params*: commerce_order_number (query), order (query)
- **GET** `/oms/tracking_url.php` `[AUTH]`: Oms: Tracking Url
  - *Params*: module_type (query), order_id (query), commerce_order_number (query)
- **POST** `/payments/cancel_order.php` `[AUTH]`: Payments: Cancel Order
  - *Body Schema*: {"type":"object","properties":{"order_id":{"type":"integer","example":1},"action":{"type":"string","example":"action"}},"required":["order_id"]}
- **GET** `/payments/invoice.php` `[AUTH]`: Payments: Invoice
  - *Params*: type (query), invoice_number (query), receipt_number (query), order_id (query, req), format (query), print (query)
- **GET** `/payments/my_orders.php` `[AUTH]`: Payments: My Orders
  - *Params*: page (query), limit (query)
- **GET** `/payments/order_status.php` `[AUTH]`: Payments: Order Status
  - *Params*: order_id (query, req), product_type (query), verify (query)

## Tag: Payments (9)
- **POST** `/payments/apply_coupon.php` `[AUTH]`: Payments: Apply Coupon
  - *Body Schema*: {"type":"object","properties":{"order_id":{"type":"integer","example":1},"coupon_code":{"type":"string","example":"coupon_code"},"remove":{"type":"string","example":"remove"}},"required":["order_id","coupon_code"]}
- **GET** `/payments/checkout_summary.php` `[AUTH]`: Payments: Checkout Summary
  - *Params*: order_id (query, req), product_type (query)
- **GET** `/payments/config_status.php` `[PUBLIC]`: Payments: Config Status
- **POST** `/payments/create_session.php` `[AUTH]`: Payments: Create Session
  - *Body Schema*: {"type":"object","properties":{"order_id":{"type":"integer","example":1},"gateway":{"type":"string","example":"gateway"},"product_type":{"type":"string","example":"product_type"}},"required":["order_id"]}
- **GET** `/payments/gateways.php` `[PUBLIC]`: Payments: Gateways
- **GET** `/payments/my_schedules.php` `[AUTH]`: Payments: My Schedules
- **POST** `/payments/my_schedules.php` `[AUTH]`: Payments: My Schedules
  - *Body Schema*: {"type":"object","properties":{"action":{"type":"string","example":"action"},"installment_id":{"type":"integer","example":1}},"required":["installment_id"]}
- **GET** `/payments/payment_plans.php` `[PUBLIC]`: Payments: Payment Plans
  - *Params*: course_id (query), slug (query, req)
- **POST** `/payments/verify.php` `[AUTH]`: Payments: Verify
  - *Body Schema*: {"type":"object","properties":{"order_id":{"type":"integer","example":1},"gateway_order_id":{"type":"integer","example":1},"product_type":{"type":"string","example":"product_type"},"razorpay_payment_id":{"type":"integer","example":1},"razorpay_signature":{"type":"string","example":"razorpay_signature"},"razorpay_order_id":{"type":"integer","example":1}},"required":[]}

## Tag: Profile (7)
- **GET** `/auth/profile.php` `[AUTH]`: Auth: Profile
- **DELETE** `/student/avatar.php` `[AUTH]`: Student: Avatar
- **POST** `/student/change_password.php` `[AUTH]`: Student: Change Password
  - *Body Schema*: {"type":"object","properties":{"current_password":{"type":"string","format":"password","example":"********"},"new_password":{"type":"string","format":"password","example":"********"}},"required":[]}
- **POST** `/student/complete_profile.php` `[AUTH]`: Student: Complete Profile
  - *Body Schema*: {"type":"object","properties":{"mobile":{"type":"string","example":"mobile"},"phone":{"type":"string","example":"phone"},"gender":{"type":"string","example":"gender"},"date_of_birth":{"type":"string","example":"date_of_birth"},"country":{"type":"string","example":"country"},"state":{"type":"string","example":"state"},"city":{"type":"string","example":"city"},"address":{"type":"string","example":"address"}},"required":[]}
- **GET** `/student/profile.php` `[AUTH]`: Student: Profile
- **POST** `/student/profile.php` `[AUTH]`: Student: Profile
  - *Body Schema*: {"type":"object","properties":{"email":{"type":"string","format":"email","example":"student@example.com"},"phone":{"type":"string","example":"phone"},"mobile":{"type":"string","example":"mobile"},"whatsapp":{"type":"string","example":"whatsapp"},"student_id":{"type":"integer","example":1},"registration_date":{"type":"string","example":"registration_date"},"user_id":{"type":"integer","example":1},"username":{"type":"string","example":"username"},"photo_path":{"type":"string","example":"photo_path"}},"required":[]}
- **PUT** `/student/profile.php` `[AUTH]`: Student: Profile
  - *Body Schema*: {"type":"object","properties":{"email":{"type":"string","format":"email","example":"student@example.com"},"phone":{"type":"string","example":"phone"},"mobile":{"type":"string","example":"mobile"},"whatsapp":{"type":"string","example":"whatsapp"},"student_id":{"type":"integer","example":1},"registration_date":{"type":"string","example":"registration_date"},"user_id":{"type":"integer","example":1},"username":{"type":"string","example":"username"},"photo_path":{"type":"string","example":"photo_path"}},"required":[]}

## Tag: Public Content (20)
- **GET** `/announcements/active.php` `[PUBLIC]`: public. Returns the current site-wide banner, if any.
- **POST** `/contact/submit.php` `[PUBLIC]`: Contact: Submit
  - *Body Schema*: {"type":"object","properties":{"name":{"type":"string","example":"name"},"email":{"type":"string","format":"email","example":"student@example.com"},"phone":{"type":"string","example":"phone"},"subject":{"type":"string","example":"subject"},"message":{"type":"string","example":"message"}},"required":["email"]}
- **GET** `/gallery/hall-of-fame/list.php` `[PUBLIC]`: Gallery: List
  - *Params*: section (query)
- **GET** `/gallery/public_album.php` `[PUBLIC]`: Gallery: Public Album
  - *Params*: slug (query, req), page (query), limit (query)
- **GET** `/gallery/public_albums.php` `[PUBLIC]`: Gallery: Public Albums
  - *Params*: album_type (query), type (query), page (query), limit (query), year (query), city (query), school (query), q (query)
- **GET** `/gallery/public_featured.php` `[PUBLIC]`: Gallery: Public Featured
  - *Params*: limit (query)
- **GET** `/gallery/public_list.php` `[PUBLIC]`: Gallery: Public List
  - *Params*: page (query), limit (query), section (query), year (query), city (query), category (query), school (query), q (query), featured (query), sort (query)
- **GET** `/gallery/public_settings.php` `[PUBLIC]`: Gallery: Public Settings
- **GET** `/gallery/student-showcase/list.php` `[PUBLIC]`: Gallery: List
  - *Params*: section (query)
- **GET** `/homepage_insights/public.php` `[PUBLIC]`: Homepage Insights: Public
- **GET** `/media/public_categories.php` `[PUBLIC]`: Media: Public Categories
- **GET** `/media/public_details.php` `[PUBLIC]`: Media: Public Details
- **GET** `/media/public_list.php` `[PUBLIC]`: Media: Public List
- **GET** `/media/stream.php` `[AUTH]`: Media: Stream
  - *Params*: ticket (query), lesson_id (query, req), access_token (query)
- **POST** `/media/ticket.php` `[AUTH]`: Media: Ticket
  - *Body Schema*: {"type":"object","properties":{"lesson_id":{"type":"integer","example":1}},"required":["lesson_id"]}
- **GET** `/nasheed/download.php` `[PUBLIC]`: Nasheed: Download
  - *Params*: slug (query), id (query, req)
- **GET** `/nasheed/public_categories.php` `[PUBLIC]`: Nasheed: Public Categories
- **GET** `/nasheed/public_details.php` `[PUBLIC]`: Nasheed: Public Details
- **GET** `/nasheed/public_list.php` `[PUBLIC]`: Nasheed: Public List
- **GET** `/settings/seo_global.php` `[PUBLIC]`: Settings: Seo Global

## Tag: Quizzes (4)
- **GET** `/kids/public_quiz.php` `[PUBLIC]`: Kids: Public Quiz
  - *Params*: slug (query, req), id (query)
- **GET** `/kids/public_quizzes.php` `[PUBLIC]`: Kids: Public Quizzes
  - *Params*: page (query), limit (query), search (query), q (query), category (query), age (query), age_group (query), difficulty (query), featured (query)
- **POST** `/kids/quiz_start.php` `[PUBLIC]`: Kids: Quiz Start
  - *Body Schema*: {"type":"object","properties":{"quiz_id":{"type":"integer","example":1}},"required":["quiz_id"]}
- **POST** `/kids/quiz_submit.php` `[PUBLIC]`: Kids: Quiz Submit
  - *Body Schema*: {"type":"object","properties":{"attempt_token":{"type":"string","example":"attempt_token"},"answers":{"type":"string","example":"answers"}},"required":[]}

## Tag: Scholarships (10)
- **POST** `/scholarship/apply.php` `[AUTH]`: Scholarship: Apply
  - *Body Schema*: {"type":"object","properties":{"website":{"type":"string","example":"website"},"company_url":{"type":"string","example":"company_url"},"email":{"type":"string","format":"email","example":"student@example.com"},"student_name":{"type":"string","example":"student_name"},"phone":{"type":"string","example":"phone"},"course_requested":{"type":"string","example":"course_requested"}},"required":[]}
- **POST** `/scholarship/donate_create.php` `[AUTH]`: Scholarship: Donate Create
  - *Body Schema*: {"type":"object","properties":{"website":{"type":"string","example":"website"}},"required":[]}
- **GET** `/scholarship/donate_receipt.php` `[PUBLIC]`: Scholarship: Donate Receipt
  - *Params*: donation_id (query), access_token (query)
- **POST** `/scholarship/donate_verify.php` `[PUBLIC]`: Scholarship: Donate Verify
  - *Body Schema*: {"type":"object","properties":{"donation_id":{"type":"integer","example":1},"access_token":{"type":"string","example":"access_token"}},"required":["donation_id"]}
- **GET** `/scholarship/public_content.php` `[PUBLIC]`: Scholarship: Public Content
  - *Params*: section (query)
- **GET** `/scholarship/public_reports.php` `[PUBLIC]`: Scholarship: Public Reports
  - *Params*: type (query)
- **GET** `/scholarship/public_stats.php` `[PUBLIC]`: Scholarship: Public Stats
- **GET** `/scholarship/sponsor_dashboard.php` `[AUTH]`: Scholarship: Sponsor Dashboard
- **POST** `/scholarship/sponsor_dashboard.php` `[AUTH]`: Scholarship: Sponsor Dashboard
  - *Body Schema*: {"type":"object","properties":{"donation_id":{"type":"integer","example":1}},"required":["donation_id"]}
- **POST** `/scholarship/upload_document.php` `[PUBLIC]`: Scholarship: Upload Document
  - *Body Schema*: {"type":"object","properties":{"captcha_token":{"type":"string","example":"captcha_token"},"cf-turnstile-response":{"type":"string","example":"cf-turnstile-response"}},"required":[]}

## Tag: Search (1)
- **GET** `/settings/seo_resolve.php` `[PUBLIC]`: Settings: Seo Resolve
  - *Params*: key (query)

## Tag: Store (7)
- **GET** `/store/download.php` `[AUTH]`: Store: Download
  - *Params*: product_id (query, req), id (query, req)
- **GET** `/store/public_categories.php` `[PUBLIC]`: Store: Public Categories
- **GET** `/store/public_collections.php` `[PUBLIC]`: Store: Public Collections
  - *Params*: page (query), limit (query), featured (query)
- **GET** `/store/public_details.php` `[PUBLIC]`: Store: Public Details
  - *Params*: id (query), slug (query)
- **GET** `/store/public_list.php` `[PUBLIC]`: Store: Public List
  - *Params*: page (query), limit (query), search (query), category_id (query), category (query), featured (query), bestseller (query), new (query), collection_id (query), sort (query), dir (query)
- **POST** `/store/purchase.php` `[AUTH]`: Store: Purchase
  - *Body Schema*: {"type":"object","properties":{"store_product_id":{"type":"integer","example":1},"product_id":{"type":"integer","example":1},"store_variant_id":{"type":"integer","example":1},"variant_id":{"type":"integer","example":1},"quantity":{"type":"string","example":"quantity"}},"required":["product_id"]}
- **GET** `/store/purchase_status.php` `[AUTH]`: Store: Purchase Status
  - *Params*: product_id (query, req), store_product_id (query), variant_id (query), store_variant_id (query)

## Tag: Students (13)
- **POST** `/free-trial/attendance.php` `[AUTH]`: Free Trial: Attendance
  - *Body Schema*: {"type":"object","properties":{"id":{"type":"integer","example":1},"booking_id":{"type":"integer","example":1},"action":{"type":"string","example":"action"}},"required":["id"]}
- **POST** `/free-trial/book.php` `[AUTH]`: Free Trial: Book
  - *Body Schema*: {"type":"object","properties":{"website":{"type":"string","example":"website"},"company_url":{"type":"string","example":"company_url"},"course_id":{"type":"integer","example":1},"student_name":{"type":"string","example":"student_name"},"full_name":{"type":"string","example":"full_name"},"phone":{"type":"string","example":"phone"},"whatsapp":{"type":"string","example":"whatsapp"},"country":{"type":"string","example":"country"}},"required":[]}
- **POST** `/free-trial/join.php` `[AUTH]`: Free Trial: Join
  - *Body Schema*: {"type":"object","properties":{"id":{"type":"integer","example":1}},"required":["id"]}
- **GET** `/free-trial/my_trials.php` `[AUTH]`: Free Trial: My Trials
- **POST** `/free-trial/quick_enroll.php` `[AUTH]`: Free Trial: Quick Enroll
  - *Body Schema*: {"type":"object","properties":{"website":{"type":"string","example":"website"},"company_url":{"type":"string","example":"company_url"},"course_id":{"type":"integer","example":1}},"required":[]}
- **POST** `/free-trial/student_cancel.php` `[AUTH]`: Free Trial: Student Cancel
  - *Body Schema*: {"type":"object","properties":{"id":{"type":"integer","example":1},"reason":{"type":"string","example":"reason"}},"required":["id"]}
- **PUT** `/free-trial/student_cancel.php` `[AUTH]`: Free Trial: Student Cancel
  - *Body Schema*: {"type":"object","properties":{"id":{"type":"integer","example":1},"reason":{"type":"string","example":"reason"}},"required":["id"]}
- **GET** `/progress/course.php` `[AUTH]`: Progress: Course
  - *Params*: course_id (query, req)
- **POST** `/progress/update.php` `[AUTH]`: Progress: Update
  - *Body Schema*: {"type":"object","properties":{"lesson_id":{"type":"integer","example":1},"course_id":{"type":"integer","example":1},"status":{"type":"string","example":"status"},"progress_percent":{"type":"string","example":"progress_percent"},"watch_percent":{"type":"string","example":"watch_percent"},"last_position_seconds":{"type":"string","example":"last_position_seconds"},"page_reached":{"type":"integer","example":1},"total_pages":{"type":"string","example":"total_pages"},"time_spent_seconds":{"type":"string","example":"time_spent_seconds"}},"required":["progress_percent","watch_percent","last_position_seconds","page_reached","total_pages","time_spent_seconds"]}
- **GET** `/student/assignments.php` `[AUTH]`: Student: Assignments
  - *Params*: lesson_id (query, req)
- **POST** `/student/assignments.php` `[AUTH]`: Student: Assignments
  - *Body Schema*: {"type":"object","properties":{"lesson_id":{"type":"integer","example":1},"content":{"type":"string","example":"content"},"file_path":{"type":"string","example":"file_path"},"file_name":{"type":"string","example":"file_name"}},"required":["lesson_id"]}
- **GET** `/student/dashboard.php` `[AUTH]`: Student: Dashboard
- **GET** `/student/lesson.php` `[AUTH]`: Student: Lesson
  - *Params*: lesson_id (query, req)

## Tag: Wishlist (3)
- **GET** `/wishlist/count.php` `[AUTH]`: Wishlist: Count
- **GET** `/wishlist/status.php` `[AUTH]`: Wishlist: Status
  - *Params*: course_id (query, req)
- **POST** `/wishlist/toggle.php` `[AUTH]`: Wishlist: Toggle
  - *Body Schema*: {"type":"object","properties":{"course_id":{"type":"integer","example":1}},"required":["course_id"]}

