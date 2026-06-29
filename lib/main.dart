import 'package:flutter/material.dart';
import 'widgets/reusable_data_table.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reusable Data Table Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Reusable Data Table'),
    );
  }
}

class DemoItem {
  final int id;
  final String name;
  final String category;
  final String status;
  final String updated;
  final String owner;
  final String region;
  final String priority;
  final String department;
  final String details;

  DemoItem({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.updated,
    required this.owner,
    required this.region,
    required this.priority,
    required this.department,
    required this.details,
  });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final List<DemoItem> _allItems = List.generate(
    120,
    (index) => DemoItem(
      id: index + 1,
      name: 'Item ${index + 1}',
      category: index % 3 == 0
          ? 'Finance'
          : index % 3 == 1
          ? 'Health'
          : 'Tech',
      status: index % 2 == 0 ? 'Active' : 'Paused',
      updated: '2026-06-${(index % 30) + 1}',
      owner: index % 4 == 0
          ? 'Team A'
          : index % 4 == 1
          ? 'Team B'
          : 'Team C',
      region: index % 3 == 0
          ? 'US'
          : index % 3 == 1
          ? 'EU'
          : 'APAC',
      priority: index % 3 == 0
          ? 'High'
          : index % 3 == 1
          ? 'Medium'
          : 'Low',
      department: index % 2 == 0 ? 'Sales' : 'Support',
      details: 'This is the expanded detail for item ${index + 1}.',
    ),
  );

  Future<PaginatedData<DemoItem>> _fetchPage(
    int page,
    int pageSize,
    String search,
    String filter,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedSearch = search.trim().toLowerCase();
    final filtered = _allItems.where((item) {
      final matchesSearch =
          normalizedSearch.isEmpty ||
          item.name.toLowerCase().contains(normalizedSearch) ||
          item.category.toLowerCase().contains(normalizedSearch) ||
          item.status.toLowerCase().contains(normalizedSearch);
      final matchesFilter =
          filter.isEmpty || item.category == filter || item.status == filter;
      return matchesSearch && matchesFilter;
    }).toList();

    final total = filtered.length;
    final start = (page - 1) * pageSize;
    final pageItems = filtered.skip(start).take(pageSize).toList();

    return PaginatedData(
      items: pageItems,
      totalItems: total,
      hasMore: start + pageSize < total,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ReusableDataTable<DemoItem>(
        pageFetcher: _fetchPage,
        columnHeaders: const [
          'Name',
          'Category',
          'Status',
          'Updated',
          'Owner',
          'Region',
          'Priority',
          'Department',
        ],
        filters: const ['', 'Finance', 'Health', 'Tech', 'Active', 'Paused'],
        searchHint: 'Search name, category or status',
        initialPageSize: 10,
        columnWidths: const [200, 140, 110, 140, 140, 120, 110, 140],
        tableHeight: 420,
        rowBuilder: (item, isExpanded) {
          return [
            Text(item.name),
            Text(item.category),
            Text(item.status),
            Text(item.updated),
            Text(item.owner),
            Text(item.region),
            Text(item.priority),
            Text(item.department),
          ];
        },
        expandedBuilder: (item) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID: ${item.id}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(item.details),
            ],
          );
        },
      ),
    );
  }
}
