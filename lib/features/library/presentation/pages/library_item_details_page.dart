import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../../../features/store/presentation/controllers/cart_controller.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/library_item_model.dart';
import '../../data/services/library_api_service.dart';

class LibraryItemDetailsPage extends StatefulWidget {
  const LibraryItemDetailsPage({super.key, required this.itemId, this.initialItem});

  final int itemId;
  final LibraryItemModel? initialItem;

  @override
  State<LibraryItemDetailsPage> createState() => _LibraryItemDetailsPageState();
}

class _LibraryItemDetailsPageState extends State<LibraryItemDetailsPage> {
  final LibraryApiService _service = LibraryApiService();
  LibraryItemModel? _item;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedFormatIndex = 0;

  String _selectedFormat(LibraryItemModel item) {
    return (item.formats.isNotEmpty && _selectedFormatIndex < item.formats.length)
        ? item.formats[_selectedFormatIndex].format
        : 'pdf';
  }

  double _selectedPrice(LibraryItemModel item) {
    if (item.formats.isNotEmpty && _selectedFormatIndex < item.formats.length) {
      final format = item.formats[_selectedFormatIndex];
      return format.salePrice ?? format.price;
    }
    return item.salePrice ?? item.price;
  }

  @override
  void initState() {
    super.initState();
    _item = widget.initialItem;
    if (_item == null) {
      _fetchDetails();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final item = await _service.getLibraryDetails(id: widget.itemId);
      setState(() {
        _item = item;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load book details.';
      });
    }
  }

  Future<void> _launchUrl(String rawUrl) async {
    if (rawUrl.isEmpty) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open URL: $rawUrl')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navyDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Resource Details',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: ZabiraLoader(size: 40));
    }

    if (_errorMessage != null || _item == null) {
      return ZabiraErrorState(
        title: 'Unable to Load Book',
        message: _errorMessage ?? 'Book not found.',
        onRetry: _fetchDetails,
      );
    }

    final item = _item!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover Image ──────────────────────────────────────────────────
          Center(
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ZabiraNetworkImage(
                  imageUrl: item.resolvedCoverImage,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Category pill
          if (item.categoryName != null && item.categoryName!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.categoryName!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),

          // Title & Author
          Text(
            item.title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'By ${item.author}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 12),

          // Price display
          Text(
            item.formattedPrice,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),

          const SizedBox(height: 16),

          // ── Formats Selection (PDF, Paperback, Hardcover) ─────────────────
          if (item.formats.isNotEmpty) ...[
            Text(
              'Select Format',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(item.formats.length, (idx) {
                final fmt = item.formats[idx];
                final isSelected = _selectedFormatIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${fmt.format.toUpperCase()} (₹${fmt.price.toInt()})'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFormatIndex = idx),
                    selectedColor: AppColors.navyDark,
                    backgroundColor: Colors.white,
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.navyDark,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // ── Action Buttons (Download / Preview / Add to Cart) ─────────────
          Row(
            children: [
              if (item.resolvedPreviewUrl != null && item.resolvedPreviewUrl!.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchUrl(item.resolvedPreviewUrl!),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Preview PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyDark,
                      side: const BorderSide(color: AppColors.navyDark, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              if (item.resolvedPreviewUrl != null && item.resolvedPreviewUrl!.isNotEmpty)
                const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final auth = context.read<AuthController>();
                    final cart = context.read<CartController>();
                    final messenger = ScaffoldMessenger.of(context);

                    final format = _selectedFormat(item);

                    final success = await cart.addItem(
                      itemData: {
                        'book_id': item.id,
                        'format': format,
                        'book_format': format,
                        'product_type': 'library',
                        'quantity': '1',
                      },
                      token: auth.currentToken,
                    );

                    if (!mounted) return;

                    if (success) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Added "${item.title}" to cart!'),
                          backgroundColor: AppColors.navyDark,
                          duration: const Duration(seconds: 3),
                          action: SnackBarAction(
                            label: 'View Cart',
                            textColor: AppColors.gold,
                            onPressed: () {
                              if (mounted) {
                                context.push(AppRoutes.cart);
                              }
                            },
                          ),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(cart.errorMessage ?? 'Could not add book to cart.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final auth = context.read<AuthController>();
                if (!auth.isAuthenticated) {
                  auth.setPendingReturnTo('/library/${item.id}');
                  showAuthBottomSheet(context);
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                final format = _selectedFormat(item);
                try {
                  final response = await _service.purchaseLibraryItem(
                    bookId: item.id,
                    format: format,
                    token: auth.currentToken,
                  );
                  final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
                  final orderId = int.tryParse(data['order_id']?.toString() ?? data['id']?.toString() ?? '');
                  if (!mounted) return;
                  if (orderId == null || orderId <= 0) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Could not initialize library order.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  context.push(
                    AppRoutes.checkout,
                    extra: {
                      'orderId': orderId,
                      'productType': 'library',
                      'title': '${item.title} (${format.toUpperCase()})',
                      'amount': _selectedPrice(item),
                      'category': item.categoryName ?? 'Library',
                    },
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception:', '').trim()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: const Text('Buy Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navyDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Description
          if (item.cleanDescription.isNotEmpty) ...[
            Text(
              'About this Book',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.cleanDescription,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
