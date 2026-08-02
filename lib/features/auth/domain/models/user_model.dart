import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'permission.dart';
import 'role.dart';

/// Modèle utilisateur pour l'application LSC
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.lastLoginAt,
    this.phoneNumber,
    this.role,
    this.department,
    this.matricule,
    this.dateOfBirth,
    this.address,
    this.driverLicenseNumber,
    this.isActive = true,
    this.permissions = const [],
    this.lastPermissionUpdate,
    this.fleetId,
    this.managerId,
    this.managerName,
  });

  /// Créer un UserModel depuis Firebase User
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    String? firstName;
    String? lastName;

    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      firstName: firstName,
      lastName: lastName,
      photoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
      phoneNumber: firebaseUser.phoneNumber,
    );
  }

  /// Créer un UserModel depuis une Map (Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: (map['email'] as String?) ?? '',
      firstName: map['firstName'] as String?,
      lastName: map['lastName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      role: map['role'] as String?,
      department: map['department'] as String?,
      matricule: map['matricule'] as String?,
      address: map['address'] as String?,
      driverLicenseNumber: map['driverLicenseNumber'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      permissions: (map['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateTime(map['lastLoginAt']),
      dateOfBirth: _parseDateTime(map['dateOfBirth']),
      lastPermissionUpdate: _parseDateTime(map['lastPermissionUpdate']),
      fleetId: map['fleetId'] as String?,
      managerId: map['managerId'] as String?,
      managerName: map['managerName'] as String?,
    );
  }

  /// Helper pour parser les DateTime depuis Firestore (Timestamp ou String)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    // Si c'est déjà un DateTime
    if (value is DateTime) return value;

    // Si c'est un Timestamp Firestore
    if (value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate() as DateTime;
    }

    // Si c'est une String (ancien format)
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? role;
  final String? department;
  final String? matricule;
  final String? address;
  final String? driverLicenseNumber;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final List<String> permissions;
  final DateTime? lastPermissionUpdate;
  final String? fleetId;
  final String? managerId;
  final String? managerName;

  /// Obtenir le rôle utilisateur en tant qu'enum
  UserRole? get userRole => UserRole.fromString(role);

  /// Obtenir toutes les permissions effectives (rôle + permissions additionnelles)
  Set<Permission> get effectivePermissions {
    final rolePerms = userRole != null
        ? RoleDefinition.getDefaultPermissions(userRole!)
        : <Permission>{};

    final userPerms = permissions
        .map((permName) {
          try {
            return Permission.values.byName(permName);
          } catch (e) {
            return null;
          }
        })
        .whereType<Permission>()
        .toSet();

    return {...rolePerms, ...userPerms};
  }

  /// Vérifier si l'utilisateur a une permission spécifique
  bool hasPermission(Permission permission) {
    // Si l'utilisateur a fullAccess, il a toutes les permissions
    if (effectivePermissions.contains(Permission.fullAccess)) {
      return true;
    }
    return effectivePermissions.contains(permission);
  }

  /// Vérifier si l'utilisateur a toutes les permissions spécifiées (AND)
  bool hasAllPermissions(List<Permission> perms) {
    return perms.every(hasPermission);
  }

  /// Vérifier si l'utilisateur a au moins une des permissions spécifiées (OR)
  bool hasAnyPermission(List<Permission> perms) {
    return perms.any(hasPermission);
  }

  /// Obtenir le nom complet
  String get fullName {
    if (firstName == null && lastName == null) return '';
    if (firstName != null && lastName != null) return '$firstName $lastName';
    return firstName ?? lastName ?? '';
  }

  /// Obtenir les initiales
  String get initials {
    final first = (firstName?.isNotEmpty ?? false) ? firstName![0] : '';
    final last = (lastName?.isNotEmpty ?? false) ? lastName![0] : '';
    return '$first$last'.toUpperCase();
  }

  /// Vérifier si l'utilisateur est RH (admin)
  @Deprecated('Utilisez hasPermission(Permission.viewUsers) à la place')
  bool get isRH => role?.toLowerCase() == 'rh' || role?.toLowerCase() == 'admin';

  /// Vérifier si l'utilisateur est un superviseur flotte
  bool get isSuperviseurFlotte => matricule?.startsWith('SFLOT') ?? false;

  /// Vérifier si l'utilisateur est un superviseur général
  bool get isSuperviseurGeneral => matricule?.startsWith('SGEN') ?? false;

  /// Vérifier si l'utilisateur est un chauffeur
  bool get isChauffeur => matricule?.startsWith('CH') ?? false;

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'role': role,
      'department': department,
      'matricule': matricule,
      'address': address,
      'driverLicenseNumber': driverLicenseNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'permissions': permissions,
      'lastPermissionUpdate': lastPermissionUpdate?.toIso8601String(),
      'fleetId': fleetId,
      'managerId': managerId,
      'managerName': managerName,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? phoneNumber,
    String? role,
    String? department,
    String? matricule,
    String? address,
    String? driverLicenseNumber,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    List<String>? permissions,
    DateTime? lastPermissionUpdate,
    String? fleetId,
    String? managerId,
    String? managerName,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      department: department ?? this.department,
      matricule: matricule ?? this.matricule,
      address: address ?? this.address,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
      lastPermissionUpdate: lastPermissionUpdate ?? this.lastPermissionUpdate,
      fleetId: fleetId ?? this.fleetId,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
    );
  }
}
