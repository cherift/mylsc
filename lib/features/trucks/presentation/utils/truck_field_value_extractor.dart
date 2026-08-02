import 'package:intl/intl.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../domain/models/truck_model.dart';

/// Helper pour extraire les valeurs des champs d'un camion
class TruckFieldValueExtractor {
  static String getValue(TruckModel truck, String fieldKey, AppLocalizations l10n) {
    switch (fieldKey) {
      // Identification
      case 'immatriculation':
        return truck.immatriculation;
      case 'marque':
        return truck.marque;
      case 'modele':
        return truck.modele;
      case 'numeroInterneFlotte':
        return truck.numeroInterneFlotte;
      case 'proprietaire':
        return truck.proprietaire;
      case 'numeroChassis':
        return truck.numeroChassis;
      case 'anneeFabrication':
        return truck.anneeFabrication.toString();
      case 'type':
        return l10n.translate('trucks.types.${truck.type.name}');
      case 'configuration':
        return l10n.translate('trucks.configuration.${truck.configuration.name}');
      case 'couleur':
        return truck.couleur ?? '-';
      case 'assuranceCompagnie':
        return truck.assuranceCompagnie ?? '-';
      case 'visiteTechniqueProchaine':
        return truck.visiteTechniqueProchaine != null
            ? DateFormat('dd/MM/yyyy').format(truck.visiteTechniqueProchaine!)
            : '-';

      // Caractéristiques techniques
      case 'typeCarburant':
        return truck.typeCarburant != null
            ? l10n.translate('trucks.fuelType.${truck.typeCarburant!.name}')
            : '-';
      case 'puissanceCV':
        return truck.puissanceCV != null ? '${truck.puissanceCV} CV' : '-';
      case 'capaciteReservoir':
        return truck.capaciteReservoir != null
            ? '${truck.capaciteReservoir} L'
            : '-';
      case 'ptac':
        return truck.ptac != null ? '${truck.ptac} kg' : '-';
      case 'chargeUtileMax':
        return truck.chargeUtileMax != null
            ? '${truck.chargeUtileMax} t'
            : '-';
      case 'boiteVitesses':
        return truck.boiteVitesses != null
            ? l10n.translate('trucks.gearbox.${truck.boiteVitesses!.name}')
            : '-';

      // Exploitation
      case 'statut':
        return l10n.translate('trucks.status.${truck.statut.name}');
      case 'siteAffectation':
        return truck.siteAffectation ?? '-';
      case 'zoneExploitation':
        return truck.zoneExploitation ?? '-';
      case 'typeActivite':
        return truck.typeActivite != null
            ? l10n.translate('trucks.activityType.${truck.typeActivite!.name}')
            : '-';
      case 'chauffeurPrincipal':
        return truck.chauffeurPrincipalId ?? 'Non assigné';
      case 'kilometrageActuel':
        return '${NumberFormat('#,###').format(truck.kilometrageActuel)} km';
      case 'heuresMoteur':
        return truck.heuresMoteur != null ? '${truck.heuresMoteur} h' : '-';

      // Maintenance
      case 'derniereMaintenanceDate':
        return truck.derniereMaintenanceDate != null
            ? DateFormat('dd/MM/yyyy').format(truck.derniereMaintenanceDate!)
            : '-';
      case 'prochaineMaintenancePrevue':
        return truck.prochaineMaintenancePrevue != null
            ? DateFormat('dd/MM/yyyy').format(truck.prochaineMaintenancePrevue!)
            : '-';
      case 'planMaintenance':
        return truck.planMaintenance != null
            ? l10n.translate('trucks.maintenancePlan.${truck.planMaintenance!.name}')
            : '-';
      case 'garagePrestataire':
        return truck.garagePrestataire ?? '-';

      // Performance
      case 'tauxDisponibilite':
        return truck.tauxDisponibilite != null
            ? '${truck.tauxDisponibilite}%'
            : '-';
      case 'coutParKm':
        return truck.coutParKm != null ? '${truck.coutParKm} €/km' : '-';
      case 'rentabilite':
        return truck.rentabilite != null ? '${truck.rentabilite} €' : '-';
      case 'nombreRotations':
        return truck.nombreRotations?.toString() ?? '-';
      case 'tonnageTransporte':
        return truck.tonnageTransporte != null
            ? '${truck.tonnageTransporte} t'
            : '-';

      // GPS
      case 'identifiantGPS':
        return truck.identifiantGPS ?? '-';
      case 'fournisseurGPS':
        return truck.fournisseurGPS ?? '-';

      default:
        return '-';
    }
  }

  /// Obtenir une icône de statut pour certains champs
  static String? getStatusIcon(TruckModel truck, String fieldKey) {
    switch (fieldKey) {
      case 'statut':
        switch (truck.statut) {
          case TruckStatus.enService:
            return '🟢';
          case TruckStatus.enMaintenance:
            return '🟡';
          case TruckStatus.enPanne:
            return '🔴';
          case TruckStatus.immobilise:
            return '⚫';
        }
      case 'prochaineMaintenancePrevue':
        if (truck.maintenanceAVenir) return '⚠️';
        return null;
      case 'visiteTechniqueProchaine':
        if (!truck.visiteTechniqueValide) return '⚠️';
        return null;
      case 'assuranceCompagnie':
        if (!truck.hasAssurance) return '⚠️';
        return null;
      default:
        return null;
    }
  }
}
