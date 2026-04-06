import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/emergency_provider.dart';

/// Stable keys sent to the backend / Convex with [EmergencyProvider.triggerSOS].
enum EmergencyCategory {
  carMalfunction('car_malfunction'),
  medical('medical_emergency'),
  suspicious('suspicious_activity'),
  accident('accident');

  const EmergencyCategory(this.apiKey);
  final String apiKey;

  IconData get icon => switch (this) {
        EmergencyCategory.carMalfunction => Icons.directions_car_outlined,
        EmergencyCategory.medical => Icons.medical_services_outlined,
        EmergencyCategory.suspicious => Icons.shield_outlined,
        EmergencyCategory.accident => Icons.car_crash_outlined,
      };

  String label(AppLocalizations l10n) => switch (this) {
        EmergencyCategory.carMalfunction =>
          l10n.emergencyTypeCarMalfunction,
        EmergencyCategory.medical => l10n.emergencyTypeMedical,
        EmergencyCategory.suspicious => l10n.emergencyTypeSuspicious,
        EmergencyCategory.accident => l10n.emergencyTypeAccident,
      };
}

/// Emergency CTA (same in light / dark).
const Color _kEmergencyAccentPink = Color(0xFFFF5E73);
const Color _kOnAccentLabel = Color(0xFF1A1B1F);

/// Theme-aware colors so the sheet matches [ThemeData] (fixes light-mode clash).
@immutable
class _EmergencySheetPalette {
  const _EmergencySheetPalette({
    required this.sheetBg,
    required this.rowBg,
    required this.titleColor,
    required this.subtitleColor,
    required this.iconColor,
    required this.chevronColor,
    required this.dragHandleColor,
    required this.iconCircleBg,
  });

  factory _EmergencySheetPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (theme.brightness == Brightness.dark) {
      return const _EmergencySheetPalette(
        sheetBg: Color(0xFF1A1B1F),
        rowBg: Color(0xFF232529),
        titleColor: Colors.white,
        subtitleColor: Color(0xFF9DA1AA),
        iconColor: Color(0xFFEBEEF2),
        chevronColor: Color(0xFF9DA1AA),
        dragHandleColor: Color(0x669DA1AA),
        iconCircleBg: Color(0xFF3D1518),
      );
    }
    return _EmergencySheetPalette(
      sheetBg: scheme.surface,
      rowBg: scheme.surfaceContainerHighest,
      titleColor: scheme.onSurface,
      subtitleColor: scheme.onSurfaceVariant,
      iconColor: scheme.onSurface,
      chevronColor: scheme.onSurfaceVariant,
      dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.35),
      iconCircleBg: AppColors.sosRed.withValues(alpha: 0.12),
    );
  }

  final Color sheetBg;
  final Color rowBg;
  final Color titleColor;
  final Color subtitleColor;
  final Color iconColor;
  final Color chevronColor;
  final Color dragHandleColor;
  final Color iconCircleBg;
}

/// Shows the emergency sheet; on send, calls Convex/backend and shows a short
/// confirmation — no full-screen SOS animation.
Future<void> showEmergencyAlertFlow(BuildContext context, String tripId) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (ctx) => _EmergencyAlertSheetBody(tripId: tripId),
  );
}

class _EmergencyAlertSheetBody extends StatefulWidget {
  const _EmergencyAlertSheetBody({required this.tripId});

  final String tripId;

  @override
  State<_EmergencyAlertSheetBody> createState() =>
      _EmergencyAlertSheetBodyState();
}

class _EmergencyAlertSheetBodyState extends State<_EmergencyAlertSheetBody> {
  EmergencyCategory? _selected;
  bool _sending = false;

  Future<void> _onSend() async {
    final category = _selected;
    if (category == null || _sending) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context)!;
    final emergency = context.read<EmergencyProvider>();

    final ok = await emergency.triggerSOS(
      widget.tripId,
      reason: category.apiKey,
    );

    if (!mounted) return;

    setState(() => _sending = false);

    final scheme = Theme.of(context).colorScheme;
    messenger?.showSnackBar(
      SnackBar(
        backgroundColor: scheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Text(
          ok
              ? l10n.sosActivated
              : (emergency.error ?? l10n.emergencySendFailed),
          style: TextStyle(color: scheme.onInverseSurface),
        ),
      ),
    );

    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final palette = _EmergencySheetPalette.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: palette.sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: theme.brightness == Brightness.light
              ? Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.35),
                  ),
                )
              : null,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: palette.dragHandleColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _HeaderIcon(palette: palette),
                const SizedBox(height: 18),
                Text(
                  l10n.emergencyAlertTitle,
                  style: textTheme.titleLarge?.copyWith(
                    color: palette.titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.emergencyAlertSubtitle,
                  style: textTheme.titleSmall?.copyWith(
                    color: palette.subtitleColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                ...EmergencyCategory.values.map((c) => _CategoryTile(
                      palette: palette,
                      category: c,
                      label: c.label(l10n),
                      selected: _selected == c,
                      enabled: !_sending,
                      onTap: () {
                        if (_sending) return;
                        setState(() => _selected = c);
                      },
                    )),
                const SizedBox(height: 22),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _kEmergencyAccentPink.withValues(alpha: 0.38),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: _kEmergencyAccentPink,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: (_selected == null || _sending) ? null : _onSend,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_sending)
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: _kOnAccentLabel.withValues(
                                      alpha: 0.85),
                                ),
                              )
                            else
                              Icon(
                                Icons.send_rounded,
                                color: _kOnAccentLabel.withValues(
                                    alpha: _selected == null ? 0.4 : 1),
                                size: 22,
                              ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.emergencySendAlert,
                              style: TextStyle(
                                color: _kOnAccentLabel.withValues(
                                    alpha: (_selected == null || _sending)
                                        ? 0.4
                                        : 1),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _sending ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.subtitleColor,
                  ),
                  child: Text(
                    l10n.cancel,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.palette});

  final _EmergencySheetPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: palette.iconCircleBg,
              shape: BoxShape.circle,
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kEmergencyAccentPink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: const Icon(
                    Icons.priority_high_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.palette,
    required this.category,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final _EmergencySheetPalette palette;
  final EmergencyCategory category;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: palette.rowBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return theme.colorScheme.primary.withValues(alpha: 0.08);
            }
            return null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? _kEmergencyAccentPink.withValues(alpha: 0.9)
                    : theme.brightness == Brightness.light
                        ? theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.45)
                        : Colors.transparent,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  category.icon,
                  color: palette.iconColor.withValues(
                      alpha: enabled ? 0.95 : 0.4),
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.titleColor.withValues(
                          alpha: enabled ? 1 : 0.45),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.chevronColor.withValues(
                      alpha: enabled ? 0.9 : 0.35),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
