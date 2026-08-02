import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../users/presentation/providers/user_management_providers.dart';
import '../providers/fleet_providers.dart';

class AssignDriverDialog extends ConsumerStatefulWidget {
  const AssignDriverDialog({required this.fleetId, super.key});

  final String fleetId;

  @override
  ConsumerState<AssignDriverDialog> createState() => _AssignDriverDialogState();
}

class _AssignDriverDialogState extends ConsumerState<AssignDriverDialog> {
  String? _selectedDriverId;
  String? _selectedDriverName;
  bool _isLoading = false;

  List<UserModel> _getUnassignedDrivers(List<UserModel> users) {
    return users
        .where((u) =>
            u.role?.toLowerCase().replaceAll(' ', '') == 'chauffeur' &&
            u.isActive &&
            u.fleetId == null)
        .toList();
  }

  Future<void> _submit() async {
    if (_selectedDriverId == null) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(fleetRepositoryProvider);
      await repository.assignDriverToFleet(_selectedDriverId!, widget.fleetId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final usersAsync = ref.watch(usersStreamProvider);

    return AlertDialog(
      title: Text(l10n.translate('fleet.assignDriver')),
      content: SizedBox(
        width: 400,
        child: usersAsync.when(
          data: (users) {
            final available = _getUnassignedDrivers(users);
            if (available.isEmpty) {
              return Text(l10n.translate('fleet.noAvailableDrivers'));
            }
            return InkWell(
              onTap: () async {
                final result = await showDialog<UserModel>(
                  context: context,
                  builder: (context) =>
                      _DriverSearchDialog(drivers: available),
                );
                if (result != null) {
                  setState(() {
                    _selectedDriverId = result.id;
                    _selectedDriverName = result.fullName.isNotEmpty
                        ? result.fullName
                        : result.email;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.translate('fleet.selectDriver'),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.search),
                ),
                child: Text(
                  _selectedDriverName ??
                      l10n.translate('fleet.selectDriver'),
                  style: TextStyle(
                    color: _selectedDriverName != null
                        ? null
                        : Theme.of(context).hintColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erreur: $e'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.translate('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedDriverId == null ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.translate('fleet.assign')),
        ),
      ],
    );
  }
}

class _DriverSearchDialog extends StatefulWidget {
  const _DriverSearchDialog({required this.drivers});

  final List<UserModel> drivers;

  @override
  State<_DriverSearchDialog> createState() => _DriverSearchDialogState();
}

class _DriverSearchDialogState extends State<_DriverSearchDialog> {
  final _searchController = TextEditingController();
  List<UserModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.drivers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = widget.drivers
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.translate('fleet.selectDriver')),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.translate('fleet.searchDriver'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(l10n.translate('fleet.noAvailableDrivers')),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final u = _filtered[index];
                        final name =
                            u.fullName.isNotEmpty ? u.fullName : u.email;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(name[0].toUpperCase()),
                          ),
                          title: Text(name),
                          subtitle: Text(u.email),
                          onTap: () => Navigator.of(context).pop(u),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('common.cancel')),
        ),
      ],
    );
  }
}
