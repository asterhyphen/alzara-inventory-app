import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ApproveAllDialog extends StatelessWidget {
  final int count;

  const ApproveAllDialog({
    super.key,
    required this.count,
  });

  static Future<bool?> show(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ApproveAllDialog(count: count),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.green, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Approve All Changes?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        'You are about to batch-approve $count pending changes. This will immediately update the live product catalog on all devices.',
        style: AppTypography.bodySmall,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text('Approve All ($count)', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
