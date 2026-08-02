import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../domain/models/user_model.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/animated_background.dart';
import '../widgets/truck_illustration.dart';

/// Page de connexion premium pour tablette
/// Design industriel raffiné avec animations fluides
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await ref.read(authControllerProvider.notifier).signIn(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final isTablet = size.width >= 768;
    final isLandscape = orientation == Orientation.landscape;

    // Écouter les changements d'état d'authentification
    ref.listen<AsyncValue<UserModel?>>(authControllerProvider, (previous, next) {
      if (!mounted) return;

      next.whenOrNull(
        data: (user) {
          if (user != null) {
            // Arrêter le loading et naviguer vers le dashboard
            setState(() => _isLoading = false);
            Navigator.of(context).pushReplacementNamed('/dashboard');
          } else {
            // Si user est null après une tentative de connexion, arrêter le loading
            setState(() => _isLoading = false);
          }
        },
        error: (error, stack) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          );
        },
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),

          SafeArea(
            child: isTablet || isLandscape
                ? _buildTabletLayout(size)
                : _buildMobileLayout(size),
          ),
        ],
      ),
    );
  }

  /// Layout pour tablette - deux colonnes
  Widget _buildTabletLayout(Size size) {
    return Row(
      children: [
        // Panneau gauche - Branding et illustration
        Expanded(
          flex: 55,
          child: _buildBrandingPanel(),
        ),

        // Panneau droit - Formulaire de connexion
        Expanded(
          flex: 45,
          child: _buildLoginPanel(),
        ),
      ],
    );
  }

  /// Layout pour mobile - colonne unique
  Widget _buildMobileLayout(Size size) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              _buildLogo()
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.3, curve: Curves.easeOutCubic),
              const SizedBox(height: AppSpacing.xxl),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  /// Panneau de branding avec illustration
  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F1629),
            Color(0xFF0A0E17),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Motif de grille en arrière-plan
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPatternPainter(),
                ),
              ),

          // Cercles décoratifs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 4.seconds,
                curve: Curves.easeInOut,
              ),

          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(1.1, 1.1),
                end: const Offset(0.9, 0.9),
                duration: 5.seconds,
                curve: Curves.easeInOut,
              ),

          // Contenu du panneau
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (AppSpacing.xxl * 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      _buildLogo()
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 200.ms)
                          .slideX(begin: -0.3, curve: Curves.easeOutCubic),

                      // Illustration de camion
                      Center(
                        child: const TruckIllustration()
                            .animate()
                            .fadeIn(duration: 1000.ms, delay: 400.ms)
                            .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                      ),

                      // Section inférieure
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Texte de présentation
                          _buildBrandingText()
                              .animate()
                              .fadeIn(duration: 800.ms, delay: 600.ms)
                              .slideY(begin: 0.3, curve: Curves.easeOutCubic),

                          const SizedBox(height: AppSpacing.xxl),

                          // Statistiques
                          _buildStats()
                              .animate()
                              .fadeIn(duration: 800.ms, delay: 800.ms)
                              .slideY(begin: 0.3, curve: Curves.easeOutCubic),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
            ],
          );
        },
      ),
    );
  }

  /// Logo de l'application
  Widget _buildLogo() {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.asset(
            'assets/images/logo.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.glow,
              ),
              child: const Icon(
                Iconsax.truck_fast,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Nom
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.appTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              l10n.appName,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Texte de branding
  Widget _buildBrandingText() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('auth.brandingTitle'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.textPrimary, AppColors.primary],
          ).createShader(bounds),
          child: Text(
            l10n.translate('auth.brandingSubtitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.translate('auth.brandingDescription'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  /// Statistiques animées
  Widget _buildStats() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          _buildStatItem(l10n.translate('auth.stat1Value'), l10n.translate('auth.stat1Label'), Iconsax.truck),
          _buildStatDivider(),
          _buildStatItem(l10n.translate('auth.stat2Value'), l10n.translate('auth.stat2Label'), Iconsax.chart_success),
          _buildStatDivider(),
          _buildStatItem(l10n.translate('auth.stat3Value'), l10n.translate('auth.stat3Label'), Iconsax.message_favorite5),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 60,
      color: AppColors.surfaceBorder,
    );
  }

  /// Panneau de connexion
  Widget _buildLoginPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          left: BorderSide(
            color: AppColors.surfaceBorder,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (AppSpacing.xxl * 2),
                maxWidth: 420,
              ),
              child: Center(
                child: _buildLoginForm(),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Formulaire de connexion
  Widget _buildLoginForm() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sélecteur de langue
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              LanguageSelector(),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // En-tête
          Text(
            l10n.authWelcome,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .slideX(begin: 0.2, curve: Curves.easeOutCubic),

          const SizedBox(height: AppSpacing.sm),

          Text(
            l10n.authSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 300.ms)
              .slideX(begin: 0.2, curve: Curves.easeOutCubic),

          const SizedBox(height: AppSpacing.xxl),

          // Champ email ou téléphone
          PremiumTextField(
            controller: _identifierController,
            focusNode: _identifierFocusNode,
            label: l10n.translate('auth.identifier'),
            hint: l10n.translate('auth.identifierHint'),
            prefixIcon: Iconsax.user,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.translate('auth.errors.identifierRequired');
              }
              // Si contient @, valider comme email
              if (value.contains('@')) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return l10n.translate('auth.errors.identifierInvalid');
                }
                return null;
              }
              // Sinon, valider comme téléphone guinéen
              final cleaned = value.replaceAll(RegExp(r'[\s\-\.]'), '');
              final phonePatterns = [
                RegExp(r'^\+224[0-9]{9}$'),
                RegExp(r'^00224[0-9]{9}$'),
                RegExp(r'^[0-9]{9}$'),
              ];
              if (!phonePatterns.any((p) => p.hasMatch(cleaned))) {
                return l10n.translate('auth.errors.identifierInvalid');
              }
              return null;
            },
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 400.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),

          const SizedBox(height: AppSpacing.lg),

          // Champ mot de passe
          PremiumTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: l10n.authPassword,
            hint: l10n.authPasswordHint,
            prefixIcon: Iconsax.lock,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Iconsax.eye : Iconsax.eye_slash,
                color: AppColors.textTertiary,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.translate('auth.errors.passwordRequired');
              }
              if (value.length < 8) {
                return l10n.translate('auth.errors.passwordTooShort');
              }
              return null;
            },
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 500.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),

          const SizedBox(height: AppSpacing.md),

          // Options supplémentaires
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Se souvenir de moi
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _rememberMe
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _rememberMe
                              ? AppColors.primary
                              : AppColors.surfaceBorder,
                          width: 1.5,
                        ),
                      ),
                      child: _rememberMe
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.translate('auth.rememberMe'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Mot de passe oublié (désactivé)
              // TextButton(
              //   onPressed: () {
              //     // Navigation vers la page de récupération
              //   },
              //   child: Text(l10n.authForgotPassword),
              // ),
            ],
          ).animate().fadeIn(duration: 600.ms, delay: 600.ms),

          const SizedBox(height: AppSpacing.xl),

          // Bouton de connexion
          PremiumButton(
            text: l10n.authLogin,
            onPressed: _handleLogin,
            isLoading: _isLoading,
            icon: Iconsax.login,
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 700.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

/// Bouton de connexion sociale
class _SocialLoginButton extends StatefulWidget {
  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.surfaceLight
                : (_isHovered ? AppColors.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: AppColors.textPrimary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Peintre pour le motif de grille
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceBorder.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    // Lignes verticales
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Lignes horizontales
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
