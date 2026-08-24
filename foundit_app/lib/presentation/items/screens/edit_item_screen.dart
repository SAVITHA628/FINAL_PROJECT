import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/enums/item_status.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/item_model.dart';
import '../../../providers/app_providers.dart';
import '../../common/widgets/app_image.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  final String itemId;

  const EditItemScreen({super.key, required this.itemId});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;

  ItemModel? _item;
  ItemStatus _status = ItemStatus.active;
  String _category = 'Electronics';

  String? _newBase64Image;
  bool _isLoading = false;

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
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _locationCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = ref.read(itemRepositoryProvider);
      final fetched = await repo.getItemById(widget.itemId);
      if (fetched != null && mounted) {
        setState(() {
          _item = fetched;
          _titleCtrl.text = fetched.title;
          _descCtrl.text = fetched.description;
          _locationCtrl.text = fetched.location;
          _category = fetched.category;
          _status = fetched.status;
        });
      }
    });
  }

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
      final bytes = await pickedFile.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      setState(() {
        _newBase64Image = base64String;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _item == null) return;

    setState(() => _isLoading = true);
    try {
      String? updatedImageUrl = _newBase64Image ?? _item!.imageUrl;

      final updatedItem = _item!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        location: _locationCtrl.text.trim(),
        status: _status,
        imageUrl: updatedImageUrl,
      );

      await ref.read(itemRepositoryProvider).updateItem(updatedItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(activeItemsProvider);
        ref.invalidate(myReportedItemsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_item == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Edit Item')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final currentDisplayImage = _newBase64Image ?? _item!.imageUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Container with AppImage
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AppImage(
                            imageUrl: currentDisplayImage,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(16),
                            category: _category,
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_rounded,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Change Photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: _categories.contains(_category)
                      ? _category
                      : _categories.first,
                  decoration: const InputDecoration(labelText: 'Category'),
                  dropdownColor: AppColors.surface,
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),

                // Status Selector
                DropdownButtonFormField<ItemStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  dropdownColor: AppColors.surface,
                  items: ItemStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.displayName,
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
                const SizedBox(height: 28),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
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
                            'Save Changes',
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
