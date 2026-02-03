class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final regex = RegExp(r'^\+?[0-9]{9,13}$');
    if (!regex.hasMatch(value)) return 'Enter a valid phone number';
    return null;
  }

  static String? vehiclePlate(String? value) {
    if (value == null || value.isEmpty) return 'Vehicle plate is required';
    if (value.length < 4) return 'Enter a valid plate number';
    return null;
  }

  static String? seats(String? value) {
    if (value == null || value.isEmpty) return 'Number of seats is required';
    final seats = int.tryParse(value);
    if (seats == null || seats < 1 || seats > 10) {
      return 'Seats must be between 1 and 10';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    final price = double.tryParse(value);
    if (price == null || price <= 0) return 'Enter a valid price';
    return null;
  }
}
