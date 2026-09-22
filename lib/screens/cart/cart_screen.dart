import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/cart_item_model.dart';
import '../../models/coupon_model.dart';
import '../../services/cart_service.dart';
import '../../services/coupon_service.dart';
import '../../services/billing_service.dart';
import '../../services/checkout_service.dart';

import '../home_screen.dart';
import '../saved_addresses_screen.dart';
import '../payment_screen.dart';
import '../offers_coupons_screen.dart';

import 'cart_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService cartService = CartService();

  bool couponApplied = false;
  String? appliedCoupon;
  double couponDiscount = 0;
  double appliedCouponMinimumOrderValue = 0;

  bool _couponRemovalScheduled = false;

  Future<List<CartItemModel>>? _suggestionsFuture;
  String? _suggestionsRestaurantId;

  @override
  void initState() {
    super.initState();
    _loadBusinessRules();
  }

  Future<void> _loadBusinessRules() async {
    await BillingService.loadBusinessRules();

    if (!mounted) return;

    setState(() {});
  }

  Future<List<CartItemModel>> _loadRestaurantSuggestions(
    String restaurantId,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("menu_items")
        .where(
          "restaurantId",
          isEqualTo: restaurantId,
        )
        .where(
          "isAvailable",
          isEqualTo: true,
        )
        .limit(20)
        .get();

    final List<CartItemModel> suggestions = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final imageUrl =
          (data["imageUrl"] ??
                  data["image"] ??
                  data["imageURL"] ??
                  data["photoUrl"] ??
                  "")
              .toString();

      suggestions.add(
        CartItemModel(
          id: doc.id,
          restaurantId:
              (data["restaurantId"] ?? restaurantId)
                  .toString(),
          restaurantName:
              (data["restaurantName"] ?? "")
                  .toString(),
          itemName:
              (data["name"] ?? "")
                  .toString(),
          description:
              (data["description"] ?? "")
                  .toString(),
          price:
              (data["price"] as num?)?.toDouble() ?? 0,
          quantity: 1,
          emoji:
              (data["emoji"] ?? "🍽️")
                  .toString(),
          imageUrl: imageUrl,
          preparationTime:
              (data["preparationTime"] ?? 20)
                  .toInt(),
        ),
      );
    }

    return suggestions;
  }

  void _prepareSuggestions(String restaurantId) {
    if (_suggestionsRestaurantId == restaurantId &&
        _suggestionsFuture != null) {
      return;
    }

    _suggestionsRestaurantId = restaurantId;

    _suggestionsFuture =
        _loadRestaurantSuggestions(restaurantId);
  }

  Future<void> _addSuggestionToCart(
    CartItemModel item,
  ) async {
    try {
      await cartService.addToCart(item);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${item.itemName} added to cart",
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to add item. Please try again.",
          ),
        ),
      );
    }
  }

  Future<void> _selectCoupon({
    required BuildContext context,
    required String restaurantId,
    required double itemsTotal,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OffersCouponsScreen(
          restaurantId: restaurantId,
          subtotal: itemsTotal,
        ),
      ),
    );

    if (result == null || result is! String) {
      return;
    }

    final couponCode = result.trim().toUpperCase();

    if (couponCode.isEmpty) {
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          "Please login to apply a coupon.",
        );
      }

      final CouponModel? coupon =
          await CouponService.instance.applyCoupon(
        couponCode: couponCode,
        restaurantId: restaurantId,
        cartAmount: itemsTotal,
        userId: user.uid,
      );

      if (coupon == null) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This coupon cannot be applied to your order.",
            ),
          ),
        );

        return;
      }

      final discount =
          CouponService.instance.calculateDiscount(
        coupon: coupon,
        cartAmount: itemsTotal,
      );

      if (discount <= 0) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This coupon does not provide a valid discount.",
            ),
          ),
        );

        return;
      }

      if (!context.mounted) return;

      setState(() {
        appliedCoupon = coupon.code;
        couponApplied = true;
        couponDiscount = discount;
        appliedCouponMinimumOrderValue =
            coupon.minimumOrderValue;
      });

      CheckoutService.instance.appliedCouponCode =
          coupon.code;
      CheckoutService.instance.couponApplied = true;
      CheckoutService.instance.couponDiscount =
          discount;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${coupon.code} applied successfully. "
            "You saved ₹${discount.toStringAsFixed(0)}.",
          ),
        ),
      );
    } on Exception catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to apply coupon. Please try again.",
          ),
        ),
      );
    }
  }

  void _removeCoupon({
    bool showMessage = false,
  }) {
    final removedCoupon = appliedCoupon;

    setState(() {
      appliedCoupon = null;
      couponApplied = false;
      couponDiscount = 0;
      appliedCouponMinimumOrderValue = 0;
    });

    CheckoutService.instance.appliedCouponCode = null;
    CheckoutService.instance.couponApplied = false;
    CheckoutService.instance.couponDiscount = 0;

    if (showMessage &&
        mounted &&
        removedCoupon != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Coupon removed because the minimum order value is no longer met.",
          ),
        ),
      );
    }
  }

  void _scheduleCouponRemoval() {
    if (_couponRemovalScheduled) {
      return;
    }

    _couponRemovalScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _couponRemovalScheduled = false;

      if (!mounted || !couponApplied) {
        return;
      }

      _removeCoupon(showMessage: true);
    });
  }

  bool _isValidAddress(Map<String, dynamic>? address) {
    if (address == null) {
      return false;
    }

    final fullName =
        (address["fullName"] ?? "").toString().trim();

    final phone =
        (address["phone"] ?? "").toString().trim();

    final fullAddress =
        (address["address"] ?? "").toString().trim();

    final city =
        (address["city"] ?? "").toString().trim();

    final state =
        (address["state"] ?? "").toString().trim();

    final pincode =
        (address["pincode"] ?? "").toString().trim();

    final latitude =
        (address["latitude"] as num?)?.toDouble();

    final longitude =
        (address["longitude"] as num?)?.toDouble();

    return fullName.isNotEmpty &&
        phone.isNotEmpty &&
        fullAddress.isNotEmpty &&
        city.isNotEmpty &&
        state.isNotEmpty &&
        pincode.isNotEmpty &&
        latitude != null &&
        longitude != null;
  }

  Future<void> _showAddressRequiredPopup() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.deepPurple,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Add Delivery Address",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            "Please add your delivery address before continuing with your order.",
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SavedAddressesScreen(
                      isCheckoutMode: true,
                    ),
                  ),
                );
              },
              child: const Text(
                "Add Address",
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _proceedToCheckout({
    required BuildContext context,
    required bool couponApplied,
    required String? couponCode,
    required double couponDiscount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please login to continue.",
          ),
        ),
      );

      return;
    }

    try {
      final addressSnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .collection("addresses")
              .where(
                "selectedForCheckout",
                isEqualTo: true,
              )
              .limit(1)
              .get();

      if (addressSnapshot.docs.isEmpty) {
        await _showAddressRequiredPopup();
        return;
      }

      final address =
          addressSnapshot.docs.first.data();

      if (!_isValidAddress(address)) {
        await _showAddressRequiredPopup();
        return;
      }

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            couponApplied: couponApplied,
            couponCode: couponCode,
            couponDiscount: couponDiscount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to verify your delivery address. Please try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: cartService.cartStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final List<CartItemModel> cartItems = [];

        double itemsTotal = 0;
        int totalItems = 0;

        for (final doc in docs) {
          final item = CartItemModel.fromMap(
            doc.data() as Map<String, dynamic>,
          );

          cartItems.add(item);
          totalItems += item.quantity;
          itemsTotal += item.price * item.quantity;
        }

        final String? restaurantId =
            cartItems.isNotEmpty
                ? cartItems.first.restaurantId
                : null;

        if (restaurantId != null) {
          _prepareSuggestions(restaurantId);
        } else {
          _suggestionsFuture = null;
          _suggestionsRestaurantId = null;
        }

        if (couponApplied &&
            itemsTotal <
                appliedCouponMinimumOrderValue) {
          _scheduleCouponRemoval();
        }

        final bool effectiveCouponApplied =
            couponApplied &&
            itemsTotal >=
                appliedCouponMinimumOrderValue;

        final double effectiveCouponDiscount =
            effectiveCouponApplied
                ? couponDiscount
                : 0;

        final bill = BillingService.calculateBill(
          itemsTotal: itemsTotal,
          couponDiscount:
              effectiveCouponDiscount,
          couponCode:
              effectiveCouponApplied
                  ? appliedCoupon
                  : null,
        );

        final user =
            FirebaseAuth.instance.currentUser;

        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                "Please login to continue.",
              ),
            ),
          );
        }

        final uid = user.uid;

        return Scaffold(
          backgroundColor:
              const Color(0xFFF5F0FF),
          appBar: AppBar(
            backgroundColor:
                const Color(0xFFF5F0FF),
            elevation: 0,
            title: const Text(
              "🛒 Your Cart",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: totalItems == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text(
                        "😕",
                        style: TextStyle(
                          fontSize: 80,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Your Cart Is Empty",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Let's find something delicious",
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const HomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Browse Food",
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore
                                  .instance
                                  .collection("users")
                                  .doc(uid)
                                  .collection(
                                      "addresses")
                                  .where(
                                    "selectedForCheckout",
                                    isEqualTo: true,
                                  )
                                  .limit(1)
                                  .snapshots(),
                          builder:
                              (context,
                                  addressSnapshot) {
                            if (!addressSnapshot
                                .hasData) {
                              return const Center(
                                child:
                                    CircularProgressIndicator(),
                              );
                            }

                            Map<String, dynamic>?
                                address;

                            if (addressSnapshot
                                .data!
                                .docs
                                .isNotEmpty) {
                              address =
                                  addressSnapshot
                                          .data!
                                          .docs
                                          .first
                                          .data()
                                      as Map<String,
                                          dynamic>;
                            }

                            final bool hasValidAddress =
                                address != null &&
                                _isValidAddress(address);

                            return Container(
                              margin:
                                  const EdgeInsets.only(
                                bottom: 16,
                              ),
                              padding:
                                  const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color:
                                        hasValidAddress
                                            ? Colors
                                                .deepPurple
                                            : Colors
                                                .redAccent,
                                  ),
                                  const SizedBox(
                                      width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        const Text(
                                          "Deliver To",
                                          style: TextStyle(
                                            color:
                                                Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 4),
                                        if (address !=
                                                null &&
                                            hasValidAddress) ...[
                                          Text(
                                            address[
                                                    "fullName"] ??
                                                "",
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                          Text(
                                            "${address["address"] ?? ""}\n"
                                            "${address["city"] ?? ""}",
                                          ),
                                        ] else ...[
                                          const Text(
                                            "Add delivery address",
                                            style:
                                                TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              color: Colors
                                                  .redAccent,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: 2),
                                          const Text(
                                            "Required before checkout",
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SavedAddressesScreen(
                                            isCheckoutMode:
                                                true,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      hasValidAddress
                                          ? "Change"
                                          : "Add",
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        ...cartItems.map(
                          (item) => CartItemCard(
                            item: item,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Container(
                          padding:
                              const EdgeInsets.all(16),
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_offer,
                                color:
                                    Colors.deepPurple,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Text(
                                      "Apply Coupon",
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      effectiveCouponApplied
                                          ? "✅ $appliedCoupon Applied"
                                          : "Apply an available coupon",
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      effectiveCouponApplied
                                          ? "You saved ₹${effectiveCouponDiscount.toStringAsFixed(0)}"
                                          : "Save more on your order",
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    restaurantId == null
                                        ? null
                                        : () async {
                                            if (effectiveCouponApplied) {
                                              _removeCoupon();
                                              return;
                                            }

                                            await _selectCoupon(
                                              context:
                                                  context,
                                              restaurantId:
                                                  restaurantId,
                                              itemsTotal:
                                                  itemsTotal,
                                            );
                                          },
                                child: Text(
                                  effectiveCouponApplied
                                      ? "Remove"
                                      : "View",
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        if (restaurantId != null)
                          _buildRestaurantSuggestions(
                            cartItems,
                          ),

                        const SizedBox(height: 20),

                        const Divider(),

                        BillRow(
                          title: "Items Total",
                          value:
                              "₹${bill.itemsTotal.toStringAsFixed(0)}",
                        ),

                        if (effectiveCouponApplied)
                          BillRow(
                            title:
                                "Coupon Discount",
                            value:
                                "-₹${bill.couponDiscount.toStringAsFixed(0)}",
                          ),

                        BillRow(
                          title: "Delivery Fee",
                          value:
                              "₹${bill.deliveryFee.toStringAsFixed(0)}",
                        ),

                        BillRow(
                          title: "Platform Fee",
                          value:
                              "₹${bill.platformFee.toStringAsFixed(0)}",
                        ),

                        const Divider(),

                        BillRow(
                          title: "Grand Total",
                          value:
                              "₹${bill.grandTotal.toStringAsFixed(0)}",
                          bold: true,
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: restaurantId == null
                                ? null
                                : () {
                                    _proceedToCheckout(
                                      context: context,
                                      couponApplied:
                                          effectiveCouponApplied,
                                      couponCode:
                                          effectiveCouponApplied
                                              ? appliedCoupon
                                              : null,
                                      couponDiscount:
                                          effectiveCouponDiscount,
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
                              "Proceed to Checkout",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildRestaurantSuggestions(
    List<CartItemModel> cartItems,
  ) {
    if (_suggestionsFuture == null) {
      return const SizedBox.shrink();
    }

    final cartIds =
        cartItems.map((item) => item.id).toSet();

    return FutureBuilder<List<CartItemModel>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SizedBox(
            height: 190,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final suggestions =
            snapshot.data!
                .where(
                  (item) =>
                      !cartIds.contains(item.id),
                )
                .take(6)
                .toList();

        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius:
                        BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "You might also like",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "More delicious choices from this restaurant",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 235,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                separatorBuilder:
                    (_, __) =>
                        const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item =
                      suggestions[index];

                  return _SuggestionCard(
                    item: item,
                    onAdd: () {
                      _addSuggestionToCart(item);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onAdd;

  const _SuggestionCard({
    required this.item,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.07,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 112,
            width: double.infinity,
            child: item.imageUrl.trim().isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return _imageFallback();
                    },
                  )
                : _imageFallback(),
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                10,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    "₹${item.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.deepPurple,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF3EEFF),
      alignment: Alignment.center,
      child: Text(
        item.emoji,
        style: const TextStyle(
          fontSize: 42,
        ),
      ),
    );
  }
}