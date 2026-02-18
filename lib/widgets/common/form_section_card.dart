import 'package:flutter/material.dart';

class FormSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry contentPadding;

  const FormSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.padding = const EdgeInsets.only(bottom: 16),
    this.contentPadding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding,
      child: Card(
        elevation: 1,
        child: Padding(
          padding: contentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class FormActions extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final String saveLabel;
  final String? cancelLabel;
  final bool isLoading;
  final bool showCancel;

  const FormActions({
    super.key,
    required this.onSave,
    this.onCancel,
    this.saveLabel = 'Сохранить',
    this.cancelLabel,
    this.isLoading = false,
    this.showCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onSave,
          icon: isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
          label: Text(saveLabel),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        if (showCancel) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isLoading ? null : (onCancel ?? () => Navigator.pop(context)),
            icon: const Icon(Icons.close),
            label: Text(cancelLabel ?? 'Отмена'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ],
    );
  }
}

class FormDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T)? displayMapper;
  final Widget Function(T)? iconMapper;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final String? hint;

  const FormDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.displayMapper,
    this.iconMapper,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        value: value,
        hint: hint != null ? Text(hint!) : null,
        items: items.map((item) {
          final displayText = displayMapper?.call(item) ?? item.toString();
          final icon = iconMapper?.call(item);
          
          return DropdownMenuItem<T>(
            value: item,
            child: Row(
              children: [
                if (icon != null) ...[
                  icon,
                  const SizedBox(width: 8),
                ],
                Text(displayText),
              ],
            ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        validator: validator,
        isExpanded: true,
      ),
    );
  }
}

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final void Function(DateTime?) onDateSelected;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    required this.label,
    this.date,
    required this.onDateSelected,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: enabled ? () => _showDatePicker(context) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
                color: enabled ? null : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      date != null 
                          ? '${date!.day.toString().padLeft(2, '0')}.${date!.month.toString().padLeft(2, '0')}.${date!.year}'
                          : 'Выберите дату',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: date != null 
                            ? theme.colorScheme.onSurface 
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ru', 'RU'),
    );
    
    if (picked != null) {
      onDateSelected(picked);
    }
  }
}
