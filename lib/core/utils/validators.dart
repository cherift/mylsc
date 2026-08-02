import '../constants/app_constants.dart';

/// Validateurs de formulaires pour l'application LSC
class Validators {
  Validators._();

  /// Valide une adresse email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse email est requise';
    }

    value = value.trim();

    if (value.length > AppConstants.maxEmailLength) {
      return 'L\'adresse email est trop longue';
    }

    // Regex pour validation email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Adresse email invalide';
    }

    return null;
  }

  /// Valide un mot de passe
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Le mot de passe doit contenir au moins ${AppConstants.minPasswordLength} caractères';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return 'Le mot de passe est trop long';
    }

    return null;
  }

  /// Valide un mot de passe fort (avec critères supplémentaires)
  static String? strongPassword(String? value) {
    final basicValidation = password(value);
    if (basicValidation != null) {
      return basicValidation;
    }

    if (!RegExp('[A-Z]').hasMatch(value!)) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }

    if (!RegExp('[a-z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une minuscule';
    }

    if (!RegExp('[0-9]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un caractère spécial';
    }

    return null;
  }

  /// Valide la confirmation du mot de passe
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Veuillez confirmer votre mot de passe';
      }

      if (value != password) {
        return 'Les mots de passe ne correspondent pas';
      }

      return null;
    };
  }

  /// Valide un nom (prénom, nom de famille, etc.)
  static String? name(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }

    value = value.trim();

    if (value.length < AppConstants.minNameLength) {
      return '$fieldName doit contenir au moins ${AppConstants.minNameLength} caractères';
    }

    if (value.length > AppConstants.maxNameLength) {
      return '$fieldName est trop long';
    }

    // Vérifie que le nom ne contient que des lettres, espaces, tirets et apostrophes
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(value)) {
      return '$fieldName contient des caractères invalides';
    }

    return null;
  }

  /// Valide un numéro de téléphone guinéen
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }

    // Supprime les espaces, tirets et points
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-\.]'), '');

    // Formats acceptés pour la Guinée :
    // - Format international: +224XXXXXXXXX (9 chiffres après +224)
    // - Format international alternatif: 00224XXXXXXXXX
    // - Format local: XXXXXXXXX (9 chiffres)
    final phonePatterns = [
      RegExp(r'^\+224[0-9]{9}$'),      // +224XXXXXXXXX
      RegExp(r'^00224[0-9]{9}$'),      // 00224XXXXXXXXX
      RegExp(r'^[0-9]{9}$'),           // XXXXXXXXX
    ];

    final isValid = phonePatterns.any((pattern) => pattern.hasMatch(cleanedValue));

    if (!isValid) {
      return 'Numéro de téléphone invalide (format: +224 XXX XX XX XX)';
    }

    return null;
  }

  /// Valide une adresse email (optionnelle - ne valide que si non vide)
  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return email(value);
  }

  /// Valide un numéro de téléphone guinéen (optionnel - ne valide que si non vide)
  static String? optionalPhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return phoneNumber(value);
  }

  /// Normalise un numéro de téléphone vers le format +224XXXXXXXXX
  static String normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\.]'), '');

    if (RegExp(r'^\+224[0-9]{9}$').hasMatch(cleaned)) {
      return cleaned;
    }
    if (RegExp(r'^00224[0-9]{9}$').hasMatch(cleaned)) {
      return '+224${cleaned.substring(5)}';
    }
    if (RegExp(r'^[0-9]{9}$').hasMatch(cleaned)) {
      return '+224$cleaned';
    }

    throw const FormatException('Format de numéro de téléphone invalide');
  }

  /// Valide un champ requis générique
  static String? required(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Valide une plaque d'immatriculation française
  static String? licensePlate(String? value) {
    if (value == null || value.isEmpty) {
      return 'La plaque d\'immatriculation est requise';
    }

    final cleanedValue = value.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

    // Format nouveau (AA-123-AA) ou ancien (123 ABC 45)
    final newFormat = RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$');
    final oldFormat = RegExp(r'^[0-9]{1,4}[A-Z]{2,3}[0-9]{2}$');

    if (!newFormat.hasMatch(cleanedValue) &&
        !oldFormat.hasMatch(cleanedValue)) {
      return 'Format de plaque invalide';
    }

    return null;
  }

  /// Valide un numéro VIN (Vehicle Identification Number)
  static String? vin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro VIN est requis';
    }

    final cleanedValue = value.toUpperCase().replaceAll(RegExp(r'\s'), '');

    if (cleanedValue.length != 17) {
      return 'Le numéro VIN doit contenir 17 caractères';
    }

    // Le VIN ne contient pas I, O, Q
    if (RegExp('[IOQ]').hasMatch(cleanedValue)) {
      return 'Le numéro VIN ne peut pas contenir I, O ou Q';
    }

    if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(cleanedValue)) {
      return 'Format de numéro VIN invalide';
    }

    return null;
  }

  /// Valide un kilométrage
  static String? mileage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le kilométrage est requis';
    }

    final mileageValue = int.tryParse(value.replaceAll(RegExp(r'\s'), ''));

    if (mileageValue == null) {
      return 'Kilométrage invalide';
    }

    if (mileageValue < 0) {
      return 'Le kilométrage ne peut pas être négatif';
    }

    if (mileageValue > 10000000) {
      return 'Kilométrage trop élevé';
    }

    return null;
  }

  /// Valide un pourcentage (0-100)
  static String? percentage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est requis';
    }

    final percentValue = double.tryParse(value);

    if (percentValue == null) {
      return 'Valeur invalide';
    }

    if (percentValue < 0 || percentValue > 100) {
      return 'La valeur doit être entre 0 et 100';
    }

    return null;
  }

  /// Valide une date (pas dans le futur)
  static String? pastDate(DateTime? value) {
    if (value == null) {
      return 'La date est requise';
    }

    if (value.isAfter(DateTime.now())) {
      return 'La date ne peut pas être dans le futur';
    }

    return null;
  }

  /// Valide une date (pas dans le passé)
  static String? futureDate(DateTime? value) {
    if (value == null) {
      return 'La date est requise';
    }

    if (value.isBefore(DateTime.now())) {
      return 'La date ne peut pas être dans le passé';
    }

    return null;
  }

  /// Combine plusieurs validateurs
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
}
