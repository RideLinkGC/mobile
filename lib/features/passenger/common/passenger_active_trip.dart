import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ridelink/core/theme/app_colors.dart';
import 'package:ridelink/features/driver/trip/models/trip_model.dart';
import 'package:ridelink/l10n/app_localizations.dart';

class PassengerActiveTripCard extends StatelessWidget {
  final TripModel trip;
  const PassengerActiveTripCard({super.key, required this.trip});

 

  String _shortDriverName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return name;
    if (parts.length == 1) return parts.first;
    final last = parts.last;
    final initial = last.isNotEmpty ? '${last[0]}.' : '';
    return '${parts.first} $initial'.trim();
  }

  String _vehicleSubtitle(TripModel? trip) {
    final model = trip?.vehicleModel ?? 'Toyota Prius';
    final plate = trip?.vehiclePlate ?? 'AA 2-34567';
    return '$model • $plate';
  }



  /// Kilometers from Gebeta `totalDistance` (via [RouteResult.distanceKm]).
  double? get _routeDistanceKm {
    final km = trip.distanceKm;
    if (km <= 0) return null;
    return km;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: trip.driverImage != null &&
                          trip.driverImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: trip.driverImage!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _avatarFallback(
                            trip.driverName ?? '',
                            64,
                          ),
                        )
                      : _avatarFallback(trip.driverName ?? '', 64),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -6,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            trip.driverRating?.toStringAsFixed(1) ?? '0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.ratingStar,
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              
              
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _shortDriverName(trip.driverName ?? ''),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _vehicleSubtitle(trip),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(
                      color: theme.brightness ==
                              Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            
            
            Text(
              l10n.passengerDashboardEtaLabel(trip.departureTimeFormatted),
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimelineRail(theme: theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.passengerDashboardPickup}: ${trip.origin}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${l10n.passengerDashboardDropoff}: ${trip.destination}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 18),
        Row(
          children: [
            _SpecChip(
              label: l10n.passengerDashboardSeatsCount(
                trip.bookedSeats,
              ),
            ),
            const SizedBox(width: 8),
            if (_routeDistanceKm != null) ...[
              _SpecChip(
                label:
                    '${_routeDistanceKm!.toStringAsFixed(1)} ${l10n.km}',
              ),
              const SizedBox(width: 8),
            ],
            _SpecChip(label: l10n.passengerDashboardAcOn),
            const Spacer(),
            Text(
              '${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb}${l10n.perSeat}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _avatarFallback(String name, double size) {
    final initial =
        name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final lineColor = theme.colorScheme.outline.withValues(alpha: 0.45);
    return SizedBox(
      width: 18,
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 2),
              color: theme.colorScheme.surface,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SizedBox(
              height: 28,
              child: CustomPaint(
                painter: _DashedLinePainter(color: lineColor),
                size: const Size(2, 28),
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}


class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 4.0;
    const gap = 3.0;
    double y = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final cx = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(cx, y), Offset(cx, math.min(y + dash, size.height)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: 0.35)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
