import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AppImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String category;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.category = 'General',
  });

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('phone') || cat.contains('electro') || cat.contains('charger')) {
      return Icons.devices_other_rounded;
    } else if (cat.contains('card') || cat.contains('id')) {
      return Icons.badge_rounded;
    } else if (cat.contains('key')) {
      return Icons.vpn_key_rounded;
    } else if (cat.contains('wallet')) {
      return Icons.account_balance_wallet_rounded;
    } else if (cat.contains('bag') || cat.contains('pack')) {
      return Icons.backpack_rounded;
    }
    return Icons.shopping_bag_rounded;
  }

  LinearGradient _getCategoryGradient(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('phone') || cat.contains('electro')) {
      return const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]);
    } else if (cat.contains('card') || cat.contains('id')) {
      return const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)]);
    } else if (cat.contains('key')) {
      return const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]);
    } else if (cat.contains('wallet')) {
      return const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]);
    }
    return const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]);
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: _getCategoryGradient(category),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: width != null ? (width! * 0.4).clamp(24.0, 56.0) : 36.0,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    Widget imageWidget;

    if (url == null || url.isEmpty) {
      imageWidget = _buildFallback();
    } else if (url.startsWith('data:image/') || (url.length > 100 && !url.startsWith('http'))) {
      // Base64 Data URL or Raw Base64 string
      try {
        final base64Str = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(base64Str.replaceAll(RegExp(r'\s+'), ''));
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } catch (_) {
        imageWidget = _buildFallback();
      }
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.surfaceElevated,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else if (!kIsWeb && (url.startsWith('/') || url.contains(':\\') || url.startsWith('file://'))) {
      imageWidget = Image.file(
        File(url.replaceFirst('file://', '')),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      imageWidget = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
