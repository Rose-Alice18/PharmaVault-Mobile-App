import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor =
        theme.inputDecorationTheme.fillColor ??
        (theme.brightness == Brightness.dark
            ? const Color(0xFF1F2937)
            : Colors.white);
    final borderColor =
        theme.inputDecorationTheme.enabledBorder?.borderSide.color ??
        theme.dividerColor;
    final labelStyle =
        theme.inputDecorationTheme.labelStyle ??
        TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final prefixColor = theme.colorScheme.onSurfaceVariant;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      style:
          theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 15,
          ) ??
          TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: prefixColor, size: 20)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: prefixColor,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: fillColor,
        labelStyle: labelStyle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
