import '../models/passenger_booking_list_item.dart';

/// Temporary mock lists for the passenger bookings screen until API wiring is ready.
class PassengerBookingsMock {
  PassengerBookingsMock._();

  static List<PassengerBookingListItem> awaitingYou() => [
        PassengerBookingListItem(
          id: 'mock-await-1',
          tripId: 't-await-1',
          driverName: 'Abebe Kebede',
          origin: 'Bole Airport',
          destination: 'Megenagna Square',
          departureTime: DateTime.now().add(const Duration(hours: 2)),
          totalPrice: 90,
          seatsBooked: 2,
          kind: PassengerBookingListKind.awaitingPassengerConfirmation,
        ),
        PassengerBookingListItem(
          id: 'mock-await-2',
          tripId: 't-await-2',
          driverName: 'Tigist Hailu',
          origin: 'Kazanchis',
          destination: 'CMC',
          departureTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
          totalPrice: 70,
          seatsBooked: 1,
          kind: PassengerBookingListKind.awaitingPassengerConfirmation,
        ),
      ];

  static List<PassengerBookingListItem> pendingDriver() => [
        PassengerBookingListItem(
          id: 'mock-pend-1',
          tripId: 't-pend-1',
          driverName: 'Dawit M.',
          origin: 'Piassa',
          destination: 'Ayat',
          departureTime: DateTime.now().add(const Duration(hours: 5)),
          totalPrice: 120,
          seatsBooked: 3,
          kind: PassengerBookingListKind.pendingDriverConfirmation,
        ),
        PassengerBookingListItem(
          id: 'mock-pend-2',
          tripId: 't-pend-2',
          driverName: 'Sara Tadesse',
          origin: 'Gerji',
          destination: 'Bole Medhanialem',
          departureTime: DateTime.now().add(const Duration(days: 2)),
          totalPrice: 45,
          seatsBooked: 1,
          kind: PassengerBookingListKind.pendingDriverConfirmation,
        ),
      ];

  static List<PassengerBookingListItem> active() => [
        PassengerBookingListItem(
          id: 'mock-act-1',
          tripId: 't-act-1',
          driverName: 'Yonas Girma',
          origin: 'Bole',
          destination: '4 Kilo',
          departureTime: DateTime.now().add(const Duration(minutes: 40)),
          totalPrice: 55,
          seatsBooked: 1,
          kind: PassengerBookingListKind.active,
        ),
        PassengerBookingListItem(
          id: 'mock-act-2',
          tripId: 't-act-2',
          driverName: 'Helen Bekele',
          origin: 'CMC',
          destination: 'Sarbet',
          departureTime: DateTime.now().add(const Duration(days: 1, hours: 7)),
          totalPrice: 280,
          seatsBooked: 2,
          kind: PassengerBookingListKind.active,
          isRecurrent: true,
          recurrenceLabel: 'Weekly',
        ),
        PassengerBookingListItem(
          id: 'mock-act-3',
          tripId: 't-act-3',
          driverName: 'Michael T.',
          origin: 'Merkato',
          destination: 'Lebu',
          departureTime: DateTime.now().add(const Duration(days: 3)),
          totalPrice: 900,
          seatsBooked: 1,
          kind: PassengerBookingListKind.active,
          isRecurrent: true,
          recurrenceLabel: 'Monthly',
        ),
      ];
}
