import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/widgets/user_avatar_widget.dart';
import '../../../../services/auth_service.dart' hide authControllerProvider;
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';
import '../../../users/presentation/providers/user_management_providers.dart';

/// Écran de configuration de l'application
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final userModel = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userModel != null) ...[
                    _buildProfileSection(context, ref, userModel, l10n),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  _buildLanguageSection(context, ref, currentLocale, l10n),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.backgroundSecondary, AppColors.surface],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.glow,
            ),
            child: const Icon(
              Iconsax.setting_2,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.translate('settings.title'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.translate('settings.subtitle'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
    );
  }

  // ── Section Profil ─────────────────────────────────────────────────────────

  Widget _buildProfileSection(
    BuildContext context,
    WidgetRef ref,
    dynamic userModel,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Iconsax.user_edit,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('settings.profileSection'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.translate('settings.profileSectionSubtitle'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          // Carte de profil + bouton modifier
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                UserAvatarWidget(
                  radius: 30,
                  photoUrl: userModel.photoUrl as String?,
                  initials: userModel.initials as String,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userModel.fullName as String,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if ((userModel.email as String?)?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Text(
                          userModel.email as String,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if ((userModel.role as String?)?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            userModel.role as String,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => EditProfileDialog(userModel: userModel),
                  ),
                  icon: const Icon(Iconsax.edit_2, size: 16),
                  label: Text(l10n.translate('settings.editProfile')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms);
  }

  // ── Section Langue ─────────────────────────────────────────────────────────

  Widget _buildLanguageSection(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Iconsax.language_square,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('settings.languageSection'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.translate('settings.languageSectionSubtitle'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _buildLanguageOption(
                  context,
                  ref,
                  l10n,
                  locale: const Locale('fr', 'FR'),
                  flag: '🇫🇷',
                  name: l10n.translate('settings.french'),
                  nativeName: 'Français',
                  isSelected: currentLocale.languageCode == 'fr',
                ),
                const SizedBox(height: AppSpacing.md),
                _buildLanguageOption(
                  context,
                  ref,
                  l10n,
                  locale: const Locale('en', 'US'),
                  flag: '🇬🇧',
                  name: l10n.translate('settings.english'),
                  nativeName: 'English',
                  isSelected: currentLocale.languageCode == 'en',
                ),
                const SizedBox(height: AppSpacing.md),
                _buildLanguageOption(
                  context,
                  ref,
                  l10n,
                  locale: const Locale('zh', 'CN'),
                  flag: '🇨🇳',
                  name: l10n.translate('settings.chinese'),
                  nativeName: '中文',
                  isSelected: currentLocale.languageCode == 'zh',
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    required Locale locale,
    required String flag,
    required String name,
    required String nativeName,
    required bool isSelected,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          await ref.read(localeProvider.notifier).setLocale(locale);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n
                    .translate('settings.languageChanged')
                    .replaceAll('{language}', nativeName)),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.surfaceBorder.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(flag, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nativeName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Iconsax.tick_circle5,
                        color: Colors.white, size: 20),
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.surfaceBorder, width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dialogue d'édition du profil ──────────────────────────────────────────────

class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({required this.userModel, super.key});

  final dynamic userModel;

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Infos
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  bool _infoLoading = false;

  // Email
  late final TextEditingController _newEmailCtrl;
  final TextEditingController _emailPasswordCtrl = TextEditingController();
  bool _emailLoading = false;
  bool _emailPasswordVisible = false;

  // Mot de passe
  final TextEditingController _currentPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  bool _pwdLoading = false;
  bool _currentPwdVisible = false;
  bool _newPwdVisible = false;
  bool _confirmPwdVisible = false;

  final _infoKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormState>();
  final _pwdKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _firstNameCtrl =
        TextEditingController(text: widget.userModel.firstName as String? ?? '');
    _lastNameCtrl =
        TextEditingController(text: widget.userModel.lastName as String? ?? '');
    _newEmailCtrl =
        TextEditingController(text: widget.userModel.email as String? ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _newEmailCtrl.dispose();
    _emailPasswordCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _saveInfo() async {
    if (!_infoKey.currentState!.validate()) return;
    setState(() => _infoLoading = true);
    try {
      final repo = ref.read(userManagementRepositoryProvider);
      await repo.updateUserBasicInfo(
        userId: widget.userModel.id as String,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
      );
      ref.invalidate(authControllerProvider);
      if (mounted) {
        _showSuccess(AppLocalizations.of(context)
            .translate('settings.profileUpdated'));
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _infoLoading = false);
    }
  }

  Future<void> _saveEmail() async {
    if (!_emailKey.currentState!.validate()) return;
    final newEmail = _newEmailCtrl.text.trim();
    final password = _emailPasswordCtrl.text;
    if (newEmail == (widget.userModel.email as String? ?? '')) {
      _showError(AppLocalizations.of(context)
          .translate('settings.emailUnchanged'));
      return;
    }
    setState(() => _emailLoading = true);
    try {
      // Réauthentification
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail);

      // Mise à jour Firestore
      final repo = ref.read(userManagementRepositoryProvider);
      await repo.updateUserEmail(
        userId: widget.userModel.id as String,
        email: newEmail,
      );
      ref.invalidate(authControllerProvider);
      if (mounted) {
        _showSuccess(AppLocalizations.of(context)
            .translate('settings.emailVerificationSent'));
        _emailPasswordCtrl.clear();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_mapFirebaseError(e.code));
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_pwdKey.currentState!.validate()) return;
    setState(() => _pwdLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.updatePassword(
        currentPassword: _currentPasswordCtrl.text,
        newPassword: _newPasswordCtrl.text,
      );
      if (!result.success) throw Exception(result.errorMessage);
      if (mounted) {
        _showSuccess(AppLocalizations.of(context)
            .translate('settings.passwordUpdated'));
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _pwdLoading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'wrong-password':
        return AppLocalizations.of(context)
            .translate('settings.wrongPassword');
      case 'requires-recent-login':
        return AppLocalizations.of(context)
            .translate('settings.requiresRecentLogin');
      case 'email-already-in-use':
        return AppLocalizations.of(context)
            .translate('settings.emailAlreadyInUse');
      default:
        return code;
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Container(
        width: size.width < 600 ? size.width * 0.95 : 520,
        constraints: BoxConstraints(maxHeight: size.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildDialogHeader(l10n),
            // Tabs
            Container(
              color: AppColors.backgroundSecondary,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: l10n.translate('settings.tabInfo')),
                  Tab(text: l10n.translate('settings.tabEmail')),
                  Tab(text: l10n.translate('settings.tabPassword')),
                ],
              ),
            ),
            // Content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(l10n),
                  _buildEmailTab(l10n),
                  _buildPasswordTab(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          UserAvatarWidget(
            radius: 24,
            photoUrl: widget.userModel.photoUrl as String?,
            initials: widget.userModel.initials as String,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('settings.editProfileTitle'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.userModel.fullName as String,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ── Tab Informations ───────────────────────────────────────────────────────

  Widget _buildInfoTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _infoKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            PremiumTextField(
              controller: _firstNameCtrl,
              label: l10n.translate('users.createUserDialog.firstName'),
              prefixIcon: Iconsax.user,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.translate('settings.fieldRequired') : null,
            ),
            const SizedBox(height: AppSpacing.md),
            PremiumTextField(
              controller: _lastNameCtrl,
              label: l10n.translate('users.createUserDialog.lastName'),
              prefixIcon: Iconsax.user,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.translate('settings.fieldRequired') : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            _SaveButton(
              label: l10n.translate('settings.saveInfo'),
              isLoading: _infoLoading,
              onPressed: _saveInfo,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Email ──────────────────────────────────────────────────────────────

  Widget _buildEmailTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _emailKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.translate('settings.emailChangeInfo'),
                      style: const TextStyle(
                          color: AppColors.info, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PremiumTextField(
              controller: _newEmailCtrl,
              label: l10n.translate('settings.newEmail'),
              prefixIcon: Iconsax.sms,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.translate('settings.fieldRequired');
                }
                if (!v.contains('@')) {
                  return l10n.translate('settings.invalidEmail');
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildPasswordField(
              controller: _emailPasswordCtrl,
              label: l10n.translate('settings.currentPasswordConfirm'),
              icon: Iconsax.lock,
              visible: _emailPasswordVisible,
              onToggle: () => setState(
                  () => _emailPasswordVisible = !_emailPasswordVisible),
              validator: (v) => (v == null || v.isEmpty)
                  ? l10n.translate('settings.fieldRequired')
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            _SaveButton(
              label: l10n.translate('settings.saveEmail'),
              isLoading: _emailLoading,
              onPressed: _saveEmail,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Mot de passe ───────────────────────────────────────────────────────

  Widget _buildPasswordTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _pwdKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _buildPasswordField(
              controller: _currentPasswordCtrl,
              label: l10n.translate('settings.currentPassword'),
              icon: Iconsax.lock,
              visible: _currentPwdVisible,
              onToggle: () => setState(
                  () => _currentPwdVisible = !_currentPwdVisible),
              validator: (v) => (v == null || v.isEmpty)
                  ? l10n.translate('settings.fieldRequired')
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildPasswordField(
              controller: _newPasswordCtrl,
              label: l10n.translate('settings.newPassword'),
              icon: Iconsax.lock_1,
              visible: _newPwdVisible,
              onToggle: () =>
                  setState(() => _newPwdVisible = !_newPwdVisible),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return l10n.translate('settings.fieldRequired');
                }
                if (v.length < 6) {
                  return l10n.translate('settings.passwordTooShort');
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildPasswordField(
              controller: _confirmPasswordCtrl,
              label: l10n.translate('settings.confirmPassword'),
              icon: Iconsax.lock_1,
              visible: _confirmPwdVisible,
              onToggle: () => setState(
                  () => _confirmPwdVisible = !_confirmPwdVisible),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return l10n.translate('settings.fieldRequired');
                }
                if (v != _newPasswordCtrl.text) {
                  return l10n.translate('settings.passwordMismatch');
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            _SaveButton(
              label: l10n.translate('settings.savePassword'),
              isLoading: _pwdLoading,
              onPressed: _savePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      style:
          const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon:
            Icon(icon, size: 18, color: AppColors.textTertiary),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Iconsax.eye_slash : Iconsax.eye,
            size: 18,
            color: AppColors.textTertiary,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

// ── Bouton de sauvegarde ──────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Iconsax.tick_circle, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
