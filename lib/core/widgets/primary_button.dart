import 'package:flutter/material.dart';

/// Full-width filled button with an optional icon and loading state.
/// Pass `onPressed: null` to disable it.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    // AbsorbPointer keeps the enabled colors while loading but blocks taps.
    return AbsorbPointer(
      absorbing: isLoading,
      child: FilledButton(
        onPressed: onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: onPrimary),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  ],
                ),
        ),
      ),
    );
  }
}
