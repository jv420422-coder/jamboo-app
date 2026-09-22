import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart/cart_screen.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState
    extends State<RestaurantDetailsScreen> {
  String selectedFilter = "all";

  final CartService cartService = CartService();

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get restaurantStream {
    return FirebaseFirestore.instance
        .collection("restaurant_registrations")
        .doc(widget.restaurantId)
        .snapshots();
  }

  Stream<int> get totalItems => cartService.totalItems();

  Stream<double> get totalPrice => cartService.totalPrice();

  List<QueryDocumentSnapshot> _filterMenuItems(
    List<QueryDocumentSnapshot> docs,
  ) {
    switch (selectedFilter) {
      case "bestseller":
        return docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data["isBestseller"] == true;
        }).toList();

      case "veg":
        return docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data["isVeg"] == true;
        }).toList();

      case "nonveg":
        return docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data["isVeg"] == false;
        }).toList();

      case "under99":
        return docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final price = (data["price"] ?? 0) as num;
          return price < 99;
        }).toList();

      case "under199":
        return docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final price = (data["price"] ?? 0) as num;
          return price < 199;
        }).toList();

      case "all":
      default:
        return docs;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      bottomNavigationBar: StreamBuilder<int>(
        stream: totalItems,
        builder: (context, itemSnapshot) {
          return StreamBuilder<double>(
            stream: totalPrice,
            builder: (context, priceSnapshot) {
              final items = itemSnapshot.data ?? 0;
              final total = priceSnapshot.data ?? 0;

              if (items == 0) {
                return const SizedBox();
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "🛒 $items Items | ₹${total.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CartScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor:
                            Colors.deepPurple,
                      ),
                      child: const Text(
                        "View Cart",
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                StreamBuilder<
                    DocumentSnapshot<
                        Map<String, dynamic>>>(
                  stream: restaurantStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final data =
                        snapshot.data!.data() ?? {};

                    final coverPhotoUrl =
                        data["coverPhotoUrl"] as String?;

                    if (coverPhotoUrl != null &&
                        coverPhotoUrl.isNotEmpty) {
                      return CachedNetworkImage(
                        imageUrl: coverPhotoUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        placeholder: (context, url) {
                          return Container(
                            width: double.infinity,
                            height: 250,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorWidget:
                            (context, url, error) {
                          return Container(
                            width: double.infinity,
                            height: 250,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      );
                    }

                    return Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: StreamBuilder<
                  DocumentSnapshot<
                      Map<String, dynamic>>>(
                stream: restaurantStream,
                builder: (context, snapshot) {
                  final data =
                      snapshot.data?.data() ?? {};

                  final isOpen =
                      data["isOpen"] == true;

                  final totalRatings =
                      (data["totalRatings"] ?? 0) as num;

                  final averageRating =
                      (data["averageRating"] ?? 0) as num;

                  final estimatedDeliveryTime =
                      (data["estimatedDeliveryTime"] ??
                              30)
                          as num;

                  final ratingText =
                      totalRatings > 0
                          ? averageRating
                              .toStringAsFixed(1)
                          : "New";

                  final address =
                      data["address"] ?? "";

                  final city =
                      data["city"] ?? "";

                  final state =
                      data["state"] ?? "";

                  final location = [
                    address,
                    city,
                    state,
                  ]
                      .where(
                        (value) => value
                            .toString()
                            .trim()
                            .isNotEmpty,
                      )
                      .join(", ");

                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.restaurantName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            ratingText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Icon(
                            Icons.access_time,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "${estimatedDeliveryTime.toInt()} min",
                          ),
                          const SizedBox(width: 20),
                          const Icon(
                            Icons.delivery_dining,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Free Delivery",
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              location.isEmpty
                                  ? "Location unavailable"
                                  : location,
                            ),
                          ),
                        ],
                      ),

                      if (!isOpen) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  Colors.red.shade200,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.storefront,
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "This restaurant is currently closed",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight:
                                        FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  filterChip(
                    "🔥 Bestseller",
                    "bestseller",
                  ),
                  filterChip(
                    "📋 All",
                    "all",
                  ),
                  filterChip(
                    "Veg",
                    "veg",
                  ),
                  filterChip(
                    "Non-Veg",
                    "nonveg",
                  ),
                  filterChip(
                    "Under ₹99",
                    "under99",
                  ),
                  filterChip(
                    "Under ₹199",
                    "under199",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('menu_items')
                  .where(
                    'restaurantId',
                    isEqualTo: widget.restaurantId,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No menu items found",
                    ),
                  );
                }

                final filteredDocs =
                    _filterMenuItems(
                  snapshot.data!.docs,
                );

                if (filteredDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No items found",
                    ),
                  );
                }

                return StreamBuilder<
                    DocumentSnapshot<
                        Map<String, dynamic>>>(
                  stream: restaurantStream,
                  builder: (
                    context,
                    restaurantSnapshot,
                  ) {
                    final restaurantData =
                        restaurantSnapshot.data
                                ?.data() ??
                            {};

                    final isOpen =
                        restaurantData["isOpen"] == true;

                    return Column(
                      children:
                          filteredDocs.map((doc) {
                        final data =
                            doc.data()
                                as Map<String, dynamic>;

                        return foodItem(
                          emoji:
                              data['category'] == "Pizza"
                                  ? "🍕"
                                  : data['category'] ==
                                          "Burger"
                                      ? "🍔"
                                      : "🍽️",
                          name: data['name'] ?? '',
                          description:
                              data['description'] ??
                                  'Fresh & Delicious',
                          price:
                              "₹${data['price'] ?? 0}",
                          itemId: doc.id,
                          preparationTime:
                              (data['preparationTime'] ??
                                      20)
                                  .toInt(),
                          imageUrl:
                              data['imageUrl'] ?? "",
                          isRestaurantOpen: isOpen,
                          isVeg:
                              data['isVeg'] == true,
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget filterChip(
    String title,
    String value,
  ) {
    final bool isSelected =
        selectedFilter == value;

    IconData? icon;
    Color iconColor = Colors.deepPurple;

    if (value == "veg") {
      icon = Icons.eco;
      iconColor = Colors.green;
    } else if (value == "nonveg") {
      icon = Icons.circle;
      iconColor = Colors.red;
    } else if (value == "under99" ||
        value == "under199") {
      icon = Icons.local_offer;
      iconColor = Colors.deepPurple;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.deepPurple.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : iconColor,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.deepPurple,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget foodItem({
    required String emoji,
    required String name,
    required String description,
    required String price,
    required String itemId,
    required int preparationTime,
    required String imageUrl,
    required bool isRestaurantOpen,
    required bool isVeg,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: cartService.cartStream(),
      builder: (context, snapshot) {
        int liveQuantity = 0;

        if (snapshot.hasData) {
          for (var cartDoc
              in snapshot.data!.docs) {
            if (cartDoc.id == itemId) {
              final cartData =
                  cartDoc.data()
                      as Map<String, dynamic>;

              liveQuantity =
                  cartData["quantity"] ?? 0;

              break;
            }
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (
                          context,
                          url,
                        ) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            alignment:
                                Alignment.center,
                            child: Text(
                              emoji,
                              style:
                                  const TextStyle(
                                fontSize: 35,
                              ),
                            ),
                          );
                        },
                        errorWidget: (
                          context,
                          url,
                          error,
                        ) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            alignment:
                                Alignment.center,
                            child: Text(
                              emoji,
                              style:
                                  const TextStyle(
                                fontSize: 35,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(
                            fontSize: 35,
                          ),
                        ),
                      ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  if (!isRestaurantOpen)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Closed",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    liveQuantity == 0
                        ? ElevatedButton(
                            onPressed: () async {
                              final item = CartItemModel(
  id: itemId,
  restaurantId: widget.restaurantId,
  restaurantName: widget.restaurantName,
  itemName: name,
  description: description,
  price: double.parse(
    price.replaceAll(
      "₹",
      "",
    ),
  ),
  quantity: 1,
  emoji: emoji,
  imageUrl: imageUrl,
  preparationTime: preparationTime,
);

                              await cartService
                                  .addToCart(item);
                            },
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.deepPurple,
                              foregroundColor:
                                  Colors.white,
                            ),
                            child: const Text(
                              "Add",
                            ),
                          )
                        : Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  await cartService
                                      .decreaseQty(
                                    itemId,
                                  );
                                },
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color:
                                      Colors.deepPurple,
                                ),
                              ),
                              Text(
                                liveQuantity.toString(),
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await cartService
                                      .increaseQty(
                                    itemId,
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_circle,
                                  color:
                                      Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),

                  const SizedBox(height: 6),

                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(4),
                      border: Border.all(
                        color: isVeg
                            ? Colors.green
                            : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isVeg
                              ? Colors.green
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}