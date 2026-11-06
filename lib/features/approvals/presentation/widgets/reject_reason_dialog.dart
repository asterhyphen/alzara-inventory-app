import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class RejectReasonDialog extends StatefulWidget {
  final String productName;

  const RejectReasonDialog({
    super.key,
    required this.productName,
  });

  static Future<String?> show(BuildContext context, String productName) {
    return showDialog<String>(
      context: context,
      builder: (context) => RejectReasonDialog(productName: productName),
    );
  }

  @override
  State<RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<RejectReasonDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _quickReasons = [
    'Margin too low',
    'Exceeds market rate',
    'Incorrect cost price',
    'Duplicate request',
  ];
  String? _selectedQuickReason;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reject Change Request',
              style: AppTypography.headlineSmall.copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rejecting change for "${widget.productName}". Please select or provide a reason:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons.map((reason) {
                final isSelected = _selectedQuickReason == reason;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedQuickReason = null;
                        _controller.clear();
                      } else {
                        _selectedQuickReason = reason;
                        _controller.text = reason;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.red.withValues(alpha: 0.2)
                          : AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.red : AppColors.border,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? AppColors.red : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Custom reason (optional)...',
              ),
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            final reason = _controller.text.trim();
            Navigator.pop(
              context,
              reason.isNotEmpty ? reason : (_selectedQuickReason ?? 'Rejected by Admin'),
            );
          },
          child: const Text('Confirm Reject'),
        ),
      ],
    );
  }
}
