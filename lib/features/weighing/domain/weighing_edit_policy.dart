import '../../auth/domain/models/permission.dart';
import '../../auth/domain/models/user_model.dart';
import 'models/weighing_record_model.dart';

/// Règles de correction des pesées (T.38)
class WeighingEditPolicy {
  const WeighingEditPolicy._();

  /// Délai pendant lequel un pointeur peut corriger ses propres pesées
  static const pointeurEditWindow = Duration(hours: 24);

  /// Admin (Direction / RH) : correction de toutes les pesées
  static bool isAdminEditor(UserModel user) =>
      user.hasPermission(Permission.editWeighings);

  /// Peut corriger cette pesée :
  /// - admin : toutes les pesées ;
  /// - pointeur : ses propres pesées, dans les 24 h suivant leur création.
  static bool canEdit(UserModel user, WeighingRecordModel record,
      {DateTime? now}) {
    if (isAdminEditor(user)) return true;
    if (!user.hasPermission(Permission.recordWeighing)) return false;
    if (record.weighedBy != user.id) return false;
    final elapsed = (now ?? DateTime.now()).difference(record.createdAt);
    return elapsed <= pointeurEditWindow;
  }

  /// Le n° de bon relie l'entrée à la sortie (T.27.1) : seul l'admin
  /// peut le corriger.
  static bool canEditTicket(UserModel user) => isAdminEditor(user);
}
