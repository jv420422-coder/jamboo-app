import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';

final CartService cartService = CartService();

class CartItemCard extends StatelessWidget {
  final CartItemModel item;

  const CartItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 92,
              height: 92,
              child: item.imageUrl.trim().isNotEmpty
    ? CachedNetworkImage(
        imageUrl: item.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) {
          return Container(
            color: const Color(0xFFF3EEFF),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorWidget: (context, url, error) {
          return _emojiFallback();
        },
      )
    : _emojiFallback(),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                if (item.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                Text(
                  "₹${item.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EEFF),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius:
                            BorderRadius.circular(10),
                        onTap: () async {
                          await cartService.decreaseQty(
                            item.id,
                          );
                        },
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            Icons.remove,
                            size: 18,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 28,
                        child: Center(
                          child: Text(
                            item.quantity.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      InkWell(
                        borderRadius:
                            BorderRadius.circular(10),
                        onTap: () async {
                          await cartService.increaseQty(
                            item.id,
                          );
                        },
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.deepPurple,
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
    );
  }

  Widget _emojiFallback() {
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

class BillRow extends StatelessWidget {
  final String title;
  final String value;
  final bool bold;

  const BillRow({
    super.key,
    required this.title,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: bold
                  ? Colors.black
                  : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 17 : 14,
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: bold
                  ? Colors.deepPurple
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}