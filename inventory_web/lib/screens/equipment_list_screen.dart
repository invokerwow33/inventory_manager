import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equipment_provider.dart';
import '../models/equipment.dart';

class EquipmentListScreen extends StatelessWidget {
  const EquipmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.equipment.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Оборудование не найдено',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте первое оборудование',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.equipment.length,
          itemBuilder: (context, index) {
            final item = provider.equipment[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.statusIcon, color: item.statusColor),
                ),
                title: Text(item.name),
                subtitle: Text('${item.serialNumber}${item.category != null ? ' • ${item.category}' : ''}'),
                trailing: Chip(
                  label: Text(
                    _getStatusName(item.status),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: item.statusColor,
                ),
                onTap: () => _showDetails(context, item),
              ),
            );
          },
        );
      },
    );
  }

  String _getStatusName(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return 'На складе';
      case EquipmentStatus.inUse:
        return 'В использовании';
      case EquipmentStatus.maintenance:
        return 'В ремонте';
      case EquipmentStatus.retired:
        return 'Списано';
    }
  }

  void _showDetails(BuildContext context, Equipment item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.statusIcon, color: item.statusColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          item.serialNumber,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildInfoRow('Статус', _getStatusName(item.status)),
              if (item.category != null) _buildInfoRow('Категория', item.category!),
              if (item.price != null) _buildInfoRow('Цена', '${item.price} ₽'),
              _buildInfoRow('Дата покупки', _formatDate(item.purchaseDate)),
              if (item.description != null) ...[
                const SizedBox(height: 16),
                Text('Описание', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(item.description!),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Edit equipment
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Изменить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _issueEquipment(context, item);
                      },
                      icon: const Icon(Icons.assignment),
                      label: const Text('Выдать'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.isAvailable ? null : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _issueEquipment(BuildContext context, Equipment item) {
    if (!item.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оборудование недоступно для выдачи')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выдать оборудование'),
        content: const Text('Выберите сотрудника...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement employee selection and issue
              Navigator.pop(context);
            },
            child: const Text('Выдать'),
          ),
        ],
      ),
    );
  }
}
