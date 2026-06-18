import 'package:flutter/material.dart';

class AddNewAddressScreen extends StatefulWidget {
  const AddNewAddressScreen({super.key});

  @override
  State<AddNewAddressScreen> createState() =>
      _AddNewAddressScreenState();
}

class _AddNewAddressScreenState
    extends State<AddNewAddressScreen> {

  String selectedType = "Home";

  @override
  Widget build(BuildContext context) {
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
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                          16),
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
            ),

            const SizedBox(height: 20),

            const Text(
              "Full Name",
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              decoration: InputDecoration(
                hintText:
                    "Enter your name",
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                          12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Mobile Number",
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              keyboardType:
                  TextInputType.phone,
              decoration: InputDecoration(
                hintText:
                    "Enter mobile number",
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                          12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Address",
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    "House no, area, landmark",
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                          12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Address Type",
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

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
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Address Saved Successfully ✅",
                      ),
                    ),
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepPurple,
                  foregroundColor:
                      Colors.white,
                ),
                child: const Text(
                  "Save Address",
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
  }

  Widget choiceChip(String title) {
    final bool isSelected =
        selectedType == title;

    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          selectedType = title;
        });
      },
    );
  }
}