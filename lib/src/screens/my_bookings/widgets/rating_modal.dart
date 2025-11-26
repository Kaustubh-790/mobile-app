import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../models/booking.dart';
import '../../../theme/app_theme.dart';

class RatingModal extends StatefulWidget {
  final Booking booking;
  final int serviceIndex;
  final VoidCallback onRated;

  const RatingModal({
    super.key,
    required this.booking,
    required this.serviceIndex,
    required this.onRated,
  });

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await context.read<BookingProvider>().rateService(
        widget.booking.id!,
        widget.serviceIndex,
        _rating,
        _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
      );

      if (success && mounted) {
        widget.onRated();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.booking.services[widget.serviceIndex];
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: AppTheme.beigeDefault,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rate & Review Service',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.brown500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: AppTheme.brown400),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.sand40,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.beige10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.serviceId,
                    style: TextStyle(
                      color: AppTheme.brown500,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: ₹${service.price.toStringAsFixed(2)}',
                    style: TextStyle(color: AppTheme.brown300, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rating
            Text(
              'Rating *',
              style: TextStyle(
                color: AppTheme.brown500,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: index < _rating ? Colors.amber : AppTheme.brown200,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Review
            Text(
              'Review (Optional)',
              style: TextStyle(
                color: AppTheme.brown500,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 3,
              maxLength: 200,
              style: TextStyle(color: AppTheme.brown500),
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: TextStyle(color: AppTheme.brown300),
                filled: true,
                fillColor: AppTheme.sand50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.beige10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.beige10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.primaryDefault,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.brown400),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _rating == 0
                        ? null
                        : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDefault,
                      foregroundColor: AppTheme.beige4,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.beige4,
                              ),
                            ),
                          )
                        : const Text('Submit Rating'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
