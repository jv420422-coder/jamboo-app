import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/address_model.dart';
import '../../services/address_service.dart';

import '../payment_screen.dart';
import 'address_widgets.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() =>
      _AddressScreenState();
}

class _AddressScreenState
    extends State<AddressScreen> {

  final AddressService addressService =
      AddressService();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  String selectedType = "Home";

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(

      stream: addressService.addressStream(),

      builder: (context, snapshot) {

        List<AddressModel> addresses = [];

        if (snapshot.hasData) {

          addresses = snapshot.data!.docs
              .map(
                (doc) => AddressModel.fromMap(
                  doc.data()
                      as Map<String, dynamic>,
                ),
              )
              .toList();
        }

        return Scaffold(

          backgroundColor:
              const Color(0xFFF5F0FF),

          appBar: AppBar(

            backgroundColor:
                const Color(0xFFF5F0FF),

            elevation: 0,

            title: const Text(
              "📍 Delivery Address",
              style: TextStyle(
                color: Colors.black,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

          ),

          body: SingleChildScrollView(

            padding:
                const EdgeInsets.all(20),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Container(

                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(16),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                  ),

                  child: const Row(

                    children: [

                      Icon(
                        Icons.my_location,
                        color:
                            Colors.deepPurple,
                      ),

                      SizedBox(width: 10),

                      Text(
                        "Use Current Location",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                    ],

                  ),

                ),

                const SizedBox(height: 20),

                ...addresses.map(
                  (address) => AddressCard(
                    title:
                        address.type == "Home"
                            ? "🏠 Home"
                            : address.type ==
                                    "Work"
                                ? "🏢 Work"
                                : "📍 Other",
                    name: address.fullName,
                    phone: address.phone,
                    address: address.address,
                    selected:
                        address.isDefault,
                    onTap: () {
                      // Part 2 me
                      // Default Address
                    },
                  ),
                ),

                const SizedBox(height: 20),

                const SectionTitle(
                  title: "Full Name",
                ),

                AddressTextField(
                  controller:
                      nameController,
                  hint:
                      "Enter your name",
                ),

                const SizedBox(height: 20),

                const SectionTitle(
                  title:
                      "Mobile Number",
                ),

                AddressTextField(
                  controller:
                      phoneController,
                  hint:
                      "Enter mobile number",
                  keyboardType:
                      TextInputType.phone,
                ),

                const SizedBox(height: 20),

                const SectionTitle(
                  title: "Address",
                ),

                AddressTextField(
                  controller:
                      addressController,
                  hint:
                      "House No, Area, Landmark",
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                const SectionTitle(
                  title: "Address Type",
                ),

                Wrap(
                  spacing: 10,
                  children: [
AddressTypeChip(
                  title: "Home",
                  selected: selectedType == "Home",
                  onTap: () {
                    setState(() {
                      selectedType = "Home";
                    });
                  },
                ),

                AddressTypeChip(
                  title: "Work",
                  selected: selectedType == "Work",
                  onTap: () {
                    setState(() {
                      selectedType = "Work";
                    });
                  },
                ),

                AddressTypeChip(
                  title: "Other",
                  selected: selectedType == "Other",
                  onTap: () {
                    setState(() {
                      selectedType = "Other";
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {

                  final address = AddressModel(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    fullName:
                        nameController.text.trim(),
                    phone:
                        phoneController.text.trim(),
                    address:
                        addressController.text.trim(),
                    type: selectedType,
                    isDefault: true,
                  );

                  await addressService
                      .saveAddress(address);

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const PaymentScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepPurple,
                  foregroundColor:
                      Colors.white,
                ),
                child: const Text(
                  "Continue to Payment",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}