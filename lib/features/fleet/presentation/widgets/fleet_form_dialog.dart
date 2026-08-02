import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../users/presentation/providers/user_management_providers.dart';
import '../../domain/models/fleet_model.dart';
import '../providers/fleet_providers.dart';

class FleetFormDialog extends ConsumerStatefulWidget {
  const FleetFormDialog({super.key, this.fleet});

  final FleetModel? fleet;

  @override
  ConsumerState<FleetFormDialog> createState() => _FleetFormDialogState();
}

class _FleetFormDialogState extends ConsumerState<FleetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _selectedSupervisorId;
  bool _isLoading = false;

  bool get isEditing => widget.fleet != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fleet?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.fleet?.description ?? '');
    _selectedSupervisorId = widget.fleet?.supervisorId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<UserModel> _getSupervisors(List<UserModel> users) {
    return users
        .where((u) =>
            u.role?.toLowerCase().replaceAll(' ', '') == 'superviseurflotte' &&
            u.isActive)
        .toList();
  }

  String _formatSupervisor(UserModel user) {
    final name = user.fullName.isNotEmpty ? user.fullName : user.email;
    if (user.matricule != null && user.matricule!.isNotEmpty) {
      return '$name #${user.matricule}';
    }
    return name;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupervisorId == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(fleetRepositoryProvider);

      if (isEditing) {
        final updated = widget.fleet!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          supervisorId: _selectedSupervisorId,
        );
        await repository.updateFleet(updated);
      } else {
        final fleet = FleetModel(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          supervisorId: _selectedSupervisorId!,
          createdAt: DateTime.now(),
          createdBy: '',
        );
        await repository.createFleet(fleet);
      }

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
      title: Text(isEditing
          ? l10n.translate('fleet.editFleet')
          : l10n.translate('fleet.createFleet')),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.translate('fleet.name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.translate('fleet.nameRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.translate('fleet.description'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              usersAsync.when(
                data: (users) {
                  final supervisors = _getSupervisors(users);
                  final selectedUser = _selectedSupervisorId != null
                      ? supervisors.where((u) => u.id == _selectedSupervisorId).firstOrNull
                      : null;
                  final displayName = selectedUser != null
                      ? _formatSupervisor(selectedUser)
                      : null;

                  return FormField<String>(
                    initialValue: _selectedSupervisorId,
                    validator: (value) {
                      if (value == null) {
                        return l10n.translate('fleet.supervisorRequired');
                      }
                      return null;
                    },
                    builder: (field) {
                      return InkWell(
                        onTap: () async {
                          final result = await showDialog<UserModel>(
                            context: context,
                            builder: (context) =>
                                _SupervisorSearchDialog(supervisors: supervisors),
                          );
                          if (result != null) {
                            setState(() {
                              _selectedSupervisorId = result.id;
                            });
                            field.didChange(result.id);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.translate('fleet.supervisor'),
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                            suffixIcon: const Icon(Icons.search),
                          ),
                          child: Text(
                            displayName ??
                                l10n.translate('fleet.selectSupervisor'),
                            style: TextStyle(
                              color: displayName != null
                                  ? null
                                  : Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Erreur: $e'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.translate('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing
                  ? l10n.translate('common.save')
                  : l10n.translate('common.create')),
        ),
      ],
    );
  }
}

class _SupervisorSearchDialog extends StatefulWidget {
  const _SupervisorSearchDialog({required this.supervisors});

  final List<UserModel> supervisors;

  @override
  State<_SupervisorSearchDialog> createState() =>
      _SupervisorSearchDialogState();
}

class _SupervisorSearchDialogState extends State<_SupervisorSearchDialog> {
  final _searchController = TextEditingController();
  List<UserModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.supervisors;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = widget.supervisors
          .where((s) =>
              s.fullName.toLowerCase().contains(q) ||
              s.email.toLowerCase().contains(q) ||
              (s.matricule?.toLowerCase().contains(q) ?? false))
          .toList();
    });
  }

  String _formatSupervisor(UserModel user) {
    final name = user.fullName.isNotEmpty ? user.fullName : user.email;
    if (user.matricule != null && user.matricule!.isNotEmpty) {
      return '$name #${user.matricule}';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.translate('fleet.selectSupervisor')),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.translate('fleet.searchSupervisor'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(l10n.translate('fleet.noSupervisorFound')),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final s = _filtered[index];
                        final display = _formatSupervisor(s);
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(display[0].toUpperCase()),
                          ),
                          title: Text(display),
                          subtitle: Text(s.email),
                          onTap: () => Navigator.of(context).pop(s),
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
