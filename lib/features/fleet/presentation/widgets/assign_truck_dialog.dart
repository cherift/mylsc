import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../providers/fleet_providers.dart';

class AssignTruckDialog extends ConsumerStatefulWidget {
  const AssignTruckDialog({required this.fleetId, super.key});

  final String fleetId;

  @override
  ConsumerState<AssignTruckDialog> createState() => _AssignTruckDialogState();
}

class _AssignTruckDialogState extends ConsumerState<AssignTruckDialog> {
  String? _selectedTruckId;
  String? _selectedTruckName;
  bool _isLoading = false;

  List<TruckModel> _getUnassignedTrucks(List<TruckModel> trucks) {
    return trucks.where((t) => t.fleetId == null && t.isActive).toList();
  }

  Future<void> _submit() async {
    if (_selectedTruckId == null) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(fleetRepositoryProvider);
      await repository.assignTruckToFleet(_selectedTruckId!, widget.fleetId);
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
    final trucksAsync = ref.watch(trucksStreamProvider);

    return AlertDialog(
      title: Text(l10n.translate('fleet.assignTruck')),
      content: SizedBox(
        width: 400,
        child: trucksAsync.when(
          data: (trucks) {
            final available = _getUnassignedTrucks(trucks);
            if (available.isEmpty) {
              return Text(l10n.translate('fleet.noAvailableTrucks'));
            }
            return InkWell(
              onTap: () async {
                final result = await showDialog<TruckModel>(
                  context: context,
                  builder: (context) =>
                      _TruckSearchDialog(trucks: available),
                );
                if (result != null) {
                  setState(() {
                    _selectedTruckId = result.id;
                    _selectedTruckName = result.displayName;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.translate('fleet.selectTruck'),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.search),
                ),
                child: Text(
                  _selectedTruckName ??
                      l10n.translate('fleet.selectTruck'),
                  style: TextStyle(
                    color: _selectedTruckName != null
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
          onPressed: _isLoading || _selectedTruckId == null ? null : _submit,
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

class _TruckSearchDialog extends StatefulWidget {
  const _TruckSearchDialog({required this.trucks});

  final List<TruckModel> trucks;

  @override
  State<_TruckSearchDialog> createState() => _TruckSearchDialogState();
}

class _TruckSearchDialogState extends State<_TruckSearchDialog> {
  final _searchController = TextEditingController();
  List<TruckModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.trucks;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = widget.trucks
          .where((t) =>
              t.immatriculation.toLowerCase().contains(q) ||
              t.displayName.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.translate('fleet.selectTruck')),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.translate('fleet.searchTruck'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(l10n.translate('fleet.noAvailableTrucks')),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final t = _filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(t.immatriculation.isNotEmpty
                                ? t.immatriculation[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(
                            t.immatriculation,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            t.shortName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(context).pop(t),
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
