import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/event_item_model.dart';
import '../../data/services/events_api_service.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage({super.key, required this.eventId, this.initialEvent});

  final int eventId;
  final EventItemModel? initialEvent;

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final EventsApiService _service = EventsApiService();
  EventItemModel? _event;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _event = widget.initialEvent;
    if (_event == null) {
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
      final item = await _service.getEventDetails(id: widget.eventId);
      setState(() {
        _event = item;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load event details.';
      });
    }
  }

  void _showRegistrationDialog() {
    if (_event == null) return;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Register for ${_event!.title}',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter name and email')),
                        );
                        return;
                      }
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _service.registerForEvent(
                          eventId: _event!.id,
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Registration submitted successfully!')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        setDialogState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Registration failed: $e')),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Registration'),
            ),
          ],
        ),
      ),
    );
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
          'Event Details',
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

    if (_errorMessage != null || _event == null) {
      return ZabiraErrorState(
        title: 'Unable to Load Event',
        message: _errorMessage ?? 'Event not found.',
        onRetry: _fetchDetails,
      );
    }

    final event = _event!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner Image ────────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ZabiraNetworkImage(
                  imageUrl: event.resolvedBannerImage,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.event_rounded,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(140),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.category,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF071B36),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event.title,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),

                // Key Info Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.calendar_today_rounded, 'Date', event.formattedDate),
                      const Divider(height: 16),
                      _buildInfoRow(Icons.access_time_rounded, 'Time', event.formattedTime),
                      const Divider(height: 16),
                      _buildInfoRow(Icons.location_on_rounded, 'Location', event.formattedLocation),
                      if (event.seatsLeft > 0) ...[
                        const Divider(height: 16),
                        _buildInfoRow(Icons.event_seat_rounded, 'Seats Remaining', '${event.seatsLeft} available'),
                      ],
                      if (event.registrationFee > 0) ...[
                        const Divider(height: 16),
                        _buildInfoRow(Icons.payment_rounded, 'Registration Fee', '₹${event.registrationFee.toInt()}'),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Register Button
                if (event.registrationOpen)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showRegistrationDialog,
                      icon: const Icon(Icons.how_to_reg_rounded, size: 20),
                      label: const Text('Register for Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Description
                if (event.shortDescription.isNotEmpty) ...[
                  Text(
                    'About this Event',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.shortDescription,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gold),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyDark),
        ),
      ],
    );
  }
}
