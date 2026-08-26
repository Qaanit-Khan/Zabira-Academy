import 'package:flutter_test/flutter_test.dart';
import 'package:zabira_academy/features/store/data/models/store_category_model.dart';
import 'package:zabira_academy/features/store/data/models/store_product_model.dart';
import 'package:zabira_academy/features/courses/data/models/course_api_model.dart';
import 'package:zabira_academy/features/courses/data/models/course_category_api_model.dart';

void main() {
  group('Store Models Test', () {
    test('StoreCategoryModel parses JSON correctly', () {
      final json = {
        'id': 5,
        'name': 'Stationery',
        'slug': 'stationery',
        'image': '/uploads/stationery.png',
        'product_count': 12,
        'status': 'active',
      };
      final cat = StoreCategoryModel.fromJson(json);
      expect(cat.id, 5);
      expect(cat.name, 'Stationery');
      expect(cat.slug, 'stationery');
      expect(cat.fullImageUrl, 'https://api.zabiraacademy.com/uploads/stationery.png');
    });

    test('StoreProductModel parses pricing and discounts correctly', () {
      final json = {
        'id': 6,
        'name': 'Zabira Academy Premium Black Pen',
        'slug': 'zabira-academy-premium-black-pen',
        'price': '69.00',
        'sale_price': '1.50',
        'stock': 3,
        'sku': 'ZA-PEN-001',
        'thumbnail': 'https://api.zabiraacademy.com/uploads/pen.png',
        'category_name': 'Stationery',
        'is_featured': 1,
        'is_new': 1,
      };
      final prod = StoreProductModel.fromJson(json);
      expect(prod.id, 6);
      expect(prod.name, 'Zabira Academy Premium Black Pen');
      expect(prod.formattedPrice, '₹1.50');
      expect(prod.formattedOriginalPrice, '₹69');
      expect(prod.hasDiscount, true);
      expect(prod.inStock, true);
      expect(prod.isNew, true);
      expect(prod.fullThumbnailUrl, 'https://api.zabiraacademy.com/uploads/pen.png');
    });
  });

  group('Courses Models Test', () {
    test('CourseCategoryApiModel parses JSON correctly', () {
      final json = {
        'id': 1,
        'name': 'Quran Studies',
        'slug': 'quran-studies',
        'icon': '',
        'sort_order': 1,
        'status': 'active',
      };
      final cat = CourseCategoryApiModel.fromJson(json);
      expect(cat.id, 1);
      expect(cat.name, 'Quran Studies');
    });

    test('CourseApiModel parses real API JSON structure with payment plans', () {
      final json = {
        'id': 5,
        'title': 'Quran with Tajweed',
        'slug': 'quran-with-tajweed',
        'price': 1500,
        'discount_price': 999,
        'duration': '6 months',
        'level': 'Beginner',
        'total_lessons': 98,
        'rating': 4.8,
        'review_count': 320,
        'is_popular': 1,
        'thumbnail': '/uploads/courses/quran.webp',
        'category_name': 'Quran Studies',
        'payment_plans': {
          'currency': 'INR',
          'options': [
            {
              'plan_type': 'full',
              'label': 'Pay in Full',
              'final': 999,
            },
            {
              'plan_type': 'monthly',
              'label': 'Pay Monthly',
              'final': 1500,
              'installment_amount': 249,
              'installment_count': 6,
            }
          ]
        }
      };
      final course = CourseApiModel.fromJson(json);
      expect(course.id, 5);
      expect(course.title, 'Quran with Tajweed');
      expect(course.formattedPrice, '₹999');
      expect(course.formattedOriginalPrice, '₹1500');
      expect(course.monthlyInstallmentText, 'Starting from ₹249/month EMI');
      expect(course.lessonsDisplay, '98 Lessons');
      expect(course.ratingDisplay, '4.8 (320)');
      expect(course.fullThumbnailUrl, 'https://api.zabiraacademy.com/uploads/courses/quran.webp');
    });
  });
}
