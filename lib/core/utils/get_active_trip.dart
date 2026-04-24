

import 'package:ridelink/features/driver/trip/models/trip_model.dart';
import 'package:ridelink/features/passenger/booking/models/booking_model.dart';

TripModel? getActiveTrip(List<TripModel> trips) {
  final now = DateTime.now();

  trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));

  // return the first trip that has not started yet
  for (final trip in trips) {
    if (trip.departureTime.isAfter(now)) {
      return trip;
    }
  }
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
