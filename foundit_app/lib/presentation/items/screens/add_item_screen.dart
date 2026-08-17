import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/enums/item_status.dart';
import '../../../core/enums/item_type.dart';
import '../../../core/enums/verification_status.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/item_model.dart';
import '../../../providers/app_providers.dart';

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

  ItemType _itemType = ItemType.lost;
  String _category = 'Electronics';
  DateTime _dateLostOrFound = DateTime.now();

  File? _selectedImageFile;
  Uint8List? _webImageBytes;
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
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _selectedImageFile = null;
        });
      } else {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _webImageBytes = null;
        });
      }
    }
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
      final userId = currentUser?.uid ?? 'guest_user';
      final reporterName = currentUser?.name ?? 'Guest Reporter';
      final reporterPhone = currentUser?.phone ?? '+919876543210';

      String? imageUrl;
      final isFirebase = ref.read(isFirebaseInitializedProvider);

      if (isFirebase && _selectedImageFile != null) {
        imageUrl = await ref
            .read(firebaseStorageServiceProvider)
            .uploadItemImage(userId, _selectedImageFile!);
      }

      final newItem = ItemModel(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        type: _itemType,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        location: _locationCtrl.text.trim(),
        dateLostOrFound: _dateLostOrFound,
        imageUrl: imageUrl,
        status: ItemStatus.active,
        verificationStatus: VerificationStatus.pending,
        reportedBy: userId,
        reporterName: reporterName,
        reporterPhone: reporterPhone,
        createdAt: DateTime.now(),
      );

      final repo = ref.read(itemRepositoryProvider);
      await repo.addItem(newItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item reported successfully as ${_itemType.displayName}!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(activeItemsProvider);
        ref.invalidate(myReportedItemsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: AppColors.error)),
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

                // Image Picker Box
                const Text(
                  'Item Image',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _selectedImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImageFile!,
                                fit: BoxFit.cover),
                          )
                        : _webImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(_webImageBytes!,
                                    fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded,
                                      size: 32, color: AppColors.primary),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to select item photo',
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
                  value: _category,
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
