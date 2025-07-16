import 'package:flutter/material.dart';

enum OrganizationType {
  federation,
  clan,
}

class OrganizationSelector extends StatelessWidget {
  final OrganizationType selectedType;
  final Function(OrganizationType) onTypeSelected;
  final List<String> availableOrganizations;
  final String? selectedOrganizationId;
  final Function(String?) onOrganizationSelected;

  const OrganizationSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.availableOrganizations,
    required this.selectedOrganizationId,
    required this.onOrganizationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<OrganizationType>(
                title: const Text('Federação'),
                value: OrganizationType.federation,
                groupValue: selectedType,
                onChanged: (OrganizationType? value) {
                  if (value != null) onTypeSelected(value);
                },
              ),
            ),
            Expanded(
              child: RadioListTile<OrganizationType>(
                title: const Text('Clã'),
                value: OrganizationType.clan,
                groupValue: selectedType,
                onChanged: (OrganizationType? value) {
                  if (value != null) onTypeSelected(value);
                },
              ),
            ),
          ],
        ),
        DropdownButton<String>(
          value: selectedOrganizationId,
          hint: const Text('Selecione uma organização'),
          onChanged: onOrganizationSelected,
          items: availableOrganizations.map((String orgId) {
            return DropdownMenuItem<String>(
              value: orgId,
              child: Text(orgId), // ideally, display organization name
            );
          }).toList(),
        ),
      ],
    );
  }
}


