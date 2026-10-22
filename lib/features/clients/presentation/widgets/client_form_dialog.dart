import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/client_model.dart';
import '../providers/client_providers.dart';

class ClientFormDialog extends ConsumerStatefulWidget {
  const ClientFormDialog({super.key, this.client, this.existingClients = const []});

  final ClientModel? client;

  /// Clients actifs, pour empêcher les doublons de nom
  final List<ClientModel> existingClients;

  @override
  ConsumerState<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends ConsumerState<ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  bool get isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _codeController = TextEditingController(text: widget.client?.code ?? '');
    _descriptionController =
        TextEditingController(text: widget.client?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(clientRepositoryProvider);
      final name = _nameController.text.trim();
      final code = _nullIfEmpty(_codeController.text)?.toUpperCase();
      final description = _nullIfEmpty(_descriptionController.text);

      if (isEditing) {
        await repository.updateClient(ClientModel(
          id: widget.client!.id,
          name: name,
          code: code,
          description: description,
          createdAt: widget.client!.createdAt,
          createdBy: widget.client!.createdBy,
        ));
      } else {
        final currentUser = ref.read(authControllerProvider).valueOrNull;
        await repository.createClient(ClientModel(
          id: '',
          name: name,
          code: code,
          description: description,
          createdAt: DateTime.now(),
          createdBy: currentUser?.id ?? '',
        ));
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('common.error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(isEditing
          ? l10n.translate('clients.editClient')
          : l10n.translate('clients.createClient')),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.translate('clients.name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) {
                    return l10n.translate('clients.nameRequired');
                  }
                  final duplicate = widget.existingClients.any((c) =>
                      c.id != widget.client?.id &&
                      c.name.toLowerCase() == name.toLowerCase());
                  if (duplicate) {
                    return l10n.translate('clients.nameAlreadyExists');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.translate('clients.code'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.translate('clients.description'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
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
