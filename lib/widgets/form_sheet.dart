import 'package:flutter/material.dart';

/// Shared padding for keyboard-aware form bottom sheets.
class FormSheet extends StatelessWidget {
  const FormSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}
