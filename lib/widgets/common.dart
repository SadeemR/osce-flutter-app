import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const CardContainer(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CaseFormField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool isMultiline;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

  const CaseFormField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.isMultiline = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.burgundy)),
        ),
        TextField(
          controller: controller,
          minLines: isMultiline ? 2 : 1,
          maxLines: isMultiline ? 5 : 1,
          keyboardType: keyboardType ??
              (isMultiline ? TextInputType.multiline : TextInputType.text),
          textInputAction: textInputAction ??
              (isMultiline ? TextInputAction.newline : TextInputAction.next),
          onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.apricot, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

IconData fileIconFor(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'docx':
    case 'doc':
      return Icons.description;
    case 'xlsx':
    case 'xls':
      return Icons.table_chart;
    case 'json':
      return Icons.data_object;
    case 'csv':
      return Icons.list_alt;
    default:
      return Icons.insert_drive_file;
  }
}