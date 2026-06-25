import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'my_orders_screen.dart';
import 'help_center_screen.dart';
import 'jamboo_wallet_screen.dart';
import 'saved_addresses_screen.dart';
import 'offers_coupons_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "👤 My Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text("User not found"),
            );
          }

          final user =
              snapshot.data!.data()
                  as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      const CircleAvatar(
                        radius: 40,
                        child: Icon(
                          Icons.person,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        user["name"] ?? "",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        user["email"] ?? "",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        user["phone"] ?? "",
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const EditProfileScreen(),
    ),
  );
},
    icon: const Icon(Icons.edit),
    label: const Text("Edit Profile"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
profileTile(
                  context,
                  "💰",
                  "Jamboo Wallet",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const JambooWalletScreen(),
                      ),
                    );
                  },
                ),

                profileTile(
                  context,
                  "📦",
                  "My Orders",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MyOrdersScreen(),
                      ),
                    );
                  },
                ),

                profileTile(
                  context,
                  "📍",
                  "Saved Addresses",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SavedAddressesScreen(),
                      ),
                    );
                  },
                ),

                profileTile(
                  context,
                  "🎁",
                  "Offers & Coupons",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const OffersCouponsScreen(),
                      ),
                    );
                  },
                ),

                profileTile(
                  context,
                  "🆘",
                  "Help Center",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const HelpCenterScreen(),
                      ),
                    );
                  },
                ),
profileTile(
                  context,
                  "⚙️",
                  "Settings",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SettingsScreen(),
                      ),
                    );
                  },
                ),

                profileTile(
                  context,
                  "🚪",
                  "Logout",
                  () async {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text(
                          "Are you sure you want to logout?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.deepPurple,
                              foregroundColor:
                                  Colors.white,
                            ),
                            child: const Text("Logout"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget profileTile(
    BuildContext context,
    String emoji,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Text(
          emoji,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
        title: Text(title),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
}