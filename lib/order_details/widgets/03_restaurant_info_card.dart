import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order_model.dart';

class RestaurantInfoCard extends StatefulWidget {
  final OrderModel order;

  const RestaurantInfoCard({
    super.key,
    required this.order,
  });

  @override
  State<RestaurantInfoCard> createState() =>
      _RestaurantInfoCardState();
}

class _RestaurantInfoCardState
    extends State<RestaurantInfoCard> {
  String _logoUrl = "";

  @override
  void initState() {
    super.initState();
    _loadRestaurantImage();
  }

  Future<void> _loadRestaurantImage() async {
    final restaurantId =
        widget.order.restaurantId.trim();

    if (restaurantId.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore
          .instance
          .collection("restaurant_registrations")
          .doc(restaurantId)
          .get();

      if (!snapshot.exists) return;

      final data = snapshot.data();

      final logoUrl =
          data?["logoUrl"]?.toString().trim() ?? "";

      if (!mounted) return;

      if (logoUrl.isNotEmpty) {
        setState(() {
          _logoUrl = logoUrl;
        });
      }
    } catch (_) {
      // Keep existing fallback UI if image loading fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantName =
        widget.order.restaurantName.trim().isEmpty
            ? "Restaurant"
            : widget.order.restaurantName.trim();

    final restaurantAddress =
        widget.order.restaurantAddress.trim();

    final orderDate = DateFormat(
      "dd MMM yyyy • hh:mm a",
    ).format(widget.order.createdAt);

    final itemCount = widget.order.items.length;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.045,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(18),
                child: _logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _logoUrl,
                        width: 78,
                        height: 78,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) {
                          return Container(
                            width: 78,
                            height: 78,
                            color:
                                const Color(0xFFF3EEFF),
                            child: const Center(
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Color(0xFF7E57C2),
                              ),
                            ),
                          );
                        },
                        errorWidget:
                            (context, url, error) {
                          return _restaurantFallback();
                        },
                      )
                    : _restaurantFallback(),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color: Color(0xFF171717),
                      ),
                    ),

                    const SizedBox(height: 7),

                    if (restaurantAddress
                        .isNotEmpty)
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Color(
                              0xFF7E57C2,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: Text(
                              restaurantAddress,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors
                                    .grey
                                    .shade700,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 10),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF3EEFF,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            size: 14,
                            color: Color(
                              0xFF7E57C2,
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            "Restaurant",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w600,
                              color: Color(
                                0xFF6A45B8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.04,
                ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF7E57C2),
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Order Information",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color: Color(0xFF171717),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      orderDate,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "$itemCount ${itemCount == 1 ? "Item" : "Items"}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                        color: Color(
                          0xFF6A45B8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "₹${widget.order.totalAmount.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        color: Color(
                          0xFF171717,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _restaurantFallback() {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: Color(0xFF7E57C2),
        size: 38,
      ),
    );
  }
}