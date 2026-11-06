import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/apple_alert.dart';
import '../../../core/widgets/al_zara_pill.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../categories/presentation/category_management_sheet.dart';
import '../../products/presentation/product_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Settings', style: AppTypography.headlineSmall),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // ─── CATEGORY MANAGEMENT (Admin Only) ───
          if (authState.role == UserRole.admin) ...[
            const _SectionHeader(title: 'CATEGORIES'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => CategoryManagementSheet.show(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.goldBeigeSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(CupertinoIcons.square_grid_2x2_fill, size: 18, color: AppColors.primaryLight),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manage Categories', style: AppTypography.titleMedium),
                          Text(
                            '${categories.where((c) => c.id != 'all').length} categories · Tap to add or remove',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── SECURITY / PIN MANAGEMENT ───
            const _SectionHeader(title: 'SECURITY'),
            const SizedBox(height: 12),
            _ChangePinTile(currentRole: authState.role),
            const SizedBox(height: 24),
          ],

          // ─── APP / ROLE INFO ───
          const _SectionHeader(title: 'APP INFORMATION'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                _SettingsInfoRow(label: 'Current Role', value: authState.role.displayName),
                const Divider(color: AppColors.divider, height: 20),
                _SettingsInfoRow(
                  label: 'Device Target',
                  value: authState.role == UserRole.admin ? 'Mobile Phone' : 'iPad',
                ),
                const Divider(color: AppColors.divider, height: 20),
                const _SettingsInfoRow(label: 'Dev (report bugs to)', value: 'Ahmed'),
                const Divider(color: AppColors.divider, height: 20),
                const _SettingsInfoRow(label: 'Version', value: '1.0.2'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── LOGOUT / RESET ROLE (At the very end) ───
          GestureDetector(
            onTap: () async {
              final confirm = await AppleAlert.showConfirmation(
                context: context,
                title: 'Log Out',
                message: 'Are you sure you want to log out and return to the profile selection screen?',
                confirmText: 'Log Out',
                isDestructive: true,
                icon: CupertinoIcons.square_arrow_right,
                iconColor: AppColors.red,
              );

              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.square_arrow_right,
                      size: 18,
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Out & Reset Role',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.red),
                        ),
                        Text(
                          'Return to profile selection screen',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _ChangePinTile extends ConsumerStatefulWidget {
  final UserRole currentRole;
  const _ChangePinTile({required this.currentRole});

  @override
  ConsumerState<_ChangePinTile> createState() => _ChangePinTileState();
}

class _ChangePinTileState extends ConsumerState<_ChangePinTile> {
  bool _expanded = false;
  UserRole _targetRole = UserRole.admin;
  final TextEditingController _currentAdminCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentAdminCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final authRepo = ref.read(authRepositoryProvider);
    final currentAdminPin = _currentAdminCtrl.text.trim();
    final newPin = _newCtrl.text.trim();
    final confirmPin = _confirmCtrl.text.trim();

    // Verifies admin PIN to authorize change for either role
    if (!authRepo.verifyPin(UserRole.admin, currentAdminPin)) {
      setState(() => _error = 'Admin authorization PIN is incorrect');
      return;
    }
    if (newPin.length < 4) {
      setState(() => _error = 'New PIN must be at least 4 digits');
      return;
    }
    if (newPin != confirmPin) {
      setState(() => _error = 'PINs do not match');
      return;
    }

    setState(() => _saving = true);
    try {
      await authRepo.updatePin(_targetRole, newPin);
      _currentAdminCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      setState(() => _expanded = false);
      if (mounted) {
        AppleAlert.showToast(
          context,
          message: '${_targetRole == UserRole.admin ? "Admin" : "Shopkeeper (Staff)"} PIN updated successfully',
          icon: CupertinoIcons.lock_shield_fill,
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to update PIN. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _expanded = !_expanded;
              _error = null;
            }),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldBeigeSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.lock_fill, size: 18, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Change PINs', style: AppTypography.titleMedium),
                        Text('Update Admin or Staff access PIN', style: AppTypography.caption),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: AppColors.divider, height: 16),
                        
                        // Role Selector Pills: Admin PIN / Staff PIN
                        Text(
                          'SELECT PIN TO CHANGE',
                          style: AppTypography.caption.copyWith(
                            letterSpacing: 1.1,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            AlZaraPill(
                              label: 'Admin PIN',
                              isSelected: _targetRole == UserRole.admin,
                              variant: PillVariant.gold,
                              onTap: () => setState(() {
                                _targetRole = UserRole.admin;
                                _error = null;
                              }),
                            ),
                            const SizedBox(width: 8),
                            AlZaraPill(
                              label: 'Staff (Shopkeeper) PIN',
                              isSelected: _targetRole == UserRole.shopkeeper,
                              variant: PillVariant.gold,
                              onTap: () => setState(() {
                                _targetRole = UserRole.shopkeeper;
                                _error = null;
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _PinField(controller: _currentAdminCtrl, label: 'Current Admin PIN (Authorization)'),
                        const SizedBox(height: 10),
                        _PinField(
                          controller: _newCtrl,
                          label: 'New ${_targetRole == UserRole.admin ? "Admin" : "Staff"} PIN',
                        ),
                        const SizedBox(height: 10),
                        _PinField(
                          controller: _confirmCtrl,
                          label: 'Confirm New ${_targetRole == UserRole.admin ? "Admin" : "Staff"} PIN',
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.red)),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: _saving ? null : _submit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: _saving
                                  ? const CupertinoActivityIndicator(radius: 10, color: AppColors.background)
                                  : Text(
                                      'Save ${_targetRole == UserRole.admin ? "Admin" : "Staff"} PIN',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.background,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _PinField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 8,
      style: const TextStyle(color: AppColors.textPrimary, letterSpacing: 6, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        counterText: '',
        filled: true,
        fillColor: AppColors.cardElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.caption.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _SettingsInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        Text(value, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
