import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  // =========================
  // DELETE ACCOUNT
  // =========================
  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text("Delete Account"),
            ],
          ),
          content: const Text(
            "Are you sure you want to permanently delete your Jamboo account?\n\n"
            "Your profile, saved addresses, cart, ratings, notifications "
            "and other associated account data will be deleted.\n\n"
            "This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Color(0xFF7E57C2),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete Account"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF7E57C2),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    "Deleting your account...",
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final functions = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      );

      final callable =
          functions.httpsCallable('deleteCustomerAccount');

      await callable.call();

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();
      }

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();
      }

      if (!context.mounted) return;

      String message =
          "Unable to delete your account. Please try again.";

      if (e.code == 'unauthenticated') {
        message =
            "Your session has expired. Please login again.";
      } else if (e.message != null &&
          e.message!.isNotEmpty) {
        message = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Something went wrong. Please try again.",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D9FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF7E57C2),
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "My Profile",
              style: TextStyle(
                color: Color(0xFF171717),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              child: CircularProgressIndicator(
                color: Color(0xFF7E57C2),
              ),
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

          final name =
              (user["name"] ?? "").toString();

          final email =
              (user["email"] ?? "").toString();

          final phone =
              (user["phone"] ?? "").toString();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              24,
            ),
            child: Column(
              children: [
                // =========================
                // PREMIUM PROFILE CARD
                // =========================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8E5DE7),
                        Color(0xFF6840C2),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7E57C2)
                            .withValues(alpha: 0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // PROFILE AVATAR
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: 0.7),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 43,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 4,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isEmpty
                                        ? "Jamboo Customer"
                                        : name,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 7),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .email_outlined,
                                          color: Colors.white70,
                                          size: 15,
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ),
                                        Expanded(
                                          child: Text(
                                            email,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .phone_outlined,
                                          color: Colors.white70,
                                          size: 15,
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ),
                                        Text(
                                          phone,
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // EDIT PROFILE
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EditProfileScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 19,
                          ),
                          label: const Text(
                            "Edit Profile",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white,
                            foregroundColor:
                                const Color(0xFF6B43C6),
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // WALLET
                // =========================
                profileTile(
                  context,
                  icon: Icons
                      .account_balance_wallet_rounded,
                  title: "Jamboo Wallet",
                  subtitle:
                      "View balance, transactions and more",
                  iconBackground:
                      const Color(0xFFEDE3FF),
                  iconColor:
                      const Color(0xFF6B43C6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const JambooWalletScreen(),
                      ),
                    );
                  },
                ),

                // =========================
                // ORDERS
                // =========================
                profileTile(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: "My Orders",
                  subtitle:
                      "Track, reorder and view past orders",
                  iconBackground:
                      const Color(0xFFFFEAD8),
                  iconColor:
                      const Color(0xFFE67E22),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MyOrdersScreen(),
                      ),
                    );
                  },
                ),

                // =========================
                // SAVED ADDRESSES
                // =========================
                profileTile(
                  context,
                  icon: Icons.location_on_rounded,
                  title: "Saved Addresses",
                  subtitle:
                      "Manage your delivery addresses",
                  iconBackground:
                      const Color(0xFFFFE1E7),
                  iconColor:
                      const Color(0xFFE83E5B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SavedAddressesScreen(),
                      ),
                    );
                  },
                ),

                // =========================
                // OFFERS
                // =========================
                profileTile(
                  context,
                  icon: Icons.card_giftcard_rounded,
                  title: "Offers & Coupons",
                  subtitle:
                      "View latest offers and save more",
                  iconBackground:
                      const Color(0xFFE0F8EA),
                  iconColor:
                      const Color(0xFF1B9E57),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const OffersCouponsScreen(),
                      ),
                    );
                  },
                ),

                // =========================
                // HELP
                // =========================
                profileTile(
                  context,
                  icon: Icons.support_agent_rounded,
                  title: "Help Center",
                  subtitle:
                      "Get support and find answers",
                  iconBackground:
                      const Color(0xFFE2EDFF),
                  iconColor:
                      const Color(0xFF2563C9),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const HelpCenterScreen(),
                      ),
                    );
                  },
                ),

                // =========================
                // SETTINGS
                // =========================
                profileTile(
                  context,
                  icon: Icons.settings_rounded,
                  title: "Settings",
                  subtitle:
                      "App preferences and account settings",
                  iconBackground:
                      const Color(0xFFEDE3FF),
                  iconColor:
                      const Color(0xFF6B43C6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SettingsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 4),

                // =========================
                // LOGOUT
                // =========================
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius:
                        BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFD7D7),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(18),
                      onTap: () async {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              AlertDialog(
                            title:
                                const Text("Logout"),
                            content: const Text(
                              "Are you sure you want to logout?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  );
                                },
                                child: const Text(
                                  "Cancel",
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await FirebaseAuth
                                      .instance
                                      .signOut();

                                  Navigator
                                      .pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      const Color(
                                    0xFF7E57C2,
                                  ),
                                  foregroundColor:
                                      Colors.white,
                                ),
                                child:
                                    const Text(
                                  "Logout",
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    const Color(
                                  0xFFFFE0E0,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                        13),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.red,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    "Logout",
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight:
                                          FontWeight.bold,
                                      color: Color(
                                        0xFFC62828,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "Sign out from your account",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color:
                                          Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons
                                  .arrow_forward_ios_rounded,
                              color: Color(0xFFC62828),
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // =========================
                // DELETE ACCOUNT
                // =========================
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    top: 4,
                    bottom: 8,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(16),
                      onTap: () {
                        _deleteAccount(context);
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons
                                  .delete_forever_rounded,
                              color: Colors.red.shade400,
                              size: 18,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              "Delete Account",
                              style: TextStyle(
                                color:
                                    Colors.red.shade400,
                                fontSize: 12.5,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================
  // PREMIUM PROFILE TILE
  // =========================
  Widget profileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackground,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              FontWeight.bold,
                          color: Color(0xFF171717),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF6D6D6D),
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}