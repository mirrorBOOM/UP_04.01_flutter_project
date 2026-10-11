import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final String Function(T item) idOf;
  final Set<String> selected;
  final ValueChanged<String>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: DataTable(
                  columnSpacing: 32,
                  horizontalMargin: 20,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  sortColumnIndex: sortField == null
                      ? null
                      : columns.indexWhere((c) => c.sortField == sortField).clamp(0, columns.length - 1),
                  sortAscending: sortAscending,
                  columns: [
                    if (onToggleSelect != null) const DataColumn(label: Text('')),
                    ...columns.map((c) => DataColumn(
                          label: Text(
                            c.label,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          numeric: c.numeric,
                          onSort: c.sortField != null && onSort != null
                              ? (_, __) => onSort!(c.sortField!)
                              : null,
                        )),
                    if (actions != null)
                      const DataColumn(
                        label: Text('Действия', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                  ],
                  rows: items.map((item) {
                    final id = idOf(item);
                    final isChecked = selected.contains(id);

                    return DataRow(
                      selected: isChecked,
                      cells: [
                        if (onToggleSelect != null)
                          DataCell(Checkbox(
                            value: isChecked,
                            onChanged: (_) => onToggleSelect!(id),
                          )),
                        ...columns.map((c) => DataCell(c.build(item))),
                        if (actions != null)
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: actions!(item))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}