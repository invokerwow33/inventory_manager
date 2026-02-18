import 'package:flutter/material.dart';
import '../../utils/validators.dart';

class ValidationTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final int maxLines;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;

  const ValidationTextField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
  });

  factory ValidationTextField.email({
    Key? key,
    String label = 'Email',
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
    bool enabled = true,
    bool required = false,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    FocusNode? focusNode,
  }) {
    return ValidationTextField(
      key: key,
      label: label,
      hint: hint,
      initialValue: initialValue,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: const Icon(Icons.email_outlined),
      validator: (value) {
        if (required) {
          final requiredResult = Validators.required(value, fieldName: label);
          if (!requiredResult.isValid) return requiredResult.errorMessage;
        }
        return Validators.emailField(value);
      },
      onSaved: onSaved,
      onChanged: onChanged,
      enabled: enabled,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
    );
  }

  factory ValidationTextField.phone({
    Key? key,
    String label = 'Телефон',
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
    bool enabled = true,
    bool required = false,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    FocusNode? focusNode,
  }) {
    return ValidationTextField(
      key: key,
      label: label,
      hint: hint ?? '+7 (___) ___-__-__',
      initialValue: initialValue,
      controller: controller,
      keyboardType: TextInputType.phone,
      prefixIcon: const Icon(Icons.phone_outlined),
      validator: (value) {
        if (required) {
          final requiredResult = Validators.required(value, fieldName: label);
          if (!requiredResult.isValid) return requiredResult.errorMessage;
        }
        return Validators.phoneField(value);
      },
      onSaved: onSaved,
      onChanged: onChanged,
      enabled: enabled,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
    );
  }

  factory ValidationTextField.number({
    Key? key,
    required String label,
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
    bool enabled = true,
    bool required = false,
    bool positiveOnly = false,
    String fieldName = 'Поле',
    Widget? prefixIcon,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    FocusNode? focusNode,
  }) {
    return ValidationTextField(
      key: key,
      label: label,
      hint: hint,
      initialValue: initialValue,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: prefixIcon ?? const Icon(Icons.numbers_outlined),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return '$fieldName обязательно для заполнения';
        }
        if (positiveOnly) {
          return Validators.positiveNumber(value, fieldName: fieldName) == 
              const ValidationResult.valid() ? null : 
              '$fieldName должно быть положительным числом';
        }
        return Validators.numeric(value, fieldName: fieldName) == 
            const ValidationResult.valid() ? null : 
            '$fieldName должно быть числом';
      },
      onSaved: onSaved,
      onChanged: onChanged,
      enabled: enabled,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
    );
  }

  factory ValidationTextField.required({
    Key? key,
    required String label,
    String? hint,
    String? initialValue,
    TextEditingController? controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
    bool enabled = true,
    int minLength = 1,
    int? maxLength,
    Widget? prefixIcon,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    FocusNode? focusNode,
  }) {
    return ValidationTextField(
      key: key,
      label: '$label *',
      hint: hint,
      initialValue: initialValue,
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon,
      validator: (value) {
        final result = Validators.required(value, fieldName: label);
        if (!result.isValid) return result.errorMessage;
        
        if (minLength > 1) {
          final minResult = Validators.minLength(value, minLength, fieldName: label);
          if (!minResult.isValid) return minResult.errorMessage;
        }
        
        if (maxLength != null) {
          final maxResult = Validators.maxLength(value, maxLength, fieldName: label);
          if (!maxResult.isValid) return maxResult.errorMessage;
        }
        
        return null;
      },
      onSaved: onSaved,
      onChanged: onChanged,
      enabled: enabled,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: !enabled,
          fillColor: enabled ? null : theme.colorScheme.surfaceContainerHighest,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onSaved: onSaved,
        onChanged: onChanged,
        enabled: enabled,
        autofocus: autofocus,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        focusNode: focusNode,
      ),
    );
  }
}
