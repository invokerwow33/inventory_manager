import 'package:flutter/material.dart';
import '../database/simple_database_helper.dart';

/// Панель фильтров для отчетов с возможностью фильтрации по категориям,
/// статусам, диапазону дат и поисковому запросу.
class FilterPanel extends StatefulWidget {
  final Function(FilterCriteria) onApplyFilters;
  final VoidCallback onResetFilters;
  final VoidCallback onExportCsv;
  final VoidCallback onExportExcel;
  final bool isLoading;

  const FilterPanel({
    super.key,
    required this.onApplyFilters,
    required this.onResetFilters,
    required this.onExportCsv,
    required this.onExportExcel,
    this.isLoading = false,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class FilterCriteria {
  final String? category;
  final List<String> statuses;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String searchQuery;

  const FilterCriteria({
    this.category,
    this.statuses = const [],
    this.dateFrom,
    this.dateTo,
    this.searchQuery = '',
  });

  bool get isEmpty =>
      (category == null || category == 'Все категории') &&
      statuses.isEmpty &&
      dateFrom == null &&
      dateTo == null &&
      searchQuery.isEmpty;
}

class _FilterPanelState extends State<FilterPanel> {
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  
  List<String> _categories = [];
  String? _selectedCategory;
  final List<String> _selectedStatuses = [];
  DateTime? _dateFrom;
  DateTime? _dateTo;
  
  bool _isLoadingCategories = true;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'В использовании', 'label': 'В использовании', 'color': Colors.green},
    {'value': 'На складе', 'label': 'На складе', 'color': Colors.blue},
    {'value': 'В ремонте', 'label': 'В ремонте', 'color': Colors.orange},
    {'value': 'Списано', 'label': 'Списано', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      await _dbHelper.initDatabase();
      final categories = await _dbHelper.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  void _applyFilters() {
    widget.onApplyFilters(FilterCriteria(
      category: _selectedCategory,
      statuses: List.from(_selectedStatuses),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      searchQuery: _searchController.text.trim(),
    ));
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedStatuses.clear();
      _dateFrom = null;
      _dateTo = null;
      _searchController.clear();
    });
    widget.onResetFilters();
  }

  Future<void> _selectDateFrom() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Дата от',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
      locale: const Locale('ru', 'RU'),
    );
    
    if (date != null) {
      setState(() => _dateFrom = date);
    }
  }

  Future<void> _selectDateTo() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Дата до',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
      locale: const Locale('ru', 'RU'),
    );
    
    if (date != null) {
      setState(() => _dateTo = date);
    }
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(Icons.filter_list, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Фильтры',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Фильтры - адаптивный layout
            isDesktop ? _buildDesktopFilters() : _buildMobileFilters(),
            
            const SizedBox(height: 16),
            const Divider(height: 24),
            
            // Кнопки действий
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: widget.isLoading ? null : _applyFilters,
                  icon: widget.isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Применить'),
                ),
                OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Сбросить'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: widget.isLoading ? null : widget.onExportCsv,
                  icon: const Icon(Icons.description, size: 18, color: Colors.green),
                  label: const Text('Экспорт CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.isLoading ? null : widget.onExportExcel,
                  icon: const Icon(Icons.table_chart, size: 18, color: Colors.blue),
                  label: const Text('Экспорт Excel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Первая строка: Категория и Поиск
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildCategoryDropdown(),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _buildSearchField(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Вторая строка: Статусы
        _buildStatusChips(),
        const SizedBox(height: 16),
        
        // Третья строка: Диапазон дат
        _buildDateRange(),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryDropdown(),
        const SizedBox(height: 16),
        _buildSearchField(),
        const SizedBox(height: 16),
        _buildStatusChips(),
        const SizedBox(height: 16),
        _buildDateRange(),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String?>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Категория',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      hint: const Text('Все категории'),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Все категории'),
        ),
        ..._categories.map((category) => DropdownMenuItem<String?>(
          value: category,
          child: Text(category),
        )),
      ],
      onChanged: _isLoadingCategories 
          ? null 
          : (value) => setState(() => _selectedCategory = value),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Поиск',
        hintText: 'Название, инв. или серийный номер',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => setState(() => _searchController.clear()),
              )
            : null,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildStatusChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статусы',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _statusOptions.map((status) {
            final isSelected = _selectedStatuses.contains(status['value']);
            return FilterChip(
              label: Text(status['label']),
              selected: isSelected,
              onSelected: (_) => _toggleStatus(status['value']),
              selectedColor: (status['color'] as Color).withOpacity(0.2),
              checkmarkColor: status['color'] as Color,
              labelStyle: TextStyle(
                color: isSelected ? status['color'] as Color : null,
                fontWeight: isSelected ? FontWeight.w500 : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Диапазон дат создания',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDateFrom,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _dateFrom != null ? 'От: ${_formatDate(_dateFrom)}' : 'Дата от',
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDateTo,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _dateTo != null ? 'До: ${_formatDate(_dateTo)}' : 'Дата до',
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            if (_dateFrom != null || _dateTo != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() {
                  _dateFrom = null;
                  _dateTo = null;
                }),
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Очистить даты',
              ),
            ],
          ],
        ),
      ],
    );
  }
}
