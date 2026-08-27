import 'package:flutter/material.dart';

/// Max fraction of screen height for bottom sheets and form popups.
const sheetMaxHeightFraction = 0.8;

/// Max popup height: [sheetMaxHeightFraction] of screen, reduced by the keyboard
/// so the sheet never grows past that fraction even when `viewInsets` pad the bottom.
double sheetMaxHeight(BuildContext context) {
  final media = MediaQuery.of(context);
  return (media.size.height * sheetMaxHeightFraction - media.viewInsets.bottom)
      .clamp(120.0, double.infinity);
}

/// Shared padding for keyboard-aware form bottom sheets.
class FormSheet extends StatelessWidget {
  const FormSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sheetMaxHeight(context)),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}
