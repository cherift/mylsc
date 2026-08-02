/// Constantes globales de l'application FleetManager
library;

class AppConstants {
  AppConstants._();

  // ============================================
  // INFORMATIONS DE L'APPLICATION
  // ============================================
  static const String appName = 'FleetManager';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // ============================================
  // CONFIGURATION API / FIREBASE
  // ============================================
  static const int apiTimeout = 30000; // 30 secondes
  static const int maxRetries = 3;

  // ============================================
  // PAGINATION
  // ============================================
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ============================================
  // VALIDATION
  // ============================================
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxEmailLength = 254;

  // ============================================
  // VÉHICULES
  // ============================================
  static const int maxVehiclesPerFleet = 500;
  static const int locationUpdateIntervalSeconds = 30;
  static const double lowFuelThresholdPercent = 15.0;
  static const int maintenanceAlertDaysBeforeDue = 7;

  // ============================================
  // FORMATS DE DATE
  // ============================================
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'";

  // ============================================
  // STOCKAGE LOCAL
  // ============================================
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
  static const String settingsKey = 'app_settings';
  static const String rememberMeKey = 'remember_me';
  static const String lastEmailKey = 'last_email';

  // ============================================
  // ANIMATIONS
  // ============================================
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 350;
  static const int longAnimationDuration = 500;

  // ============================================
  // BREAKPOINTS RESPONSIVE
  // ============================================
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // ============================================
  // ASSETS PATHS
  // ============================================
  static const String imagesPath = 'assets/images';
  static const String iconsPath = 'assets/icons';
  static const String fontsPath = 'assets/fonts';

  // Images
  static const String logoImage = '$imagesPath/logo.png';
  static const String logoWhiteImage = '$imagesPath/logo_white.png';
  static const String placeholderImage = '$imagesPath/placeholder.png';
  static const String truckImage = '$imagesPath/truck.png';
  static const String mapMarkerImage = '$imagesPath/map_marker.png';

  // ============================================
  // MESSAGES D'ERREUR
  // ============================================
  static const String genericErrorMessage =
      'Une erreur inattendue s\'est produite. Veuillez réessayer.';
  static const String networkErrorMessage =
      'Erreur de connexion. Vérifiez votre connexion internet.';
  static const String sessionExpiredMessage =
      'Votre session a expiré. Veuillez vous reconnecter.';
  static const String maintenanceMessage =
      'L\'application est en maintenance. Veuillez réessayer plus tard.';
}

/// Types de véhicules supportés
enum VehicleType {
  truck('Camion', 'truck'),
  van('Fourgon', 'van'),
  trailer('Remorque', 'trailer'),
  semiTrailer('Semi-remorque', 'semi_trailer');

  const VehicleType(this.label, this.value);

  final String label;
  final String value;

  static VehicleType fromValue(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VehicleType.truck,
    );
  }
}

/// Statuts des véhicules
enum VehicleStatus {
  available('Disponible', 'available'),
  inTransit('En transit', 'in_transit'),
  maintenance('Maintenance', 'maintenance'),
  outOfService('Hors service', 'out_of_service');

  const VehicleStatus(this.label, this.value);

  final String label;
  final String value;

  static VehicleStatus fromValue(String value) {
    return VehicleStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VehicleStatus.available,
    );
  }
}

/// Rôles utilisateur
enum UserRole {
  admin('Administrateur', 'admin'),
  manager('Gestionnaire', 'manager'),
  driver('Chauffeur', 'driver'),
  viewer('Observateur', 'viewer');

  const UserRole(this.label, this.value);

  final String label;
  final String value;

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.viewer,
    );
  }
}

/// Types d'alertes
enum AlertType {
  fuel('Carburant', 'fuel'),
  maintenance('Maintenance', 'maintenance'),
  speed('Vitesse', 'speed'),
  geofence('Zone géographique', 'geofence'),
  battery('Batterie', 'battery'),
  temperature('Température', 'temperature');

  const AlertType(this.label, this.value);

  final String label;
  final String value;
}
