import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/router.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../../auth/auth_controller.dart';
import '../../../payment/presentation/controllers/payment_controller.dart';
import '../controllers/student_controller.dart';
import '../../data/models/student_profile_models.dart';
import '../../data/services/student_api_service.dart';
import '../widgets/student_breadcrumb.dart';
import '../widgets/student_hero_header.dart';
import '../widgets/student_nav_tabs_bar.dart';

/// Screen 7: Student My Orders (1:1 with `7 - profile my product 7.pdf`)
class StudentMyOrdersPage extends StatefulWidget {
  const StudentMyOrdersPage({super.key});

  @override
  State<StudentMyOrdersPage> createState() => _StudentMyOrdersPageState();
}

class _StudentMyOrdersPageState extends State<StudentMyOrdersPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StudentApiService _apiService = StudentApiService();

  bool _isLoading = true;
  List<StudentOrderItem> _allOrders = [];
  String _selectedCategory = 'All Orders';
  String _selectedStatus = 'All';

  final List<String> _categories = [
    'All Orders',
    'Courses',
    'Library',
    'Store',
    'Events',
    'Scholarships',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    final auth = context.read<AuthController>();
    final paymentCtrl = context.read<PaymentController>();
    if (auth.isAuthenticated && auth.user != null) {
      context.read<StudentController>().loadDashboard(
            auth.currentToken,
            defaultName: auth.user!.displayName,
            defaultEmail: auth.user!.email,
            defaultPhoto: auth.user!.photoUrl,
          );

      setState(() => _isLoading = true);
      try {
        final orders = await _apiService.getMyOrders(token: auth.currentToken ?? '');
        if (orders.isNotEmpty) {
          if (mounted) {
            setState(() {
              _allOrders = orders;
              _isLoading = false;
            });
          }
          return;
        }
      } catch (_) {}

      // Fallback to PaymentController
      try {
        await paymentCtrl.loadMyOrders(auth.currentToken);
        final pOrders = paymentCtrl.myOrders;
        if (pOrders.isNotEmpty) {
          final mapped = pOrders.map((po) {
            final isPaid = po.isPaid;
            return StudentOrderItem(
              id: po.orderId,
              title: po.title,
              amount: po.amount,
              status: isPaid ? 'PAYMENT SUCCESSFUL' : 'PENDING PAYMENT',
              fulfillmentStatus: isPaid ? 'COMPLETED' : 'PENDING',
              productType: po.productType.toUpperCase(),
              dateStr: po.date != null ? po.date!.toLocal().toString().split('.').first : '',
              orderCode: po.invoiceNumber ?? 'ZA-2026-0000${po.orderId}',
              invoiceCode: po.invoiceNumber ?? '',
              invoiceUrl: po.invoiceUrl,
            );
          }).toList();
          if (mounted) {
            setState(() {
              _allOrders = mapped;
              _isLoading = false;
            });
          }
          return;
        }
      } catch (_) {}

      if (mounted) setState(() => _isLoading = false);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<StudentOrderItem> _getFilteredOrders() {
    return _allOrders.where((order) {
      // Category filter
      if (_selectedCategory != 'All Orders') {
        final cat = _selectedCategory.toUpperCase();
        if (cat == 'COURSES' && order.productType != 'COURSE') return false;
        if (cat == 'LIBRARY' && order.productType != 'LIBRARY' && order.productType != 'BOOK') return false;
        if (cat == 'STORE' && order.productType != 'STORE' && order.productType != 'PRODUCT') return false;
        if (cat == 'EVENTS' && order.productType != 'EVENT') return false;
        if (cat == 'SCHOLARSHIPS' && order.productType != 'SCHOLARSHIP') return false;
      }

      // Status filter
      if (_selectedStatus != 'All') {
        if (_selectedStatus == 'Completed' && !order.isSuccessful) return false;
        if (_selectedStatus == 'Pending' && !order.isPending) return false;
        if (_selectedStatus == 'Failed' && !order.status.toUpperCase().contains('FAIL')) return false;
        if (_selectedStatus == 'Cancelled' && !order.status.toUpperCase().contains('CANCEL')) return false;
        if (_selectedStatus == 'Refunded' && !order.status.toUpperCase().contains('REFUND')) return false;
      }

      return true;
    }).toList();
  }

  int _countForStatus(String status) {
    if (status == 'All') return _allOrders.length;
    if (status == 'Completed') return _allOrders.where((o) => o.isSuccessful).length;
    if (status == 'Pending') return _allOrders.where((o) => o.isPending).length;
    if (status == 'Failed') return _allOrders.where((o) => o.status.toUpperCase().contains('FAIL')).length;
    if (status == 'Cancelled') return _allOrders.where((o) => o.status.toUpperCase().contains('CANCEL')).length;
    if (status == 'Refunded') return _allOrders.where((o) => o.status.toUpperCase().contains('REFUND')).length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final studentCtrl = context.watch<StudentController>();
    final user = auth.user;
    final dashboard = studentCtrl.dashboard;

    final filteredOrders = _getFilteredOrders();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      bottomNavigationBar: const ZabiraBottomNav(selectedIndex: -1),
      body: RefreshIndicator(
        color: const Color(0xFFC9A84C),
        onRefresh: () async {
          await _loadOrders();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 1. Dark Navy Top Hero Header
              StudentHeroHeader(user: user, dashboard: dashboard),

              // 2. Horizontal Nav Bar (Index 6: My Orders)
              const StudentNavTabsBar(selectedIndex: 6),

              // 3. Breadcrumb & Section Title
              StudentBreadcrumbHeader(
                currentPage: 'My Orders',
                title: 'My Orders',
                subtitle: 'All purchases and transactions in one place — courses, library, store, events, and scholarships.',
                actionWidget: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.store),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A84C),
                    foregroundColor: const Color(0xFF112039),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Browse Store',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF112039),
                    ),
                  ),
                ),
              ),

              // 4. Filter and List Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header tag
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MY ORDERS',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_allOrders.length} orders across courses, library, store, events, and scholarships',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = cat == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedCategory = cat),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF112039) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF112039) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: ['All', 'Completed', 'Pending', 'Failed', 'Cancelled', 'Refunded'].map((st) {
                          final isSelected = st == _selectedStatus;
                          final count = _countForStatus(st);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedStatus = st),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF112039) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF112039) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  '$st ($count)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Orders List
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
                        ),
                      )
                    else if (filteredOrders.isEmpty)
                      _buildEmptyState(context)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderCard(context, order);
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.shoppingBag, size: 36, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No orders found',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'No orders matching the selected filter.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, StudentOrderItem order) {
    final isSuccess = order.isSuccessful;
    final statusBgColor = isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final statusTextColor = isSuccess ? const Color(0xFF16A34A) : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Thumbnail + Title + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF1F5F9),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: order.thumbnailUrl != null && order.thumbnailUrl!.isNotEmpty
                      ? ZabiraNetworkImage(imageUrl: order.thumbnailUrl!, fit: BoxFit.cover)
                      : const Icon(LucideIcons.bookOpen, color: Color(0xFF64748B), size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.title,
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.productType,
                            style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.invoiceCode.isNotEmpty ? '${order.orderCode} · ${order.invoiceCode}' : order.orderCode,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: statusTextColor, letterSpacing: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Fulfillment / Shipment line
          Text(
            'FULFILLMENT: ${order.fulfillmentStatus}    SHIPMENT: ${order.shipmentStatus}',
            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),

          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount: ${order.currency}${order.amount.toInt()}',
                style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              if (order.dateStr.isNotEmpty)
                Text(
                  'Date: ${order.dateStr}',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
            ],
          ),
          if (order.paymentId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Payment ID: ${order.paymentId}',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
            ),
          ],
          if (order.cashfreeOrderId.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Cashfree Order: ${order.cashfreeOrderId}',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
            ),
          ],
          if (order.paymentMethod.isNotEmpty || order.receiptCode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (order.paymentMethod.isNotEmpty)
                  Text('Method: ${order.paymentMethod}    ', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                if (order.receiptCode.isNotEmpty)
                  Text('Receipt: ${order.receiptCode}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Action Buttons Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // 1. View Order (Always visible)
                _buildActionButton(
                  label: 'View Order',
                  icon: LucideIcons.eye,
                  color: const Color(0xFF112039),
                  textColor: Colors.white,
                  onTap: () => _showOrderDetails(context, order),
                ),
                const SizedBox(width: 8),

                // 2. If Successful: Invoices, Receipts, Course access
                if (isSuccess) ...[
                  if (order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty) ...[
                    _buildActionButton(
                      label: 'Invoice',
                      icon: LucideIcons.download,
                      isOutlined: true,
                      onTap: () => launchUrl(Uri.parse(order.invoiceUrl!), mode: LaunchMode.externalApplication),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (order.receiptUrl != null && order.receiptUrl!.isNotEmpty) ...[
                    _buildActionButton(
                      label: 'Receipt',
                      icon: LucideIcons.receipt,
                      isOutlined: true,
                      onTap: () => launchUrl(Uri.parse(order.receiptUrl!), mode: LaunchMode.externalApplication),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (order.courseId != null && order.courseId! > 0) ...[
                    _buildActionButton(
                      label: 'Access Course',
                      icon: LucideIcons.externalLink,
                      color: const Color(0xFFC9A84C),
                      textColor: const Color(0xFF112039),
                      onTap: () => context.push('/courses/${order.courseId}/learn'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ] else ...[
                  // 3. Retry Payment (Pending/Failed)
                  _buildActionButton(
                    label: 'Retry Payment',
                    icon: LucideIcons.refreshCw,
                    color: const Color(0xFFC9A84C),
                    textColor: const Color(0xFF112039),
                    onTap: () => context.push(AppRoutes.checkout, extra: {
                      'orderId': order.id,
                      'amount': order.amount,
                      'title': order.title,
                      'productType': order.productType.toLowerCase(),
                    }),
                  ),
                  const SizedBox(width: 8),

                  // 4. Check Status
                  _buildActionButton(
                    label: 'Check Status',
                    icon: LucideIcons.shieldAlert,
                    isOutlined: true,
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF112039),
                          content: Text('Checking status for Order #${order.id}...', style: GoogleFonts.outfit(color: Colors.white)),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      await _loadOrders();
                    },
                  ),
                  const SizedBox(width: 8),

                  // 5. Cancel Order
                  _buildActionButton(
                    label: 'Cancel Order',
                    icon: LucideIcons.xCircle,
                    textColor: const Color(0xFFEF4444),
                    isOutlined: true,
                    onTap: () => _confirmCancelOrder(context, order),
                  ),
                  const SizedBox(width: 8),
                ],

                // 6. Delete / Remove from list
                _buildActionButton(
                  label: 'Delete',
                  icon: LucideIcons.trash2,
                  textColor: const Color(0xFF94A3B8),
                  isOutlined: true,
                  onTap: () => _confirmDeleteOrder(context, order),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, StudentOrderItem order) {
    final isSuccess = order.isSuccessful;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Details',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.status,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text('Order ID: ${order.orderCode}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        if (order.invoiceCode.isNotEmpty)
                          Text('Invoice No: ${order.invoiceCode}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount Paid', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                            Text('${order.currency}${order.amount.toInt()}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                          ],
                        ),
                        if (order.dateStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                              Text(order.dateStr, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                        ],
                        if (order.paymentMethod.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Method', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                              Text(order.paymentMethod, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              launchUrl(Uri.parse(order.invoiceUrl!), mode: LaunchMode.externalApplication);
                            },
                            icon: const Icon(LucideIcons.download, size: 16),
                            label: const Text('Download Invoice'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF112039),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmCancelOrder(BuildContext context, StudentOrderItem order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Order', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to cancel order #${order.orderCode}?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final auth = context.read<AuthController>();
              Navigator.pop(ctx);
              if (auth.currentToken != null) {
                await _apiService.cancelOrder(token: auth.currentToken!, orderId: order.id);
                _loadOrders();
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF112039),
                      content: Text('Order cancelled successfully', style: GoogleFonts.outfit(color: Colors.white)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOrder(BuildContext context, StudentOrderItem order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Order', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Remove this order from your order list?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _allOrders.removeWhere((o) => o.id == order.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF475569),
                  content: Text('Order removed from list', style: GoogleFonts.outfit(color: Colors.white)),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    IconData? icon,
    Color? color,
    Color? textColor,
    bool isOutlined = false,
    required VoidCallback onTap,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: icon != null ? Icon(icon, size: 13, color: textColor ?? const Color(0xFF1E293B)) : const SizedBox.shrink(),
        label: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: textColor ?? const Color(0xFF1E293B)),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: icon != null ? Icon(icon, size: 13, color: textColor ?? Colors.white) : const SizedBox.shrink(),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: textColor ?? Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFF112039),
        foregroundColor: textColor ?? Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
