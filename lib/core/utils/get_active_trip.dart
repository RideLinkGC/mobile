

import 'package:ridelink/features/driver/trip/models/trip_model.dart';
import 'package:ridelink/features/passenger/booking/models/booking_model.dart';
import 'package:ridelink/core/constants/enums.dart';

TripModel? getActiveTrip(List<TripModel> trips) {
  final now = DateTime.now();

  if (trips.isEmpty) return null;

  // Prefer an in-progress trip if any.
  final inProgress = trips
      .where((t) => t.status == TripStatus.inProgress)
      .toList(growable: false);
  if (inProgress.isNotEmpty) {
    final sorted = [...inProgress]..sort(
        (a, b) => a.departureTime.compareTo(b.departureTime),
      );
    return sorted.first;
  }

  // Otherwise return the next upcoming scheduled trip.
  final upcoming = trips
      .where(
        (t) =>
            t.status == TripStatus.scheduled &&
            t.departureTime.isAfter(now),
      )
      .toList(growable: false)
    ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
  if (upcoming.isNotEmpty) return upcoming.first;

  return null;
}


//get active trips from bookings
BookingModel? getActiveTripsFromBookings(List<BookingModel> bookings) {
  final now = DateTime.now();
  bookings.sort((a, b) => a.tripDepartureTime!.compareTo(b.tripDepartureTime!));
  
  for (final book in bookings){
    if(book.tripDepartureTime!.isAfter(now)){
      return book;
    }
  }
  return null;
}
