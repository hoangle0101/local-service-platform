import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A collection of Modern Minimalist widgets for the Local Service Platform.
/// These widgets enforce zero elevation, large border radii, and purposeful whitespace.

class MinCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? borderRadius;
  final BorderSide? border;

  const MinCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        border: Border.all(
          color: border?.color ?? AppColors.borderLight,
          width: border?.width ?? 1,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        child: content,
      );
    }

    return child;
  }
}

class MinButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isFullWidth;
  final IconData? icon;
  final bool isLoading;

  const MinButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isFullWidth = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    final style = isPrimary
        ? ElevatedButton.styleFrom(
            minimumSize: isFullWidth ? const Size(double.infinity, 56) : null,
          )
        : OutlinedButton.styleFrom(
            minimumSize: isFullWidth ? const Size(double.infinity, 56) : null,
          );

    return isPrimary
        ? ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: style,
            child: content,
          )
        : OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: style,
            child: content,
          );
  }
}

class MinBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const MinBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor ?? AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class MinTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const MinTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
