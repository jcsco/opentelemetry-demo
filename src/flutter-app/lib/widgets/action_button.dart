import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ported from the react-native-app's `components/ActionButton.tsx`: a
/// one-shot action button with an optional confirmation dialog, for the
/// destructive crash/ANR triggers on the Settings screen.
class ActionButton extends StatelessWidget {
  final String label;
  final FutureOr<void> Function() onPressed;

  /// Shown in a confirmation dialog before [onPressed] runs. Omit for
  /// non-destructive actions.
  final String? confirmMessage;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.confirmMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.addToCartGreen,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _onButtonPress(context),
      child: Text(label),
    );
  }

  Future<void> _onButtonPress(BuildContext context) async {
    final message = confirmMessage;
    if (message == null) {
      await onPressed();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onPressed();
    }
  }
}
