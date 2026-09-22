import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/order_model.dart';

class OrderedItemsCard extends StatefulWidget {
  final OrderModel order;

  const OrderedItemsCard({
    super.key,
    required this.order,
  });

  @override
  State<OrderedItemsCard> createState() =>
      _OrderedItemsCardState();
}

class _OrderedItemsCardState
    extends State<OrderedItemsCard> {
  final Map<String, String> _fetchedImages = {};
  final Set<String> _loadingImages = {};

  @override
  void initState() {
    super.initState();
    _loadMissingImages();
  }

  Future<void> _loadMissingImages() async {
    for (final item in widget.order.items) {
      final imageUrl = _getImageUrl(item);

      if (imageUrl.isNotEmpty) {
        continue;
      }

      final itemId =
          (item["id"] ?? "").toString().trim();

      if (itemId.isEmpty ||
          _fetchedImages.containsKey(itemId) ||
          _loadingImages.contains(itemId)) {
        continue;
      }

      _loadingImages.add(itemId);

      try {
        final snapshot = await FirebaseFirestore
            .instance
            .collection("menu_items")
            .doc(itemId)
            .get();

        if (snapshot.exists) {
          final data = snapshot.data();

          final image =
              data?["imageUrl"]?.toString().trim() ?? "";

          if (image.isNotEmpty && mounted) {
            setState(() {
              _fetchedImages[itemId] = image;
            });
          }
        }
      } catch (_) {
        // Keep existing fallback if image loading fails.
      } finally {
        _loadingImages.remove(itemId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF7E57C2),
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                "Ordered Items",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF171717),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          ...List.generate(
            widget.order.items.length,
            (index) {
              final item =
                  widget.order.items[index];

              final itemName =
                  (item["itemName"] ??
                          item["name"] ??
                          "Item")
                      .toString();

              final quantity =
                  (item["quantity"] ?? 1).toString();

              final priceValue =
                  item["price"] ?? 0;

              final price = priceValue is num
                  ? priceValue.toDouble()
                  : double.tryParse(
                          priceValue.toString(),
                        ) ??
                      0;

              final itemId =
                  (item["id"] ?? "")
                      .toString()
                      .trim();

              final directImageUrl =
                  _getImageUrl(item);

              final imageUrl =
                  directImageUrl.isNotEmpty
                      ? directImageUrl
                      : (_fetchedImages[itemId] ??
                          "");

              final isVeg =
                  _getVegStatus(item);

              return Column(
                children: [
                  if (index > 0)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 11,
                      ),
                      child: Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                    ),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.center,
                    children: [
                      _buildItemImage(imageUrl),

                      const SizedBox(width: 11),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    Color(0xFF171717),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                Text(
                                  "Qty × $quantity",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors
                                        .grey
                                        .shade600,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),

                                if (isVeg != null) ...[
                                  const SizedBox(width: 8),

                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration:
                                        BoxDecoration(
                                      border: Border.all(
                                        color: isVeg
                                            ? Colors.green
                                            : Colors.red,
                                        width: 1.3,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(3),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration:
                                            BoxDecoration(
                                          color: isVeg
                                              ? Colors.green
                                              : Colors.red,
                                          shape:
                                              BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        "₹${price.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.bold,
                          color: Color(0xFF171717),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getImageUrl(
    Map<String, dynamic> item,
  ) {
    final possibleKeys = [
      "imageUrl",
      "image",
      "imageURL",
      "photoUrl",
      "photoURL",
    ];

    for (final key in possibleKeys) {
      final value = item[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return "";
  }

  bool? _getVegStatus(
    Map<String, dynamic> item,
  ) {
    final value =
        item["isVeg"] ??
        item["isVegetarian"] ??
        item["veg"];

    if (value is bool) {
      return value;
    }

    if (value != null) {
      final text =
          value.toString().toLowerCase();

      if (text == "true" ||
          text == "veg" ||
          text == "vegetarian") {
        return true;
      }

      if (text == "false" ||
          text == "nonveg" ||
          text == "non-veg" ||
          text == "non_veg") {
        return false;
      }
    }

    return null;
  }

  Widget _buildItemImage(
    String imageUrl,
  ) {
    if (imageUrl.isEmpty) {
      return _imageFallback();
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 62,
        height: 62,
        fit: BoxFit.cover,
        placeholder:
            (context, url) {
          return Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF3EEFF),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      Color(0xFF7E57C2),
                ),
              ),
            ),
          );
        },
        errorWidget:
            (context, url, error) {
          return _imageFallback();
        },
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        color: Color(0xFF7E57C2),
        size: 28,
      ),
    );
  }
}