import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {

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
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFFF5F0FF),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            const CircleAvatar(
              radius: 45,
              child: Icon(
                Icons.person,
                size: 45,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),
SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() {
                          isSaving = true;
                        });

                        final uid =
                            FirebaseAuth.instance.currentUser!.uid;

                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(uid)
                            .update({
                          "name": nameController.text.trim(),
                          "phone": phoneController.text.trim(),
                        });

                        setState(() {
                          isSaving = false;
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Profile Updated Successfully",
                              ),
                            ),
                          );

                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}