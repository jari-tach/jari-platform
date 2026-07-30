import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// OTP cells matching Figma `Input/OTP Final/*` (48×52, radius 8, border 2).
class SaeqOtpInput extends StatefulWidget {
  const SaeqOtpInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.enabled = true,
    this.hasError = false,
    this.semanticsLabel,
    this.onCompleted,
    this.onChanged,
  });

  final TextEditingController controller;
  final int length;
  final bool enabled;
  final bool hasError;
  final String? semanticsLabel;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  static const fieldKey = Key('saeqOtpInputField');
  static const double cellWidth = 48;
  static const double cellHeight = 52;
  static const double cellGap = 8;

  @override
  State<SaeqOtpInput> createState() => _SaeqOtpInputState();
}

class _SaeqOtpInputState extends State<SaeqOtpInput> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(() => setState(() {}));
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final text = widget.controller.text;
    widget.onChanged?.call(text);
    if (text.length == widget.length) {
      widget.onCompleted?.call(text);
    }
    setState(() {});
  }

  void _focusField() {
    if (widget.enabled) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final l10n = AppLocalizations.of(context);
    final text = widget.controller.text;
    final hasFocus = _focusNode.hasFocus;
    // Figma Final Auth OTP cells are white in light and dark.
    const cellFill = Color(0xFFFFFFFF);
    const cellText = Color(0xFF1A1C1A);

    return Semantics(
      textField: true,
      label: widget.semanticsLabel,
      enabled: widget.enabled,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: SaeqOtpInput.cellHeight,
              child: TextField(
                key: SaeqOtpInput.fieldKey,
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _focusField,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.length, (index) {
                final digit = index < text.length ? text[index] : '';
                final isActive = hasFocus && index == text.length;
                final isFilled = digit.isNotEmpty;
                final borderColor = widget.hasError
                    ? colors.error
                    : (isActive || isFilled)
                    ? colors.primary
                    : colors.border;
                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: index == widget.length - 1 ? 0 : SaeqOtpInput.cellGap,
                  ),
                  child: Semantics(
                    label: l10n.otpDigitSemantics(index + 1, widget.length),
                    value: digit.isEmpty ? null : digit,
                    child: AnimatedContainer(
                      duration: AppTheme.durationFast,
                      width: SaeqOtpInput.cellWidth,
                      height: SaeqOtpInput.cellHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cellFill,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        border: Border.all(
                          color: borderColor,
                          width: AppTheme.borderWidthMedium,
                        ),
                      ),
                      child: Text(
                        digit,
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: cellText,
                          fontSize: AppTheme.fontSizeLG,
                          fontWeight: AppTheme.fontWeightBold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
