import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A consistent text field used across all forms.
///
/// Enter key navigation:
/// - Set [nextFocusNode] to move focus to the next field on Enter.
/// - Set [onSubmitted] on the LAST field to trigger form submission.
/// - Multi-line fields (maxLines > 1) always use TextInputAction.newline
///   regardless of focus chain — Flutter asserts otherwise.
class CommonTextField extends StatelessWidget {
  const CommonTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.focusNode,
    this.nextFocusNode,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.hasError = false,
    this.suffixIcon,
    this.enabled = true,
    this.autofillHints,
    this.inputFormatters,
    this.hintText,
  });

  final TextEditingController controller;
  final String labelText;
  final FocusNode? focusNode;

  /// When set, Enter moves focus to this node (single-line fields only).
  final FocusNode? nextFocusNode;

  /// Called on Enter when [nextFocusNode] is null and field is single-line.
  final VoidCallback? onSubmitted;

  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final bool hasError;
  final Widget? suffixIcon;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;

  bool get _isMultiLine => !obscureText && maxLines != 1;

  TextInputAction get _textInputAction {
    // Multi-line fields MUST use newline — Flutter asserts on any other value.
    if (_isMultiLine) {
      return TextInputAction.newline;
    }
    if (nextFocusNode != null) {
      return TextInputAction.next;
    }
    if (onSubmitted != null) {
      return TextInputAction.done;
    }
    return TextInputAction.next;
  }

  // ── FIX: Flutter's assertion requires BOTH halves to match —
  //    TextInputAction.newline is only valid when keyboardType is
  //    TextInputType.multiline (or maxLines == 1, or keyboardType != text).
  //    Forcing this automatically here means every multi-line field in the
  //    app (profile pages, job posting, etc.) gets it right without each
  //    caller having to remember to pass keyboardType explicitly.
  TextInputType get _resolvedKeyboardType {
    if (_isMultiLine) {
      return TextInputType.multiline;
    }
    return keyboardType;
  }

  void _handleSubmitted(String value) {
    // Only navigate/submit on single-line fields.
    if (_isMultiLine) {
      return;
    }
    if (nextFocusNode != null) {
      nextFocusNode!.requestFocus();
    } else {
      onSubmitted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: _resolvedKeyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      textInputAction: _textInputAction,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      onSubmitted: _handleSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        enabledBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
