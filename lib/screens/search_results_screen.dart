import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'restaurant_details_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final String searchQuery;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Results for "$searchQuery"',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            .snapshots(),
        builder: (context, restaurantSnapshot) {
          if (restaurantSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final restaurantDocs =
              restaurantSnapshot.data?.docs ?? [];

          final restaurants = restaurantDocs.where((doc) {
            final data = doc.data();

            final name =
                (data["restaurantName"] ?? "")
                    .toString()
                    .toLowerCase();

            final address =
                (data["address"] ?? "")
                    .toString()
                    .toLowerCase();

            final city =
                (data["city"] ?? "")
                    .toString()
                    .toLowerCase();

            final categories =
                (data["categories"] ?? [])
                    .toString()
                    .toLowerCase();

            return name.contains(query) ||
                address.contains(query) ||
                city.contains(query) ||
                categories.contains(query);
          }).toList();

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
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

              final menuDocs =
                  menuSnapshot.data?.docs ?? [];

              final foodResults = menuDocs.where((doc) {
                final data = doc.data();

                final name =
                    (data["name"] ?? "")
                        .toString()
                        .toLowerCase();

                final description =
                    (data["description"] ?? "")
                        .toString()
                        .toLowerCase();

                final category =
                    (data["category"] ?? "")
                        .toString()
                        .toLowerCase();

                final isActive =
                    data["isActive"] ?? true;

                final isAvailable =
                    data["isAvailable"] ?? true;

                final restaurantId =
                    (data["restaurantId"] ?? "")
                        .toString();

                final matchingRestaurant =
                    restaurantDocs.where((restaurantDoc) {
                  final restaurantData =
                      restaurantDoc.data();

                  final registeredRestaurantId =
                      (restaurantData["restaurantId"] ??
                              restaurantDoc.id)
                          .toString();

                  return registeredRestaurantId ==
                      restaurantId;
                }).toList();

                if (matchingRestaurant.isEmpty) {
                  return false;
                }

                return isActive &&
                    isAvailable &&
                    (name.contains(query) ||
                        description.contains(query) ||
                        category.contains(query));
              }).toList();

              if (restaurants.isEmpty &&
                  foodResults.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 70,
                          color: Colors.deepPurple,
                        ),
                        SizedBox(height: 15),
                        Text(
                          "No Results Found",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Try searching for another food or restaurant.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  30,
                ),
                children: [
                  if (foodResults.isNotEmpty) ...[
                    const Text(
                      "🍽 Foods",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    ...foodResults.map((doc) {
                      final data = doc.data();

                      final itemName =
                          data["name"] ?? "";

                      final description =
                          data["description"] ??
                              "Fresh & Delicious";

                      final price =
                          (data["price"] ?? 0).toString();

                      final imageUrl =
                          data["imageUrl"] ?? "";

                      final restaurantId =
                          data["restaurantId"] ?? "";

                      final matchingRestaurant =
                          restaurantDocs.where(
                        (restaurantDoc) {
                          final restaurantData =
                              restaurantDoc.data();

                          final registeredRestaurantId =
                              (restaurantData[
                                          "restaurantId"] ??
                                      restaurantDoc.id)
                                  .toString();

                          return registeredRestaurantId ==
                              restaurantId.toString();
                        },
                      ).toList();

                      if (matchingRestaurant.isEmpty) {
                        return const SizedBox();
                      }

                      final restaurantData =
                          matchingRestaurant.first.data();

                      final restaurantName =
                          (restaurantData[
                                      "restaurantName"] ??
                                  "Restaurant")
                              .toString();

                      final isOpen =
                          restaurantData["isOpen"] == true;

                      return GestureDetector(
                        onTap: () {
                          if (restaurantId
                              .toString()
                              .isEmpty) {
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RestaurantDetailsScreen(
                                restaurantId:
                                    restaurantId.toString(),
                                restaurantName:
                                    restaurantName,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          padding:
                              const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius
                                        .circular(14),
                                child: imageUrl
                                        .toString()
                                        .isNotEmpty
                                    ? CachedNetworkImage(
  imageUrl: imageUrl.toString(),
  width: 75,
  height: 75,
  fit: BoxFit.cover,
  placeholder: (context, url) {
    return Container(
      width: 75,
      height: 75,
      color: const Color(0xFFF0E8FF),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu,
          color: Colors.deepPurple,
          size: 32,
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
      width: 75,
      height: 75,
      color: const Color(0xFFF0E8FF),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu,
          color: Colors.deepPurple,
          size: 32,
        ),
      ),
    );
  },
)
                                    : Container(
                                        width: 75,
                                        height: 75,
                                        color:
                                            const Color(
                                          0xFFF0E8FF,
                                        ),
                                        child:
                                            const Center(
                                          child: Icon(
                                            Icons
                                                .restaurant_menu,
                                            color: Colors
                                                .deepPurple,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      itemName
                                          .toString(),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      description
                                          .toString(),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.grey,
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
                                        fontSize: 13,
                                        color:
                                            Colors.deepPurple,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 6,
                                    ),

                                    Row(
                                      children: [
                                        Text(
                                          "₹$price",
                                          style:
                                              const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            color: Colors
                                                .deepPurple,
                                          ),
                                        ),

                                        if (!isOpen) ...[
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          const Flexible(
                                            child: Text(
                                              "Closed today",
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style:
                                                  TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Colors.red,
                                                fontWeight:
                                                    FontWeight
                                                        .w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons
                                    .arrow_forward_ios,
                                size: 17,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  if (restaurants.isNotEmpty) ...[
                    const SizedBox(height: 20),

                    const Text(
                      "🏪 Restaurants",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    ...restaurants.map((doc) {
                      final data = doc.data();

                      final restaurantId =
                          data["restaurantId"] ??
                              doc.id;

                      final restaurantName =
                          data["restaurantName"] ??
                              "";

                      final address =
                          data["address"] ?? "";

                      final city =
                          data["city"] ?? "";

                      final logoUrl =
                          data["logoUrl"] ?? "";

                      final isOpen =
                          data["isOpen"] == true;

                      final location = [
                        address,
                        city,
                      ]
                          .where(
                            (value) => value
                                .toString()
                                .trim()
                                .isNotEmpty,
                          )
                          .join(", ");

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RestaurantDetailsScreen(
                                restaurantId:
                                    restaurantId
                                        .toString(),
                                restaurantName:
                                    restaurantName
                                        .toString(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          padding:
                              const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius
                                        .circular(14),
                                child: logoUrl
        .toString()
        .isNotEmpty
    ? CachedNetworkImage(
        imageUrl: logoUrl.toString(),
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        placeholder: (context, url) {
          return Container(
            width: 70,
            height: 70,
            color: const Color(0xFFF0E8FF),
            child: const Center(
              child: Icon(
                Icons.restaurant,
                color: Colors.deepPurple,
                size: 32,
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
            width: 70,
            height: 70,
            color: const Color(0xFFF0E8FF),
            child: const Center(
              child: Icon(
                Icons.restaurant,
                color: Colors.deepPurple,
                size: 32,
              ),
            ),
          );
        },
      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color:
                                            const Color(
                                          0xFFF0E8FF,
                                        ),
                                        child:
                                            const Center(
                                          child: Icon(
                                            Icons
                                                .restaurant,
                                            color: Colors
                                                .deepPurple,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      restaurantName
                                          .toString(),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    if (location
                                        .isNotEmpty)
                                      Text(
                                        location,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),

                                    if (!isOpen) ...[
                                      const SizedBox(
                                        height: 6,
                                      ),
                                      const Text(
                                        "This restaurant is closed today",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              Icon(
                                isOpen
                                    ? Icons
                                        .arrow_forward_ios
                                    : Icons.lock_outline,
                                size: 17,
                                color: isOpen
                                    ? Colors.grey
                                    : Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}