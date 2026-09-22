import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'restaurant_details_screen.dart';

class Under199Screen extends StatelessWidget {
  const Under199Screen({super.key});

  String _getEmoji(String category) {
    switch (category.toLowerCase()) {
      case "pizza":
        return "🍕";
      case "burger":
        return "🍔";
      case "momos":
        return "🥟";
      case "biryani":
        return "🍛";
      case "noodles":
        return "🍜";
      case "rolls":
        return "🌯";
      case "chicken":
        return "🍗";
      case "paneer":
        return "🧀";
      case "desserts":
      case "dessert":
        return "🍰";
      default:
        return "🍽️";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.black,
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Under ₹199",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("restaurant_registrations")
            .where(
              "verificationStatus",
              isEqualTo: "approved",
            )
            .where(
              "isActive",
              isEqualTo: true,
            )
            .where(
              "isOpen",
              isEqualTo: true,
            )
            .snapshots(),

        builder: (context, restaurantSnapshot) {
          if (restaurantSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (restaurantSnapshot.hasError) {
            return const Center(
              child: Text(
                "Something went wrong",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final validRestaurantIds = <String>{};
          final restaurantNames = <String, String>{};

          for (final doc
              in restaurantSnapshot.data?.docs ?? []) {
            final data =
                doc.data() as Map<String, dynamic>;

            final restaurantId =
                data["restaurantId"] ?? doc.id;

            validRestaurantIds.add(
              restaurantId.toString(),
            );

            restaurantNames[
                restaurantId.toString()] =
                (data["restaurantName"] ?? "")
                    .toString();
          }

          if (validRestaurantIds.isEmpty) {
            return const Center(
              child: Text(
                "No items available",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("menu_items")
                .snapshots(),

            builder: (context, menuSnapshot) {
              if (menuSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (menuSnapshot.hasError) {
                return const Center(
                  child: Text(
                    "Something went wrong",
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              final under199Items =
                  (menuSnapshot.data?.docs ?? [])
                      .where((doc) {
                final data =
                    doc.data()
                        as Map<String, dynamic>;

                final restaurantId =
                    (data["restaurantId"] ?? "")
                        .toString();

                final price =
                    (data["price"] ?? 0) as num;

                final isActive =
                    data["isActive"] ?? true;

                final isAvailable =
                    data["isAvailable"] ?? true;

                return validRestaurantIds
                        .contains(restaurantId) &&
                    price <= 199 &&
                    isActive == true &&
                    isAvailable == true;
              }).toList();

              if (under199Items.isEmpty) {
                return const Center(
                  child: Text(
                    "No items under ₹199",
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  30,
                ),
                itemCount:
                    under199Items.length + 2,

                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      margin:
                          const EdgeInsets.only(
                        bottom: 18,
                      ),
                      padding:
                          const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(0xFFE9D5FF),
                            Color(0xFFF8F2FF),
                          ],
                          begin:
                              Alignment.topLeft,
                          end:
                              Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                        border: Border.all(
                          color:
                              const Color(0xFFD8B4FE),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration:
                                BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius
                                      .circular(16),
                            ),
                            child: const Icon(
                              Icons
                                  .local_offer_rounded,
                              color:
                                  Colors.deepPurple,
                              size: 28,
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  "Great Taste, Great Price!",
                                  style: TextStyle(
                                    color:
                                        Colors.deepPurple,
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Enjoy delicious food within your budget",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.deepPurple,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: const Text(
                              "Max ₹199",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (index == 1) {
                    return const Padding(
                      padding:
                          EdgeInsets.only(
                        left: 4,
                        bottom: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .restaurant_menu_rounded,
                            color:
                                Colors.deepPurple,
                            size: 21,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Popular Picks Under ₹199",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final doc =
                      under199Items[index - 2];

                  final item =
                      doc.data()
                          as Map<String, dynamic>;

                  final restaurantId =
                      (item["restaurantId"] ?? "")
                          .toString();

                  final category =
                      (item["category"] ?? "")
                          .toString();

                  final restaurantName =
                      restaurantNames[
                              restaurantId] ??
                          (item["restaurantName"] ??
                                  "")
                              .toString();

                  final name =
                      (item["name"] ?? "")
                          .toString();

                  final price =
                      (item["price"] ?? 0) as num;

                  final imageUrl =
                      (item["imageUrl"] ?? "")
                          .toString();

                  final totalRatings =
                      (item["totalRatings"] ?? 0)
                          as num;

                  final averageRating =
                      (item["averageRating"] ?? 0)
                          as num;

                  final hasRating =
                      totalRatings > 0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RestaurantDetailsScreen(
                            restaurantId:
                                restaurantId,
                            restaurantName:
                                restaurantName,
                          ),
                        ),
                      );
                    },

                    child: Container(
                      margin:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),
                      padding:
                          const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 9,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                            child: imageUrl
                                    .isNotEmpty
                                ? CachedNetworkImage(
  imageUrl: imageUrl,
  width: 92,
  height: 92,
  fit: BoxFit.cover,
  placeholder: (context, url) {
    return _emojiBox(category);
  },
  errorWidget: (
    context,
    url,
    error,
  ) {
    return _emojiBox(category);
  },
)
                                : _emojiBox(
                                    category,
                                  ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  restaurantName,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Row(
                                  children: [
                                    if (hasRating) ...[
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 7,
                                          vertical: 4,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              const Color(
                                            0xFFF3E8FF,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize:
                                              MainAxisSize
                                                  .min,
                                          children: [
                                            const Icon(
                                              Icons
                                                  .star_rounded,
                                              color:
                                                  Colors.deepPurple,
                                              size: 14,
                                            ),
                                            const SizedBox(
                                              width: 3,
                                            ),
                                            Text(
                                              averageRating
                                                  .toStringAsFixed(
                                                1,
                                              ),
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.deepPurple,
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                fontSize:
                                                    12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 7,
                                      ),
                                    ],

                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            const Color(
                                          0xFFF3F4F6,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          10,
                                        ),
                                      ),
                                      child: const Text(
                                        "Under ₹199",
                                        style:
                                            TextStyle(
                                          color:
                                              Colors.grey,
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Text(
                                "₹${price.toStringAsFixed(0)}",
                                style:
                                    const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              Container(
                                width: 38,
                                height: 38,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.deepPurple,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    13,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color:
                                          Colors.black12,
                                      blurRadius: 5,
                                      offset:
                                          Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons
                                      .arrow_forward_rounded,
                                  color:
                                      Colors.white,
                                  size: 21,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _emojiBox(String category) {
    return Container(
      width: 92,
      height: 92,
      color: const Color(0xFFF3E8FF),
      alignment: Alignment.center,
      child: Text(
        _getEmoji(category),
        style: const TextStyle(
          fontSize: 42,
        ),
      ),
    );
  }
}