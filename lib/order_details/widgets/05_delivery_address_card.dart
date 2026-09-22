import 'package:flutter/material.dart';

import '../../models/order_model.dart';

class DeliveryAddressCard extends StatelessWidget {
  final OrderModel order;

  const DeliveryAddressCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final address = order.deliveryAddress;

    final label = _getValue(
      address,
      [
        "label",
        "addressType",
        "type",
        "name",
      ],
    );

    final fullName = _getValue(
      address,
      [
        "fullName",
        "name",
        "customerName",
      ],
    );

    final addressLine = _getValue(
      address,
      [
        "address",
        "addressLine",
        "street",
        "fullAddress",
      ],
    );

    final city = _getValue(
      address,
      [
        "city",
        "town",
      ],
    );

    final state = _getValue(
      address,
      [
        "state",
        "stateName",
      ],
    );

    final pincode = _getValue(
      address,
      [
        "pincode",
        "pinCode",
        "postalCode",
        "zipCode",
      ],
    );

    final formattedAddress =
        _buildAddress(
      addressLine: addressLine,
      city: city,
      state: state,
      pincode: pincode,
    );

    final displayLabel =
        label.isNotEmpty
            ? label
            : "Home";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF0),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.red,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Delivery Address",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF171717),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFF3EEFF),
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.home_rounded,
                            size: 14,
                            color:
                                Color(0xFF7E57C2),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            displayLabel,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(0xFF7E57C2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (fullName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],

                if (formattedAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    formattedAddress,
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color:
                          Colors.grey.shade700,
                    ),
                  ),
                ],

                if (formattedAddress.isEmpty &&
                    fullName.isEmpty)
                  Text(
                    "Delivery address unavailable",
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().toLowerCase() !=
              "null") {
        return value.toString().trim();
      }
    }

    return "";
  }

  String _buildAddress({
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
  }) {
    final parts = <String>[];

    if (addressLine.isNotEmpty) {
      parts.add(addressLine);
    }

    final locationParts = <String>[];

    if (city.isNotEmpty) {
      locationParts.add(city);
    }

    if (state.isNotEmpty) {
      locationParts.add(state);
    }

    if (pincode.isNotEmpty) {
      locationParts.add(pincode);
    }

    if (locationParts.isNotEmpty) {
      parts.add(locationParts.join(", "));
    }

    return parts.join("\n");
  }
}