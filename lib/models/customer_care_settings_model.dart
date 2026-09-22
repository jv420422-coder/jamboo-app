class CustomerCareSettingsModel {
  final String phoneNumber;
  final String email;
  final String whatsappNumber;
  final bool callEnabled;
  final bool emailEnabled;
  final bool whatsappEnabled;

  const CustomerCareSettingsModel({
    this.phoneNumber = '',
    this.email = '',
    this.whatsappNumber = '',
    this.callEnabled = true,
    this.emailEnabled = true,
    this.whatsappEnabled = true,
  });

  factory CustomerCareSettingsModel.fromMap(
    Map<String, dynamic> data,
  ) {
    final customerApp =
        Map<String, dynamic>.from(
      data['customerApp'] as Map? ?? {},
    );

    return CustomerCareSettingsModel(
      phoneNumber:
          customerApp['phoneNumber']?.toString() ?? '',
      email:
          customerApp['email']?.toString() ?? '',
      whatsappNumber:
          customerApp['whatsappNumber']?.toString() ?? '',
      callEnabled:
          customerApp['callEnabled'] as bool? ?? true,
      emailEnabled:
          customerApp['emailEnabled'] as bool? ?? true,
      whatsappEnabled:
          customerApp['whatsappEnabled'] as bool? ?? true,
    );
  }
}