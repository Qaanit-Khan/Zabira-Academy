import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../../features/auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../../../features/courses/presentation/controllers/wishlist_controller.dart';
import '../../../../features/payment/data/utils/order_response_utils.dart';
import '../../../../features/store/presentation/controllers/cart_controller.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/scholarship_promo_banner.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/library_item_model.dart';
import '../../data/services/library_api_service.dart';
import '../widgets/library_book_card.dart';

class LibraryItemDetailsPage extends StatefulWidget {
  const LibraryItemDetailsPage({
    super.key,
    required this.itemId,
    this.initialItem,
  });

  final int itemId;
  final LibraryItemModel? initialItem;

  @override
  State<LibraryItemDetailsPage> createState() => _LibraryItemDetailsPageState();
}

class _LibraryItemDetailsPageState extends State<LibraryItemDetailsPage> {
  final LibraryApiService _service = LibraryApiService();
  LibraryItemModel? _item;
  List<LibraryItemModel> _relatedBooks = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedFormatIndex = 0;
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();

  // Exact Brand Colors
  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  @override
  void initState() {
    super.initState();
    _item = widget.initialItem;
    _fetchDetails();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getLibraryDetails(id: widget.itemId),
        _service.getLibraryList(limit: 6),
      ]);

      if (mounted) {
        setState(() {
          _item = results[0] as LibraryItemModel? ?? _item;
          final all = results[1] as List<LibraryItemModel>;
          _relatedBooks = all
              .where((b) => b.id != widget.itemId)
              .take(4)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (_item != null) {
          setState(() => _isLoading = false);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Unable to load book details.';
          });
        }
      }
    }
  }

  String _selectedFormat(LibraryItemModel item) {
    if (item.formats.isNotEmpty && _selectedFormatIndex < item.formats.length) {
      return item.formats[_selectedFormatIndex].format;
    }
    return 'pdf';
  }

  double _selectedPrice(LibraryItemModel item) {
    if (item.formats.isNotEmpty && _selectedFormatIndex < item.formats.length) {
      final format = item.formats[_selectedFormatIndex];
      return format.salePrice ?? format.price;
    }
    return item.salePrice ?? item.price;
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
            SnackBar(content: Text('Could not open preview: $rawUrl')),
          );
        }
      }
    }
  }

  void _shareBook() {
    if (_item == null) return;
    final shareText =
        'Read "${_item!.title}" on Zabira Academy Library! Check it out here: https://zabiraacademy.com/library/${_item!.slug}';
    Clipboard.setData(ClipboardData(text: shareText));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: brandGold, size: 18),
            const SizedBox(width: 8),
            Text(
              'Book link copied to clipboard!',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: brandNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  Future<void> _addToCart() async {
    if (_item == null) return;
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();
    final messenger = ScaffoldMessenger.of(context);

    final format = _selectedFormat(_item!);

    final price = _selectedPrice(_item!);
    final success = await cart.addItem(
      itemData: {
        'book_id': _item!.id,
        'title': _item!.title,
        'name': _item!.title,
        'image': _item!.coverImage,
        'thumbnail': _item!.coverImage,
        'format': format,
        'book_format': format,
        'product_type': 'library',
        'price': price,
        'discount_price': price,
        'quantity': '1',
      },
      token: auth.currentToken,
    );

    if (!mounted) return;

    if (success) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: brandGold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Added "${_item!.title}" to cart!')),
            ],
          ),
          backgroundColor: brandNavy,
          duration: const Duration(milliseconds: 2500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: brandGold,
            onPressed: () => context.push(AppRoutes.cart),
          ),
        ),
      );
    } else {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(cart.errorMessage ?? 'Could not add book to cart.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _handleBuyNow() async {
    if (_item == null) return;
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/library/${_item!.id}');
      showAuthBottomSheet(context);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final format = _selectedFormat(_item!);
    try {
      final response = await _service.purchaseLibraryItem(
        bookId: _item!.id,
        format: format,
        token: auth.currentToken,
      );
      final orderId = extractOrderId(response);
      if (!mounted) return;
      if (orderId == null || orderId <= 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not initialize library order.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      context.push(
        AppRoutes.checkout,
        extra: {
          'orderId': orderId,
          'productType': 'library',
          'title': '${_item!.title} (${format.toUpperCase()})',
          'amount': _selectedPrice(_item!),
          'category': _item!.categoryName ?? 'Library',
        },
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _item == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: ZabiraLoader(size: 40)),
      );
    }

    if (_errorMessage != null && _item == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: brandNavy,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ZabiraErrorState(
          title: 'Unable to Load Book',
          message: _errorMessage ?? 'Book not found.',
          onRetry: _fetchDetails,
        ),
      );
    }

    final item = _item!;
    final wishlist = context.watch<WishlistController>();
    final isFav = wishlist.isLibraryFavorite(item.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: brandNavy,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: brandNavy,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? brandGold : brandNavy,
              size: 22,
            ),
            onPressed: () => wishlist.toggleLibraryItem(item),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: brandNavy, size: 20),
            onPressed: _shareBook,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomStickyBar(item),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Hero Cover Image Carousel with Dot Indicators & Preview Overlay ──
            _buildCoverCard(item),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 2. Badges Row (Language, PREMIUM, PRINT & DIGITAL) ─────
                  _buildBadgesRow(item),

                  const SizedBox(height: 12),

                  // ── 3. Title & Author ────────────────────────────────────
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: brandNavy,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: brandGold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'By ${item.author}',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── 4. Price & Savings Tag ───────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        item.formattedPrice,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: brandNavy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: brandGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: brandGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Save 25% • Best Value',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: brandNavy,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── 5. Format Selection Cards ─────────────────────────────
                  _buildFormatSelection(item),

                  const SizedBox(height: 20),

                  // ── 6. Two Primary Action Buttons ─────────────────────────
                  Row(
                    children: [
                      // Add to Cart (Navy Outlined Button)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _addToCart,
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 18,
                            ),
                            label: Text(
                              'Add to Cart',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: brandNavy,
                              side: const BorderSide(
                                color: brandNavy,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Buy Now (Golden #C9A84C Button with single Flash Icon)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _handleBuyNow,
                            icon: const Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: brandNavy,
                            ),
                            label: Text(
                              'BUY NOW',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: brandNavy,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandGold,
                              foregroundColor: brandNavy,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 7. About This Book ───────────────────────────────────
                  _buildAboutSection(item),

                  const SizedBox(height: 24),

                  // ── 8. Book Specifications Box ────────────────────────────
                  _buildSpecBox(item),

                  const SizedBox(height: 28),

                  // ── 9. Related Books Grid ─────────────────────────────────
                  if (_relatedBooks.isNotEmpty) ...[
                    _buildRelatedBooksSection(),
                    const SizedBox(height: 24),
                  ],

                  // ── 10. Promotional Banner ────────────────────────────────
                  const ScholarshipPromoBanner(),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cover Image Container with Multi-Image Slider & Preview Button ─────────
  Widget _buildCoverCard(LibraryItemModel item) {
    final images = item.allImages;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            if (images.length > 1) ...[
              // Multi-Image Carousel Slider
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: _imagePageController,
                  itemCount: images.length,
                  onPageChanged: (idx) {
                    setState(() => _currentImageIndex = idx);
                  },
                  itemBuilder: (context, index) {
                    final imgUrl = images[index];
                    return Center(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 280,
                          maxWidth: 220,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: brandNavy.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ZabiraNetworkImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.menu_book_rounded,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (idx) {
                  final isSelected = _currentImageIndex == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSelected ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? brandGold : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ] else ...[
              // Single Image Fallback
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 280,
                  maxWidth: 220,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: brandNavy.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      item.resolvedCoverImage != null &&
                          item.resolvedCoverImage!.isNotEmpty
                      ? ZabiraNetworkImage(
                          imageUrl: item.resolvedCoverImage,
                          fit: BoxFit.cover,
                          fallbackIcon: Icons.menu_book_rounded,
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: brandNavy,
                              size: 54,
                            ),
                          ),
                        ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Preview PDF Button
            if (item.resolvedPreviewUrl != null &&
                item.resolvedPreviewUrl!.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _launchUrl(item.resolvedPreviewUrl!),
                icon: const Icon(
                  Icons.visibility_rounded,
                  size: 16,
                  color: brandNavy,
                ),
                label: Text(
                  'Preview Sample PDF',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: brandNavy,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  backgroundColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Badges Row (No NEW badge, prominent Language badge) ─────────────────────
  Widget _buildBadgesRow(LibraryItemModel item) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildPillTag(item.displayLanguage, brandNavy, brandGold),
        if (item.premium) _buildPillTag('PREMIUM', brandGold, brandNavy),
        _buildPillTag('PRINT & DIGITAL', const Color(0xFFE2E8F0), brandNavy),
        if (item.categoryName != null && item.categoryName!.isNotEmpty)
          _buildPillTag(
            item.categoryName!.toUpperCase(),
            const Color(0xFFEFF6FF),
            const Color(0xFF2563EB),
          ),
      ],
    );
  }

  Widget _buildPillTag(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ── Format Selection List ──────────────────────────────────────────────────
  Widget _buildFormatSelection(LibraryItemModel item) {
    final formats = item.formats.isNotEmpty
        ? item.formats
        : [
            const LibraryBookFormat(format: 'pdf', enabled: true, price: 149),
            const LibraryBookFormat(
              format: 'paperback',
              enabled: true,
              price: 299,
            ),
            const LibraryBookFormat(
              format: 'hardcover',
              enabled: true,
              price: 499,
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Edition & Format',
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: brandNavy,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(formats.length, (idx) {
          final f = formats[idx];
          final isSelected = _selectedFormatIndex == idx;
          final price = (f.salePrice != null && f.salePrice! > 0)
              ? f.salePrice!
              : f.price;

          String subtitle = 'Instant Digital PDF Download';
          IconData icon = Icons.picture_as_pdf_rounded;
          if (f.format.toLowerCase() == 'paperback') {
            subtitle = 'Softcover printed book delivered to your doorstep';
            icon = Icons.menu_book_rounded;
          } else if (f.format.toLowerCase() == 'hardcover') {
            subtitle = 'Collector’s Hardcover edition with gold foil';
            icon = Icons.auto_stories_rounded;
          } else if (f.format.toLowerCase().contains('audio')) {
            subtitle = 'Full audiobook narration in clear Urdu & English';
            icon = Icons.headphones_rounded;
          }

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFormatIndex = idx);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? brandGold : const Color(0xFFE2E8F0),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? brandGold.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected ? brandNavy : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? brandGold : brandNavy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.format.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: brandNavy,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${price.toInt()}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: brandNavy,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── About Section ──────────────────────────────────────────────────────────
  Widget _buildAboutSection(LibraryItemModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this Book',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: brandNavy,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.cleanDescription.isNotEmpty
                    ? item.cleanDescription
                    : 'A beautifully written and illustrated Islamic moral book designed to inspire faith, wisdom, and strong values in young readers.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFF475569),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              Text(
                'Key Highlights:',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: brandNavy,
                ),
              ),
              const SizedBox(height: 8),
              _buildHighlightBullet(
                'Authentic teachings inspired by the Quran & Sunnah',
              ),
              _buildHighlightBullet(
                'Engaging full-color character illustrations',
              ),
              _buildHighlightBullet(
                'Interactive reflection questions for children and parents',
              ),
              _buildHighlightBullet(
                'Easy-to-understand storytelling in Urdu and English',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 15, color: brandGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Specifications Box ─────────────────────────────────────────────────────
  Widget _buildSpecBox(LibraryItemModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Specifications',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: brandNavy,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecRow('Publisher', item.author),
          const Divider(color: Color(0xFFF1F5F9), height: 16),
          _buildSpecRow('Language', item.displayLanguage),
          const Divider(color: Color(0xFFF1F5F9), height: 16),
          _buildSpecRow('Target Age', '5 - 15 Years'),
          const Divider(color: Color(0xFFF1F5F9), height: 16),
          _buildSpecRow('Delivery Mode', 'Instant PDF + Nationwide Shipping'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: brandNavy,
          ),
        ),
      ],
    );
  }

  // ── Related Books ──────────────────────────────────────────────────────────
  Widget _buildRelatedBooksSection() {
    final wishlist = context.watch<WishlistController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RELATED TO THIS BOOK',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: brandGold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Recommended Reads',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: brandNavy,
          ),
        ),
        const SizedBox(height: 14),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.53,
          ),
          itemCount: _relatedBooks.length,
          itemBuilder: (context, index) {
            final book = _relatedBooks[index];
            return LibraryBookCard(
              item: book,
              isFavorite: wishlist.isLibraryFavorite(book.id),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => LibraryItemDetailsPage(
                      itemId: book.id,
                      initialItem: book,
                    ),
                  ),
                );
              },
              onAddToCart: () async {
                final auth = context.read<AuthController>();
                final cart = context.read<CartController>();
                final format = book.formats.isNotEmpty
                    ? book.formats.first.format
                    : 'pdf';
                final price = (book.formats.isNotEmpty && book.formats.first.salePrice != null)
                    ? book.formats.first.salePrice!
                    : (book.salePrice ?? book.price);
                await cart.addItem(
                  itemData: {
                    'book_id': book.id,
                    'title': book.title,
                    'name': book.title,
                    'image': book.coverImage,
                    'thumbnail': book.coverImage,
                    'format': format,
                    'book_format': format,
                    'product_type': 'library',
                    'price': price,
                    'discount_price': price,
                    'quantity': '1',
                  },
                  token: auth.currentToken,
                );
              },
              onFavoriteToggle: () => wishlist.toggleLibraryItem(book),
            );
          },
        ),
      ],
    );
  }

  // ── Bottom Sticky Bar ──────────────────────────────────────────────────────
  Widget _buildBottomStickyBar(LibraryItemModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cart Button
            IconButton(
              onPressed: _addToCart,
              icon: const Icon(
                Icons.add_shopping_cart_rounded,
                color: brandNavy,
              ),
            ),

            const SizedBox(width: 8),

            // Buy Now CTA Button (Golden #C9A84C)
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _handleBuyNow,
                  icon: const Icon(
                    Icons.bolt_rounded,
                    color: brandNavy,
                    size: 20,
                  ),
                  label: Text(
                    'BUY NOW FOR ₹${_selectedPrice(item).toInt()}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: brandNavy,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGold,
                    foregroundColor: brandNavy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
