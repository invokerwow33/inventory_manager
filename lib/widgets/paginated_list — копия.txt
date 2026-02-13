import 'package:flutter/material.dart';

class PaginatedListView extends StatefulWidget {
  final Future<List<dynamic>> Function(int page, int pageSize) dataFetcher;
  final Widget Function(BuildContext, dynamic, int) itemBuilder;
  final int pageSize;
  final Widget? emptyState;
  final Widget? loadingState;
  final ScrollController? scrollController;
  final bool showLoadingIndicator;
  
  const PaginatedListView({
    super.key,
    required this.dataFetcher,
    required this.itemBuilder,
    this.pageSize = 20,
    this.emptyState,
    this.loadingState,
    this.scrollController,
    this.showLoadingIndicator = true,
  });
  
  @override
  _PaginatedListViewState createState() => _PaginatedListViewState();
}

class _PaginatedListViewState extends State<PaginatedListView> {
  List<dynamic> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _initialLoad = true;
  ScrollController? _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController?.addListener(_scrollListener);
    _loadMore();
  }
  
  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController?.dispose();
    } else {
      _scrollController?.removeListener(_scrollListener);
    }
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController!.position.pixels == 
        _scrollController!.position.maxScrollExtent) {
      _loadMore();
    }
  }
  
  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newItems = await widget.dataFetcher(_currentPage, widget.pageSize);
      
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _currentPage++;
          _hasMore = newItems.length == widget.pageSize;
          _initialLoad = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _refresh() async {
    if (_isLoading) return;
    
    setState(() {
      _items = [];
      _currentPage = 0;
      _hasMore = true;
      _initialLoad = true;
    });
    await _loadMore();
  }
  
  void reset() {
    _refresh();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_initialLoad && _items.isEmpty) {
      return widget.loadingState ?? const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (!_initialLoad && _items.isEmpty) {
      return widget.emptyState ?? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет данных для отображения',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Обновить'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refresh,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _items.length + (_hasMore && widget.showLoadingIndicator ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _items.length && _hasMore && widget.showLoadingIndicator) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (index >= _items.length) {
                  return const SizedBox();
                }
                
                return widget.itemBuilder(context, _items[index], index);
              },
            ),
          ),
          
          // Статус загрузки внизу
          if (_isLoading && !widget.showLoadingIndicator)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}