import 'package:flutter/material.dart';

class PaginatedData<T> {
  final List<T> items;
  final int totalItems;
  final bool hasMore;

  const PaginatedData({
    required this.items,
    required this.totalItems,
    required this.hasMore,
  });
}

typedef DataPageFetcher<T> =
    Future<PaginatedData<T>> Function(
      int page,
      int pageSize,
      String search,
      String filter,
    );

typedef DataRowBuilder<T> = List<Widget> Function(T item, bool isExpanded);

typedef DataExpandedBuilder<T> = Widget Function(T item);

class ReusableDataTable<T> extends StatefulWidget {
  final DataPageFetcher<T> pageFetcher;
  final List<String> columnHeaders;
  final DataRowBuilder<T> rowBuilder;
  final DataExpandedBuilder<T> expandedBuilder;
  final List<String> filters;
  final String searchHint;
  final int initialPageSize;
  final List<double>? columnWidths;
  final double tableHeight;

  const ReusableDataTable({
    super.key,
    required this.pageFetcher,
    required this.columnHeaders,
    required this.rowBuilder,
    required this.expandedBuilder,
    required this.filters,
    this.searchHint = 'Search...',
    this.initialPageSize = 10,
    this.columnWidths,
    this.tableHeight = 340,
  });

  List<double> get effectiveColumnWidths {
    if (columnWidths != null && columnWidths!.length == columnHeaders.length) {
      return columnWidths!;
    }
    return List<double>.filled(columnHeaders.length, 180);
  }

  @override
  State<ReusableDataTable<T>> createState() => _ReusableDataTableState<T>();
}

class _ReusableDataTableState<T> extends State<ReusableDataTable<T>> {
  bool _loading = false;
  String _search = '';
  String _filter = '';
  int _page = 1;
  int _pageSize = 10;
  List<T> _items = [];
  int _totalItems = 0;
  final Set<int> _expandedIndexes = {};
  String _lastSearch = '';
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filter = widget.filters.isNotEmpty ? widget.filters.first : '';
    _pageSize = widget.initialPageSize;
    _loadPage();
  }

  Future<void> _loadPage({int? page}) async {
    final nextPage = page ?? _page;
    setState(() {
      _loading = true;
    });

    try {
      final response = await widget.pageFetcher(
        nextPage,
        _pageSize,
        _search,
        _filter,
      );
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _items = response.items;
        _totalItems = response.totalItems;
        _loading = false;
        _expandedIndexes.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadPage(page: 1);
  }

  void _applySearch(String value) {
    _lastSearch = value;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastSearch == value) {
        setState(() {
          _search = value.trim();
        });
        _loadPage(page: 1);
      }
    });
  }

  void _changeFilter(String value) {
    setState(() {
      _filter = value;
    });
    _loadPage(page: 1);
  }

  int get _lastPage {
    if (_totalItems == 0) return 1;
    return (_totalItems / _pageSize).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(context),
            const SizedBox(height: 12),
            _buildHeader(context),
            const Divider(thickness: 1.2),
            _buildBody(context),
            const SizedBox(height: 12),
            _buildPagination(context),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            onChanged: _applySearch,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildFilterMenu(context),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _loading ? null : _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildFilterMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondary.withAlpha((0.08 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: PopupMenuButton<String>(
        initialValue: _filter,
        tooltip: 'Filter',
        onSelected: _changeFilter,
        itemBuilder: (context) {
          return widget.filters
              .map(
                (option) => PopupMenuItem(value: option, child: Text(option)),
              )
              .toList();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_list),
              const SizedBox(width: 8),
              Text(_filter.isEmpty ? 'Filter' : _filter),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final widths = widget.effectiveColumnWidths;
    final totalWidth =
        widths.fold<double>(0, (sum, width) => sum + width) +
        widths.length * 24;
    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Table(
            columnWidths: {
              for (var index = 0; index < widths.length; index++)
                index: FixedColumnWidth(widths[index]),
            },
            border: TableBorder.symmetric(
              inside: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(80),
                width: 1,
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(30),
                ),
                children: widget.columnHeaders
                    .map(
                      (title) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading data...'),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No matching records found.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final widths = widget.effectiveColumnWidths;
    final totalWidth =
        widths.fold<double>(0, (sum, width) => sum + width) +
        widths.length * 24;

    final rowItems = List<Widget>.generate(_items.length, (index) {
      final item = _items[index];
      final expanded = _expandedIndexes.contains(index);
      final rowCells = widget.rowBuilder(item, expanded);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedIndexes.remove(index);
                } else {
                  _expandedIndexes.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: expanded
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((0.05 * 255).round())
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Table(
                columnWidths: {
                  for (
                    var cellIndex = 0;
                    cellIndex < widths.length;
                    cellIndex++
                  )
                    cellIndex: FixedColumnWidth(widths[cellIndex]),
                },
                children: [
                  TableRow(
                    children: rowCells
                        .map(
                          (cell) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            child: cell,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: ConstrainedBox(
              constraints: expanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: expanded
                    ? Container(
                        width: totalWidth,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: widget.expandedBuilder(item),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      );
    });

    final separatedRows = <Widget>[];
    for (var i = 0; i < rowItems.length; i++) {
      separatedRows.add(rowItems[i]);
      if (i < rowItems.length - 1) {
        separatedRows.add(const Divider(height: 1));
      }
    }

    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.tableHeight),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: separatedRows,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${_items.isEmpty ? 0 : ((_page - 1) * _pageSize + 1)} - ${(_page - 1) * _pageSize + _items.length} of $_totalItems',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Row(
          children: [
            IconButton(
              onPressed: _page > 1 && !_loading
                  ? () => _loadPage(page: _page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('$_page / $_lastPage'),
            IconButton(
              onPressed: _page < _lastPage && !_loading
                  ? () => _loadPage(page: _page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _pageSize,
              items: [5, 10, 20, 50]
                  .map(
                    (size) => DropdownMenuItem(
                      value: size,
                      child: Text('$size rows'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _pageSize = value;
                  _page = 1;
                });
                _loadPage(page: 1);
              },
            ),
          ],
        ),
      ],
    );
  }
}
