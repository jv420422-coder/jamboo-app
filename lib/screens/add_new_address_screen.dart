import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  double? _latitude;
  double? _longitude;

  bool isLoading = true;
  bool isSaving = false;
  bool isGettingLocation = false;

  String selectedType = "Home";

  // Original address values are used to determine
  // whether a saved address has actually changed.
  String _originalAddress = "";
  String _originalCity = "";
  String _originalState = "";
  String _originalPincode = "";

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<void> getCurrentLocation() async {
    if (isGettingLocation || isSaving) return;

    setState(() {
      isGettingLocation = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception("Please enable Location.");
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Location permission denied.");
      }

      // Get device's current GPS coordinates.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      // Preserve actual GPS coordinates.
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Reverse geocode through Firebase Cloud Function.
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('getAddressFromCoordinates');

      final response = await callable.call({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      final data = Map<String, dynamic>.from(
        response.data as Map,
      );

      if (!mounted) return;

      // Fill the existing address fields.
      addressController.text =
          (data['address'] ?? '').toString();

      cityController.text =
          (data['city'] ?? '').toString();

      stateController.text =
          (data['state'] ?? '').toString();

      pincodeController.text =
          (data['pincode'] ?? '').toString();

      landmarkController.text =
          (data['landmark'] ?? '').toString();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Current location added successfully ✅",
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                "Unable to get address. Please try again.",
          ),
        ),
      );

      debugPrint(
        "CURRENT LOCATION FUNCTION ERROR: "
        "${e.code} - ${e.message}",
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );

      debugPrint("GET CURRENT LOCATION ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          isGettingLocation = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // ============================================================
  // LOAD USER AND EXISTING ADDRESS
  // ============================================================

  Future<void> loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("Please login again.");
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
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

        _latitude =
            (address["latitude"] as num?)?.toDouble();

        _longitude =
            (address["longitude"] as num?)?.toDouble();

        selectedType = address["type"] ?? "Home";

        // Remember the original address and coordinates.
        _originalAddress = addressController.text.trim();
        _originalCity = cityController.text.trim();
        _originalState = stateController.text.trim();
        _originalPincode = pincodeController.text.trim();
      }
    } catch (e) {
      debugPrint("LOAD USER ERROR: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to load address details."),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // GET COORDINATES FROM MANUALLY ENTERED ADDRESS
  // ============================================================

  Future<Map<String, dynamic>> getCoordinatesFromAddress({
    required String address,
    required String city,
    required String state,
    required String pincode,
  }) async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-south1',
    ).httpsCallable('getCoordinatesFromAddress');

    final response = await callable.call({
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
    });

    final data = Map<String, dynamic>.from(
      response.data as Map,
    );

    final latitude = data['latitude'];
    final longitude = data['longitude'];

    if (data['success'] != true ||
        latitude is! num ||
        longitude is! num) {
      throw Exception(
        "Coordinates could not be found. "
        "Please check your address.",
      );
    }

    return {
      'latitude': latitude.toDouble(),
      'longitude': longitude.toDouble(),
    };
  }

  // ============================================================
  // SAVE ADDRESS
  // ============================================================

  Future<void> saveAddress() async {
    if (isSaving || isGettingLocation) return;

    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        stateController.text.trim().isEmpty ||
        pincodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("Please login again.");
      }

      final address = addressController.text.trim();
      final city = cityController.text.trim();
      final state = stateController.text.trim();
      final pincode = pincodeController.text.trim();

      final addressUnchanged =
          widget.documentId != null &&
          address == _originalAddress &&
          city == _originalCity &&
          state == _originalState &&
          pincode == _originalPincode;

      // If the address was not changed, retain its existing
      // coordinates. Otherwise, geocode the new address.
      if (!addressUnchanged) {
        final coordinates = await getCoordinatesFromAddress(
          address: address,
          city: city,
          state: state,
          pincode: pincode,
        );

        _latitude = coordinates['latitude'] as double;
        _longitude = coordinates['longitude'] as double;
      }

      // Do not save an address without valid coordinates.
      if (_latitude == null || _longitude == null) {
        throw Exception(
          "Location coordinates are missing. "
          "Please use Current Location or check your address.",
        );
      }

      final addressData = <String, dynamic>{
        "fullName": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "address": address,
        "landmark": landmarkController.text.trim(),
        "city": city,
        "state": state,
        "pincode": pincode,
        "type": selectedType,
        "latitude": _latitude,
        "longitude": _longitude,

        if (widget.documentId == null)
          "createdAt": FieldValue.serverTimestamp(),
      };

      final addressesRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("addresses");

      if (widget.documentId == null) {
        await addressesRef.add(addressData);
      } else {
        await addressesRef
            .doc(widget.documentId)
            .update(addressData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Address Saved Successfully ✅"),
        ),
      );

      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                "Unable to find location. Please check your address.",
          ),
        ),
      );

      debugPrint(
        "ADDRESS COORDINATES ERROR: ${e.code} - ${e.message}",
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );

      debugPrint("SAVE ADDRESS ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            InkWell(
              onTap: (isGettingLocation || isSaving)
                  ? null
                  : getCurrentLocation,

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Row(
                  children: [
                    if (isGettingLocation)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.deepPurple,
                        ),
                      )
                    else
                      const Icon(
                        Icons.my_location,
                        color: Colors.deepPurple,
                      ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        isGettingLocation
                            ? "Getting your location..."
                            : "Use Current Location",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
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
                        borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(12),
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
                onPressed: (isSaving || isGettingLocation)
                    ? null
                    : saveAddress,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),

                child: isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text("Finding location & saving..."),
                        ],
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

  // ============================================================
  // ADDRESS TYPE
  // ============================================================

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