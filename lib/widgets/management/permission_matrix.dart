import 'package:flutter/material.dart';

class PermissionMatrix extends StatefulWidget {
  final Map<String, Map<String, bool>> permissions;
  final Function(String, String, bool) onPermissionChanged;

  const PermissionMatrix({
    super.key,
    required this.permissions,
    required this.onPermissionChanged,
  });

  @override
  State<PermissionMatrix> createState() => _PermissionMatrixState();
}

class _PermissionMatrixState extends State<PermissionMatrix> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Permissão')),
          ...widget.permissions.keys.map((role) => DataColumn(label: Text(role))),
        ],
        rows: _buildRows(),
      ),
    );
  }

  List<DataRow> _buildRows() {
    final List<String> allPermissions = _getAllUniquePermissions();
    return allPermissions.map((permission) {
      return DataRow(
        cells: [
          DataCell(Text(permission)),
          ...widget.permissions.keys.map((role) {
            final bool hasPermission = widget.permissions[role]![permission] ?? false;
            return DataCell(
              Checkbox(
                value: hasPermission,
                onChanged: (bool? newValue) {
                  if (newValue != null) {
                    widget.onPermissionChanged(role, permission, newValue);
                  }
                },
              ),
            );
          }),
        ],
      );
    }).toList();
  }

  List<String> _getAllUniquePermissions() {
    final Set<String> uniquePermissions = {};
    widget.permissions.values.forEach((rolePermissions) {
      uniquePermissions.addAll(rolePermissions.keys);
    });
    return uniquePermissions.toList()..sort();
  }
}


