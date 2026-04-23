import '../../../core/constants/enums.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final bool emailVerified;
  final String phone;
  final String nationalId;
  final String? image;
  final UserStatus status;
  final UserRole role;
  final double rating;
  final bool banned;

  // Linked Passenger record
  final String? passengerId;
  final List<String>? preferredRoutes;

  // Linked Driver record
  final String? driverId;
  final String? licenseNumber;
  final String? vehicleModel;
  final String? vehiclePlate;
  final int? vehicleSeats;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerified = false,
    this.phone = '',
    this.nationalId = '',
    this.image,
    required this.status,
    required this.role,
    this.rating = 0.0,
    this.banned = false,
    this.passengerId,
    this.preferredRoutes,
    this.driverId,
    this.licenseNumber,
    this.vehicleModel,
    this.vehiclePlate,
    this.vehicleSeats,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final passenger = json['passenger'] as Map<String, dynamic>?;
    final driver = json['driver'] as Map<String, dynamic>?;
    final topLevelPassengerId = json['passengerId'] as String?;
    final topLevelDriverId = json['driverId'] as String?;

    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
      phone: json['phone'] as String? ?? '',
      nationalId: json['nationalId'] as String? ?? '',
      image: json['image'] as String?,
      status: _parseStatus(json['status'] as String?),
      role: _parseRole(json['role'] as String?),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      banned: json['banned'] as bool? ?? false,
      passengerId: passenger?['id'] as String? ?? topLevelPassengerId,
      preferredRoutes:
          (passenger?['prefferedRoutes'] as List?)?.cast<String>(),
      driverId: driver?['id'] as String? ?? topLevelDriverId,
      licenseNumber: driver?['licenseNumber'] as String?,
      vehicleModel: driver?['vehicleModel'] as String?,
      vehiclePlate: driver?['vehiclePlate'] as String?,
      vehicleSeats: driver?['vehicleSeats'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'emailVerified': emailVerified,
      'phone': phone,
      'nationalId': nationalId,
      'image': image,
      'status': status.name,
      'role': role.name,
      'rating': rating,
      'banned': banned,
      'passengerId': passengerId,
      'driverId': driverId,
      'licenseNumber': licenseNumber,
      'vehicleModel': vehicleModel,
      'vehiclePlate': vehiclePlate,
      'vehicleSeats': vehicleSeats,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? image,
    UserStatus? status,
    UserRole? role,
    String? vehicleModel,
    String? vehiclePlate,
    int? vehicleSeats,
    List<String>? preferredRoutes,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      emailVerified: emailVerified,
      phone: phone ?? this.phone,
      nationalId: nationalId,
      image: image ?? this.image,
      status: status ?? this.status,
      role: role ?? this.role,
      rating: rating,
      banned: banned,
      passengerId: passengerId,
      preferredRoutes: preferredRoutes ?? this.preferredRoutes,
      driverId: driverId,
      licenseNumber: licenseNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleSeats: vehicleSeats ?? this.vehicleSeats,
    );
  }

  bool get isDriver => role == UserRole.driver;
  bool get isPassenger => role == UserRole.passenger;
  bool get isActive => status == UserStatus.active;
  bool get isPending => status == UserStatus.pending;

  static UserStatus _parseStatus(String? s) {
    switch (s) {
      case 'active':
        return UserStatus.active;
      case 'pending':
        return UserStatus.pending;
      case 'deactivated':
        return UserStatus.deactivated;
      default:
        return UserStatus.pending;
    }
  }

  static UserRole _parseRole(String? r) {
    switch (r) {
      case 'driver':
        return UserRole.driver;
      case 'admin':
        return UserRole.admin;
      case 'passenger':
      default:
        return UserRole.passenger;
    }
  }
}
