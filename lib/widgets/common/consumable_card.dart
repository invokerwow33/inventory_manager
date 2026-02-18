import 'package:flutter/material.dart';
import '../../models/consumable.dart';

class ConsumableCard extends StatelessWidget {
  final Consumable consumable;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddStock;
  final VoidCallback? onRemoveStock;
  final bool showActions;
  final bool isSelected;

  const ConsumableCard({
    super.key,
    required this.consumable,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onAddStock,
    this.onRemoveStock,
    this.showActions = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = consumable.isLowStock;
    
    return Card(
      elevation: isSelected ? 2 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isSelected 
          ? theme.colorScheme.primaryContainer.withOpacity(0.3) 
          : (isLowStock ? theme.colorScheme.errorContainer.withOpacity(0.1) : null),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: consumable.category.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      consumable.category.icon,
                      color: consumable.category.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consumable.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          consumable.category.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 14,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Мало',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuantityIndicator(
                      quantity: consumable.quantity,
                      minQuantity: consumable.minQuantity,
                      unit: consumable.unit,
                      isLowStock: isLowStock,
                    ),
                  ),
                  if (showActions && (onAddStock != null || onRemoveStock != null))
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onRemoveStock != null)
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, 
                              size: 24, 
                              color: theme.colorScheme.error,
                            ),
                            onPressed: consumable.quantity > 0 ? onRemoveStock : null,
                            tooltip: 'Списать',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        if (onAddStock != null)
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, 
                              size: 24, 
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: onAddStock,
                            tooltip: 'Пополнить',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                      ],
                    ),
                ],
              ),
              if (showActions && (onEdit != null || onDelete != null)) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: onEdit,
                        tooltip: 'Редактировать',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                        onPressed: onDelete,
                        tooltip: 'Удалить',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityIndicator extends StatelessWidget {
  final double quantity;
  final double minQuantity;
  final ConsumableUnit unit;
  final bool isLowStock;

  const _QuantityIndicator({
    required this.quantity,
    required this.minQuantity,
    required this.unit,
    required this.isLowStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} ${unit.shortLabel}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLowStock ? theme.colorScheme.error : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'мин. ${minQuantity.toStringAsFixed(minQuantity.truncateToDouble() == minQuantity ? 0 : 2)} ${unit.shortLabel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: minQuantity > 0 ? (quantity / (minQuantity * 2)).clamp(0.0, 1.0) : (quantity > 0 ? 0.5 : 0),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              isLowStock ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class ConsumableListTile extends StatelessWidget {
  final Consumable consumable;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const ConsumableListTile({
    super.key,
    required this.consumable,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = consumable.isLowStock;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary 
              : consumable.category.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isSelected ? Icons.check : consumable.category.icon,
          color: isSelected 
              ? theme.colorScheme.onPrimary 
              : consumable.category.color,
        ),
      ),
      title: Text(
        consumable.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${consumable.quantity.toStringAsFixed(consumable.quantity.truncateToDouble() == consumable.quantity ? 0 : 2)} ${consumable.unit.shortLabel}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isLowStock ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isLowStock
          ? Icon(
              Icons.warning_amber,
              color: theme.colorScheme.error,
            )
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
      selected: isSelected,
    );
  }
}

class ConsumableCategoryChip extends StatelessWidget {
  final ConsumableCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const ConsumableCategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FilterChip(
      avatar: Icon(category.icon, size: 18, color: category.color),
      label: Text(category.label),
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      selectedColor: category.color.withOpacity(0.2),
      checkmarkColor: category.color,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: isSelected ? category.color : theme.colorScheme.onSurface,
      ),
    );
  }
}
