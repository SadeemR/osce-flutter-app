import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  const CardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.base,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

/// Icon + title used at the top of every card.
class SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? trailing;

  const SectionLabel(
      {super.key, required this.icon, required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.text)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Small rounded tag, e.g. "DEFAULT" or "×2".
class Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const Tag({
    super.key,
    required this.text,
    this.color = AppColors.accent,
    this.background = AppColors.accentSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(100)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// Full-width coral call-to-action with press feedback and a loading state.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Pressable(
      enabled: enabled,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          child: AnimatedSwitcher(
            duration: AppMotion.base,
            switchInCurve: AppMotion.enter,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(a),
                  child: child),
            ),
            child: loading
                ? Row(
                    key: const ValueKey('loading'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.onAccent),
                      ),
                      const SizedBox(width: 12),
                      Text(loadingLabel ?? label),
                    ],
                  )
                : Row(
                    key: const ValueKey('idle'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(label),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Dashed-feel tappable tile used for "attach file" / "add rubric".
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: Material(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                trailing ??
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
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
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: AppColors.textSecondary)),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.text, fontSize: 15),
          minLines: isMultiline ? 2 : 1,
          maxLines: isMultiline ? 5 : 1,
          keyboardType: keyboardType ??
              (isMultiline ? TextInputType.multiline : TextInputType.text),
          textInputAction: textInputAction ??
              (isMultiline ? TextInputAction.newline : TextInputAction.next),
          onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
          decoration: InputDecoration(hintText: placeholder),
        ),
      ],
    );
  }
}

IconData fileIconFor(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'docx':
    case 'doc':
      return Icons.description_outlined;
    case 'xlsx':
    case 'xls':
      return Icons.table_chart_outlined;
    case 'json':
      return Icons.data_object;
    case 'csv':
      return Icons.list_alt;
    default:
      return Icons.insert_drive_file_outlined;
  }
}
