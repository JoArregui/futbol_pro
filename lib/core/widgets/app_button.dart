import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Botón principal píldora con gradiente lima + sombra neón.
/// Sustituye a todos los Elevated/Filled dispersos por un estándar.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final AppButtonVariant variant;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.variant = AppButtonVariant.primary,
    this.height = 54,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.height = 54,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = false,
    this.height = 48,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.height = 54,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    Widget btn;
    switch (variant) {
      case AppButtonVariant.primary:
        btn = _GradientPill(
          onPressed: loading ? null : onPressed,
          height: height,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.black),
            child: IconTheme.merge(
              data: const IconThemeData(color: Colors.black),
              child: child,
            ),
          ),
        );
        break;
      case AppButtonVariant.secondary:
        btn = SizedBox(
          height: height,
          child: OutlinedButton(
            onPressed: loading ? null : onPressed,
            child: child,
          ),
        );
        break;
      case AppButtonVariant.danger:
        btn = SizedBox(
          height: height,
          child: FilledButton(
            onPressed: loading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: child,
          ),
        );
        break;
      case AppButtonVariant.ghost:
        btn = TextButton(onPressed: onPressed, child: child);
        break;
    }
    if (!expanded) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }
}

enum AppButtonVariant { primary, secondary, danger, ghost }

class _GradientPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double height;
  const _GradientPill(
      {required this.child, this.onPressed, this.height = 54});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: disabled ? null : AppColors.gradientLime,
          color: disabled ? Colors.grey.shade700 : null,
          borderRadius: BorderRadius.circular(28),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.lime.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: Center(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            )),
          ),
        ),
      ),
    );
  }
}
