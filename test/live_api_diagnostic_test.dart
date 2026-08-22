import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Live API Diagnosis for Courses, Dashboard, Enrollment, Payments', () async {
    final client = http.Client();

    // 1. Courses public list
    final coursesResp = await client.get(Uri.parse('https://api.zabiraacademy.com/api/courses/public_list.php?page=1&limit=50'));
    print('--- COURSES PUBLIC LIST (page=1, limit=50) ---');
    print('Status: ${coursesResp.statusCode}');
    try {
      final decoded = jsonDecode(coursesResp.body);
      final data = decoded['data'];
      final courses = data['courses'] as List;
      print('Total courses: ${courses.length}');
      for (final c in courses) {
        print('Course ID: ${c['id']} | Title: "${c['title']}" | Cat: "${c['category_name']}" (id: ${c['category_id']}) | Price: ${c['price']} | Discount: ${c['discount_price']}');
      }
    } catch (e) {
      print('Parse error: $e');
    }

    // 2. Categories
    final catResp = await client.get(Uri.parse('https://api.zabiraacademy.com/api/categories/list.php'));
    print('--- CATEGORIES ---');
    try {
      final decoded = jsonDecode(catResp.body);
      final cats = decoded['data']['categories'] as List;
      for (final cat in cats) {
        print('Category ID: ${cat['id']} | Name: "${cat['name']}" | Slug: "${cat['slug']}"');
      }
    } catch (e) {
      print('Cat error: $e');
    }

    // 3. Course Details for all 14 real course IDs
    for (final id in [5, 21, 11, 16, 17, 20, 19, 22, 18, 23, 24, 25, 26, 27]) {
      final detailResp = await client.get(Uri.parse('https://api.zabiraacademy.com/api/courses/public_details.php?id=$id'));
      if (detailResp.statusCode == 200) {
        final decoded = jsonDecode(detailResp.body);
        final course = decoded['data']?['course'];
        final curriculum = course?['curriculum'] ?? decoded['data']?['curriculum'] ?? [];
        final paymentPlans = decoded['data']?['payment_plans'] ?? course?['payment_plans'];
        print('Course ID: $id ("${course?['title']}") -> Curriculum sections: ${curriculum is List ? curriculum.length : 0} | Plans: ${paymentPlans != null}');
      } else {
        print('Course ID: $id -> Status ${detailResp.statusCode}');
      }
    }

    // 5. Test Register API validation
    final regResp = await client.post(
      Uri.parse('https://api.zabiraacademy.com/api/auth/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': 'Test',
        'last_name': 'User',
        'full_name': 'Test User',
        'email': 'testuser_${DateTime.now().millisecondsSinceEpoch}@example.com',
        'password': 'Password123!',
        'confirm_password': 'Password123!',
        'mobile': '9876543210',
        'phone': '9876543210',
        'gender': 'Male',
        'date_of_birth': '2000-01-01',
        'country': 'India',
        'state': 'Maharashtra',
        'city': 'Mumbai',
        'accept_terms': '1',
      }),
    );
    print('--- REGISTER RESPONSE --- Status: ${regResp.statusCode}');
    print('Body: ${regResp.body}');

    // 6. Test Google Auth endpoint
    final gAuthResp = await client.post(
      Uri.parse('https://api.zabiraacademy.com/api/auth/google_auth.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_token': 'dummy_test_token',
        'portal': 'student',
      }),
    );
    print('--- GOOGLE AUTH RESPONSE --- Status: ${gAuthResp.statusCode}');
    print('Body: ${gAuthResp.body}');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
