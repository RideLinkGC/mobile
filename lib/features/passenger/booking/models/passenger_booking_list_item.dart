/// UI-only booking row for the passenger bookings hub (mock or mapped from API).
enum PassengerBookingListKind {
  /// Driver accepted; passenger must confirm or cancel.
  awaitingPassengerConfirmation,

  /// Request sent; waiting for driver.
  pendingDriverConfirmation,

  /// Both sides confirmed — trip ready (includes recurring).
  active,
}

class PassengerBookingListItem {
  final String id;
  final String tripId;
  final String driverName;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final double totalPrice;
  final int seatsBooked;
  final PassengerBookingListKind kind;

  /// When [kind] is [PassengerBookingListKind.active] and part of a subscription.
  final bool isRecurrent;

  /// e.g. "Weekly", "Monthly" when [isRecurrent] is true.
  final String? recurrenceLabel;

  const PassengerBookingListItem({
    required this.id,
    required this.tripId,
    required this.driverName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.totalPrice,
    required this.seatsBooked,
    required this.kind,
    this.isRecurrent = false,
    this.recurrenceLabel,
  });
}
