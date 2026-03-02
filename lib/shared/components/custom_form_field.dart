// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:superdriver_admin/shared/components/custom_text.dart';
import 'package:superdriver_admin/shared/themes/colors_custom.dart';

class FormFieldCustom extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? label;
  final String? prefixText;
  final bool isPassword;
  final bool isRequired;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const FormFieldCustom({
    super.key,
    this.controller,
    this.hintText,
    this.label,
    this.prefixText,
    this.isPassword = false,
    this.isRequired = true,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  State<FormFieldCustom> createState() => _FormFieldCustomState();
}

class _FormFieldCustomState extends State<FormFieldCustom> {
  bool _obscureText = true;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  bool _isArabic(String? text) {
    if (text == null || text.isEmpty) return false;
    return text.contains(RegExp(r'[\u0600-\u06FF]'));
  }

  TextStyle _textStyle({
    required double fontSize,
    Color? color,
    FontWeight? weight,
  }) {
    final isArabic = _isArabic(widget.hintText ?? widget.label ?? '');
    return isArabic
        ? GoogleFonts.notoSansArabic(
            fontSize: fontSize,
            fontWeight: weight ?? FontWeight.w500,
            color: color ?? ColorsCustom.textPrimary,
            height: 1.6,
            letterSpacing: 0,
          )
        : GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: weight ?? FontWeight.w500,
            color: color ?? ColorsCustom.textPrimary,
            height: 1.6,
            letterSpacing: 0,
          );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRtl = _isArabic(widget.label ?? widget.hintText ?? '');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: widget.label != null
              ? const EdgeInsets.only(top: 8)
              : EdgeInsets.zero,
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textAlignVertical: TextAlignVertical.center,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            style: _textStyle(
              fontSize: 15,
              color: widget.enabled
                  ? ColorsCustom.textPrimary
                  : ColorsCustom.textHint,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.enabled
                  ? ColorsCustom.surface
                  : ColorsCustom.surfaceVariant,
              hintText: widget.hintText,
              hintStyle: _textStyle(
                fontSize: 15,
                color: ColorsCustom.textHint,
                weight: FontWeight.w400,
              ),
              prefixText: widget.prefixText,
              prefixStyle: _textStyle(
                fontSize: 15,
                color: ColorsCustom.textSecondary,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: _buildSuffixIcon(),
              isDense: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: _buildBorder(ColorsCustom.border),
              enabledBorder: _buildBorder(ColorsCustom.border),
              focusedBorder: _buildBorder(ColorsCustom.primary, width: 1.5),
              errorBorder: _buildBorder(ColorsCustom.error),
              focusedErrorBorder: _buildBorder(ColorsCustom.error, width: 1.5),
              disabledBorder: _buildBorder(ColorsCustom.border, width: 0.5),
              errorStyle: _textStyle(
                fontSize: 13,
                color: ColorsCustom.error,
                weight: FontWeight.w400,
              ),
              counterStyle: _textStyle(
                fontSize: 12,
                color: ColorsCustom.textHint,
                weight: FontWeight.w400,
              ),
            ),
            cursorColor: ColorsCustom.primary,
          ),
        ),
        if (widget.label != null)
          Positioned(
            top: 0,
            right: isRtl ? 12 : null,
            left: isRtl ? null : 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              color: ColorsCustom.surface,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextCustom(
                    text: widget.label!,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorsCustom.textPrimary,
                  ),
                  if (widget.isRequired) ...[
                    const SizedBox(width: 4),
                    const TextCustom(
                      text: '*',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorsCustom.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: ColorsCustom.textHint,
          size: 22,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    return widget.suffixIcon;
  }
}

class PhoneFieldCustom extends StatefulWidget {
  final String label;
  final bool isRequired;
  final String initialCountryCode;
  final String hintText;
  final ValueChanged<PhoneNumber>? onChanged;
  final String? errorText;

  const PhoneFieldCustom({
    super.key,
    required this.label,
    this.isRequired = true,
    this.initialCountryCode = 'SY',
    this.hintText = '9XX XXX XXX',
    this.onChanged,
    this.errorText,
  });

  @override
  State<PhoneFieldCustom> createState() => _PhoneFieldCustomState();
}

class _PhoneFieldCustomState extends State<PhoneFieldCustom> {
  bool _isFocused = false;

  TextStyle _textStyle({
    double fontSize = 15,
    Color? color,
    FontWeight? weight,
  }) {
    return GoogleFonts.notoSansArabic(
      fontSize: fontSize,
      fontWeight: weight ?? FontWeight.w500,
      color: color ?? ColorsCustom.textPrimary,
      height: 1.6,
      letterSpacing: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
    final bool hasError = widget.errorText != null;
    final Color borderColor = hasError
        ? ColorsCustom.error
        : _isFocused
        ? ColorsCustom.primary
        : ColorsCustom.border;
    final double borderWidth = hasError || _isFocused ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Focus(
              onFocusChange: (hasFocus) {
                setState(() => _isFocused = hasFocus);
              },
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: ColorsCustom.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                  child: IntlPhoneField(
                    initialCountryCode: widget.initialCountryCode,
                    languageCode: Localizations.localeOf(context).languageCode,
                    disableLengthCheck: true,
                    autovalidateMode: AutovalidateMode.disabled,
                    showCountryFlag: true,
                    showDropdownIcon: false,
                    flagsButtonPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: _textStyle(
                        fontSize: 15,
                        color: ColorsCustom.textHint,
                        weight: FontWeight.normal,
                      ),
                      filled: false,
                      isDense: false,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: widget.onChanged,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: isAr ? 12 : null,
              left: isAr ? null : 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                color: ColorsCustom.surface,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextCustom(
                      text: widget.label,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorsCustom.textPrimary,
                    ),
                    if (widget.isRequired) ...[
                      const SizedBox(width: 4),
                      const TextCustom(
                        text: '*',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ColorsCustom.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: isAr ? 0 : 16, right: isAr ? 16 : 0),
            child: TextCustom(
              text: widget.errorText!,
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: ColorsCustom.error,
            ),
          ),
        ],
      ],
    );
  }
}
