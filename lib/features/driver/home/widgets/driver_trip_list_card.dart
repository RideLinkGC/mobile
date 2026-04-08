import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../trip/models/trip_model.dart';


// Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
            
//             Icon(Icons.circle, size: 10, color: Colors.green),
//               Container(width: 2, height: 30, color: Colors.grey.shade400),
//               Icon(Icons.location_on, size: 16, color: Colors.red),
//             ],
//                     ),
//           )

class DriverTripListCard extends StatelessWidget {
  final TripModel trip;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const DriverTripListCard({
    super.key,
    required this.trip,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat('EEE, MMM d • h:mm a');
    final (color, label) = switch (trip.status) {
      TripStatus.scheduled => (AppColors.info, 'Scheduled'),
      TripStatus.inProgress => (AppColors.success, 'In progress'),
      TripStatus.completed => (AppColors.textSecondaryLight, 'Completed'),
      TripStatus.canceled => (AppColors.error, 'Canceled'),
    };

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             trip.origin,
             style: GoogleFonts.poppins(
               fontWeight: FontWeight.w600,
             ),
             maxLines: 2,
             overflow: TextOverflow.ellipsis,
           ),
           const SizedBox(height: 20),

           Text(
             trip.destination,
             style: GoogleFonts.poppins(
               fontWeight: FontWeight.w600,
             ),
             maxLines: 2,
             overflow: TextOverflow.ellipsis,
           ),

           SizedBox(height: 10,),
           Row(
             children: [
               Icon(Icons.schedule, size: 16, color: AppColors.textSecondaryLight),
               const SizedBox(width: 6),
               Expanded(
                 child: Text(
                   timeFmt.format(trip.departureTime),
                   style: GoogleFonts.aBeeZee(
                     fontWeight: FontWeight.w400,
                   ),
                 ),
               ),
             ],
           ),
           const SizedBox(height: 10),
           Row(
             children: [
               _MetaChip(
                 icon: Icons.event_seat_outlined,
                 text: '${trip.seatsLeft} ${l10n.seats}',
               ),
               const SizedBox(width: 8),
               _MetaChip(
                 icon: Icons.payments_outlined,
                 text:
                     '${trip.pricePerSeat.toStringAsFixed(0)} ${l10n.etb}${l10n.perSeat}',
                     
               ),
             ],
           ),
         ],
       ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.aBeeZee(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

