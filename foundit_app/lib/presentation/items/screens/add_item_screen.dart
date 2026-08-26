import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/enums/item_status.dart';
import '../../../core/enums/item_type.dart';
import '../../../core/enums/verification_status.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/item_model.dart';
import '../../../providers/app_providers.dart';
import '../../common/shell/main_shell.dart';
import '../../common/widgets/app_image.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  ItemType _itemType = ItemType.lost;
  String _category = 'Electronics';
  DateTime _dateLostOrFound = DateTime.now();

  String? _base64ImageUrl;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _categories = [
    'Electronics',
    'ID Card',
    'Keys',
    'Wallet',
    'Clothing',
    'Books',
    'Accessories',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = await ref.read(currentUserProvider.future);
      if (user != null && mounted) {
        final phone = user.registrationPhone ?? user.phone ?? '';
        if (phone.isNotEmpty) {
          setState(() {
            _contactPhoneCtrl.text = phone;
            _whatsappCtrl.text = phone;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      // Compress & resize image to max 600px, 50% quality to keep payload under ~40KB
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _base64ImageUrl = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotificationPopup.show(
          context,
          title: 'Image Selection Failed',
          message: '$e',
          icon: Icons.error_outline_rounded,
          color: AppColors.error,
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _base64ImageUrl = null;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateLostOrFound,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateLostOrFound = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = await ref.read(currentUserProvider.future);
      final userId = currentUser?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      final reporterName = currentUser?.name.isNotEmpty == true ? currentUser!.name : 'Campus Reporter';
      final regPhone = currentUser?.registrationPhone ?? currentUser?.phone ?? '+911111111111';

      final contactPhone = _contactPhoneCtrl.text.trim().isNotEmpty
          ? _contactPhoneCtrl.text.trim()
          : regPhone;
      final contactWhatsApp = _whatsappCtrl.text.trim().isNotEmpty
          ? _whatsappCtrl.text.trim()
          : contactPhone;

      final newItem = ItemModel(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        type: _itemType,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        location: _locationCtrl.text.trim(),
        dateLostOrFound: _dateLostOrFound,
        imageUrl: _base64ImageUrl,
        status: ItemStatus.active,
        verificationStatus: VerificationStatus.pending,
        reportedBy: userId,
        reporterName: reporterName,
        reporterPhone: contactPhone,
        contactPhone: contactPhone,
        contactWhatsApp: contactWhatsApp,
        createdAt: DateTime.now(),
      );

      final repo = ref.read(itemRepositoryProvider);
      await repo.addItem(newItem);

      if (mounted) {
        AppNotificationPopup.show(
          context,
          title: '🎉 Item Submitted',
          message: 'Your ${_itemType.displayName} report "${newItem.title}" is now live!',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        );

        ref.invalidate(activeItemsProvider);
        ref.invalidate(myReportedItemsProvider);
        ref.invalidate(aiMatchesProvider);

        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      debugPrint('AddItem submit error: $e');
      if (mounted) {
        final errText = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          _errorMessage = errText;
        });

        AppNotificationPopup.show(
          context,
          title: '⚠️ Submission Error',
          message: errText,
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report Item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Item Type Selector (Lost vs Found)
                const Text(
                  'Item Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _itemType = ItemType.lost),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _itemType == ItemType.lost
                                ? AppColors.error.withValues(alpha: 0.15)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _itemType == ItemType.lost
                                  ? AppColors.error
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                color: _itemType == ItemType.lost
                                    ? AppColors.error
                                    : AppColors.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'I LOST an Item',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _itemType == ItemType.lost
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _itemType = ItemType.found),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _itemType == ItemType.found
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _itemType == ItemType.found
                                  ? AppColors.success
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: _itemType == ItemType.found
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'I FOUND an Item',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _itemType == ItemType.found
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Image Picker Container with Clean Preview
                const Text(
                  'Item Image',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _base64ImageUrl != null
                    ? Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AppImage(
                                imageUrl: _base64ImageUrl,
                                fit: BoxFit.contain,
                                borderRadius: BorderRadius.circular(16),
                                category: _category,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  IconButton.filledTonal(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.edit_rounded, size: 18),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.surfaceElevated,
                                      foregroundColor: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton.filledTonal(
                                    onPressed: _removeImage,
                                    icon: const Icon(Icons.delete_rounded, size: 18),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.error.withValues(alpha: 0.2),
                                      foregroundColor: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                size: 36,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to select or upload item photo',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 20),

                // Title Input
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item Title',
                    hintText: 'e.g. Blue Samsung Phone',
                  ),
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),

                // Description Input
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Description',
                    hintText: 'e.g. Color, marks, brand, unique identifiers...',
                  ),
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  dropdownColor: AppColors.surface,
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat,
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 16),

                // Location Input
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location (Lost / Found at)',
                    hintText: 'e.g. Library Cafeteria, Block B',
                  ),
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),

                // Item Contact Phone (Auto pre-filled from registration phone)
                TextFormField(
                  controller: _contactPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone for Call',
                    hintText: 'e.g. +91 9876543210 (Defaults to Registered Phone)',
                  ),
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),

                // Item WhatsApp Phone for WhatsApp
                TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Number for Chat',
                    hintText: 'e.g. +91 9876543210 (Defaults to Contact Phone)',
                  ),
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),

                // Date Picker Tile
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date Lost/Found',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(_dateLostOrFound),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down_rounded,
                            color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Item Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
