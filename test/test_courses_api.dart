import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Check all parameters of public_list.php', () async {
    final client = http.Client();

    // 1. Plain GET public_list.php
    final r1 = await client.get(Uri.parse('https://api.zabiraacademy.com/api/courses/public_list.php'));
    print('r1 (plain): Status ${r1.statusCode}');
    final d1 = jsonDecode(r1.body);
    final list1 = (d1['data']['courses'] ?? d1['data']) as List;
    print('r1 count: ${list1.length}');

    // 2. GET with page=1&limit=50
    final r2 = await client.get(Uri.parse('https://api.zabiraacademy.com/api/courses/public_list.php?page=1&limit=50'));
    print('r2 (limit=50): Status ${r2.statusCode}');
    final d2 = jsonDecode(r2.body);
    final list2 = (d2['data']['courses'] ?? d2['data']) as List;
    print('r2 count: ${list2.length}');

    // 3. GET with page=1&limit=50&sort=featured
    final r3 = await client.get(Uri.parse('https://api.zabiraacademy.com/api/courses/public_list.php?page=1&limit=50&sort=featured'));
    print('r3 (limit=50&sort=featured): Status ${r3.statusCode}');
    final d3 = jsonDecode(r3.body);
    final list3 = (d3['data']['courses'] ?? d3['data']) as List;
    print('r3 count: ${list3.length}');

    // 4. GET without .php (i.e. /courses/public_list)
    final r4 = await client.get(Uri.parse('https://api.zabiraacademy.com/api/courses/public_list'));
    print('r4 (/courses/public_list without .php): Status ${r4.statusCode}');
    if (r4.statusCode == 200) {
      final d4 = jsonDecode(r4.body);
      final list4 = (d4['data']['courses'] ?? d4['data']) as List;
      print('r4 count: ${list4.length}');
    }

    // 5. GET /courses/public_list?page=1&limit=50&sort=featured
    final r5 = await client.get(Uri.parse('https://api.zabiraacademy.com/api/courses/public_list?page=1&limit=50&sort=featured'));
    print('r5 (/courses/public_list?page=1&limit=50&sort=featured): Status ${r5.statusCode}');
    if (r5.statusCode == 200) {
      final d5 = jsonDecode(r5.body);
      final list5 = (d5['data']['courses'] ?? d5['data']) as List;
      print('r5 count: ${list5.length}');
    }

    for (int i = 0; i < list1.length; i++) {
      final c = list1[i];
      print('Course #$i: id=${c['id']}, title="${c['title']}", cat_id=${c['category_id']}, cat_name="${c['category_name']}"');
    }
  });
}
