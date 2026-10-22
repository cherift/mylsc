import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/fuel_supply_providers.dart';

String formatLiters(double liters) =>
    '${NumberFormat('#,##0.0', 'fr_FR').format(liters)} L';

/// Litrage encore demandable (stock − demandes en attente), null si inconnu.
/// Lecture ponctuelle (validateurs) : [FuelStockHint] maintient le flux actif.
double? availableForRequest(WidgetRef ref) {
  final stock = ref.read(fuelStockProvider).valueOrNull;
  if (stock == null) return null;
  final available = stock.availableForRequest;
  return available < 0 ? 0 : available;
}

/// Validateur du litrage demandé : ne peut dépasser le stock disponible
String? validateRequestedAgainstStock(
    AppLocalizations l10n, double liters, double? available) {
  if (available == null) return null; // stock pas encore chargé
  if (liters > available + 0.001) {
    return l10n
        .translate('fuelStock.exceedsAvailable')
        .replaceAll('{available}', formatLiters(available));
  }
  return null;
}

/// Message d'erreur lisible pour un dépassement de stock
String fuelStockErrorMessage(
    AppLocalizations l10n, InsufficientFuelStockException e,
    {bool serving = false}) {
  return l10n
      .translate(serving
          ? 'fuelStock.insufficientForServing'
          : 'fuelStock.insufficientForRequest')
      .replaceAll('{available}', formatLiters(e.available))
      .replaceAll('{requested}', formatLiters(e.requested));
}

/// Indication du litrage encore demandable, sous le champ « litres »
class FuelStockHint extends ConsumerWidget {
  const FuelStockHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stock = ref.watch(fuelStockProvider).valueOrNull;
    if (stock == null) return const SizedBox.shrink();

    final available =
        stock.availableForRequest < 0 ? 0.0 : stock.availableForRequest;
    final color = available > 0 ? AppColors.info : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.gas_station, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n
                  .translate('fuelStock.availableHint')
                  .replaceAll('{available}', formatLiters(available))
                  .replaceAll('{reserved}', formatLiters(stock.totalReserved)),
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
