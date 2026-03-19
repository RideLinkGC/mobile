import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/emergency_provider.dart';

class SosScreen extends StatefulWidget {
  final String tripId;

  const SosScreen({super.key, required this.tripId});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  static const int _countdownSeconds = 5;
  int _remainingSeconds = _countdownSeconds;
  bool _isCountdownActive = false;
  bool _alertTriggered = false;
  Timer? _countdownTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _isCountdownActive = true;
      _remainingSeconds = _countdownSeconds;
    });
    final emergencyProvider = context.read<EmergencyProvider>();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isCountdownActive = false;
            _alertTriggered = true;
          });
        }
        await emergencyProvider.triggerSOS(widget.tripId);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountdownActive = false;
      _remainingSeconds = _countdownSeconds;
    });
  }

  Future<void> _cancelSOS() async {
    await context.read<EmergencyProvider>().cancelSOS();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emergencyProvider = context.watch<EmergencyProvider>();

    return Scaffold(
      backgroundColor: AppColors.sosRed.withValues(alpha: 0.08),
      body: SafeArea(
        child: _alertTriggered || emergencyProvider.sent
            ? _buildAlertSentView(context, l10n, emergencyProvider)
            : _buildMainView(context, l10n, emergencyProvider),
      ),
    );
  }

  Widget _buildMainView(
    BuildContext context,
    AppLocalizations l10n,
    EmergencyProvider emergencyProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emergencyProvider.error != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                emergencyProvider.error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.sosRed,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.15);
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sosRed.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: AppColors.sosRed.withValues(alpha: 0.3),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isCountdownActive || emergencyProvider.isSending
                      ? null
                      : _startCountdown,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.sosRed,
                    ),
                    child: Center(
                      child: emergencyProvider.isSending
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : _isCountdownActive
                              ? Text(
                                  '$_remainingSeconds',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                )
                              : Text(
                                  'SOS',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 4,
                                      ),
                                ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isCountdownActive
                ? l10n.sosCountdown(_remainingSeconds)
                : 'Tap to activate emergency alert',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          if (_isCountdownActive)
            AppButton(
              text: l10n.cancel,
              isOutlined: true,
              foregroundColor: AppColors.sosRed,
              onPressed: _cancelCountdown,
            ),
        ],
      ),
    );
  }

  Widget _buildAlertSentView(
    BuildContext context,
    AppLocalizations l10n,
    EmergencyProvider emergencyProvider,
  ) {
    final success = emergencyProvider.sent && emergencyProvider.error == null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              size: 80,
              color: success ? AppColors.success : AppColors.sosRed,
            ),
            const SizedBox(height: 24),
            Text(
              success ? l10n.sosActivated : 'Emergency alert failed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              success
                  ? 'Emergency services and your contacts have been notified.'
                  : emergencyProvider.error ?? 'Please call emergency services.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: success && emergencyProvider.alertId != null
                  ? 'Cancel Alert'
                  : 'Back',
              isOutlined: success && emergencyProvider.alertId != null,
              foregroundColor: success && emergencyProvider.alertId != null
                  ? AppColors.sosRed
                  : null,
              onPressed: success && emergencyProvider.alertId != null
                  ? _cancelSOS
                  : () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
