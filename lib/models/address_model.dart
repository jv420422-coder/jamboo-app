class AddressModel {
  final String id;
  final String fullName;
  final String phone;
  final String address;
  final String type;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.type,
    required this.isDefault,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "fullName": fullName,
      "phone": phone,
      "address": address,
      "type": type,
      "isDefault": isDefault,
    };
  }

  factory AddressModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AddressModel(
      id: map["id"] ?? "",
      fullName: map["fullName"] ?? "",
      phone: map["phone"] ?? "",
      address: map["address"] ?? "",
      type: map["type"] ?? "Home",
      isDefault: map["isDefault"] ?? false,
    );
  }
}