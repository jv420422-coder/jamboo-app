import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddNewAddressScreen extends StatefulWidget {

  final String? documentId;
  final Map<String, dynamic>? addressData;

  const AddNewAddressScreen({
    super.key,
    this.documentId,
    this.addressData,
  });

  @override
  State<AddNewAddressScreen> createState() =>
      _AddNewAddressScreenState();
}


class _AddNewAddressScreenState
    extends State<AddNewAddressScreen> {

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final landmarkController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  String selectedType = "Home";
  Future<void> getCurrentLocation() async {

  bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enable Location"),
      ),
    );
    return;
  }

  LocationPermission permission =
      await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission =
        await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Location Permission Denied"),
      ),
    );
    return;
  }

  Position position =
      await Geolocator.getCurrentPosition();

  try {

  const apiKey = "AIzaSyATVKIrhaNIbGulsfeLEnP5Tzukqnc3m_s";

  final url =
      "https://maps.googleapis.com/maps/api/geocode/json"
      "?latlng=${position.latitude},${position.longitude}"
      "&key=$apiKey";

  final response = await http.get(Uri.parse(url));

  final data = jsonDecode(response.body);

  if (data["status"] == "OK") {

    final result = data["results"][0];

    addressController.text =
        result["formatted_address"];

  } else {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
  "${data["status"]}\n${data["error_message"] ?? ""}",
),
      ),
    );
  }

} catch (e) {

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString()),
    ),
  );
}
}

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {

      final data = doc.data()!;

      nameController.text = data["name"] ?? "";
      phoneController.text = data["phone"] ?? "";
    }
    if (widget.addressData != null) {

  final address = widget.addressData!;

  nameController.text = address["fullName"] ?? "";
  phoneController.text = address["phone"] ?? "";

  addressController.text = address["address"] ?? "";
  landmarkController.text = address["landmark"] ?? "";
  cityController.text = address["city"] ?? "";
  stateController.text = address["state"] ?? "";
  pincodeController.text = address["pincode"] ?? "";

  selectedType = address["type"] ?? "Home";
}

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "➕ Add New Address",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            InkWell(
  onTap: () async {
    await getCurrentLocation();
  },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [

                    Icon(
                      Icons.my_location,
                      color: Colors.deepPurple,
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
            ),

            const SizedBox(height: 20),
const Text(
              "Full Name",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Enter your name",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Mobile Number",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Enter mobile number",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Address",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "House No, Area, Street",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: landmarkController,
              decoration: InputDecoration(
                labelText: "Landmark",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: cityController,
                    decoration: InputDecoration(
                      labelText: "City",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: stateController,
                    decoration: InputDecoration(
                      labelText: "State",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: pincodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Pincode",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Address Type",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: [
                choiceChip("Home"),
                choiceChip("Work"),
                choiceChip("Other"),
              ],
            ),

            const SizedBox(height: 30),
SizedBox(
  width: double.infinity,
  height: 55,
  child: ElevatedButton(
    onPressed: isSaving
        ? null
        : () async {

            if (nameController.text.isEmpty ||
                phoneController.text.isEmpty ||
                addressController.text.isEmpty ||
                cityController.text.isEmpty ||
                stateController.text.isEmpty ||
                pincodeController.text.isEmpty) {

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Please fill all required fields",
                  ),
                ),
              );

              return;
            }

            setState(() {
              isSaving = true;
            });

            final uid =
                FirebaseAuth.instance.currentUser!.uid;

             print("SAVE BUTTON CLICKED");
            final addressData = {
  "fullName": nameController.text.trim(),
  "phone": phoneController.text.trim(),
  "address": addressController.text.trim(),
  "landmark": landmarkController.text.trim(),
  "city": cityController.text.trim(),
  "state": stateController.text.trim(),
  "pincode": pincodeController.text.trim(),
  "type": selectedType,

  if (widget.documentId == null)
    "createdAt": FieldValue.serverTimestamp(),
};

if (widget.documentId == null) {

  print("NEW ADDRESS SAVED");

  await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .collection("addresses")
      .add(addressData);

} else {

  print("ADDRESS UPDATED");

  await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .collection("addresses")
      .doc(widget.documentId)
      .update(addressData);

}
            print("ADDRESS SAVED");

            setState(() {
              isSaving = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Address Saved Successfully ✅",
                  ),
                ),
              );

              Navigator.pop(context);
            }
        },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
    ),
    child: isSaving
        ? const CircularProgressIndicator(
            color: Colors.white,
          )
        : const Text(
            "Save Address",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
  ),
),

const SizedBox(height: 20),
],
        ),
      ),
    );
  }

  Widget choiceChip(String title) {
    final bool isSelected = selectedType == title;

    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          selectedType = title;
        });
      },
      selectedColor: Colors.deepPurple.shade100,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    landmarkController.dispose();
    super.dispose();
  }
}