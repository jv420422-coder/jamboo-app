import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class JambooAIScreen extends StatefulWidget {
  const JambooAIScreen({super.key});

  @override
  State<JambooAIScreen> createState() => _JambooAIScreenState();
}

class _JambooAIScreenState extends State<JambooAIScreen> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: "asia-south1",
  );

  final CartService _cartService = CartService();

  final Set<String> _addingItems = {};
  final Set<String> _addedItems = {};

  bool isTyping = false;

  final List<Map<String, dynamic>> messages = [
    {
      "text":
          "👋 Hi! Main Jamboo AI hoon.\n\n"
          "Mujhe apna mood ya budget batao, main best food recommend karunga.\n\n"
          "✨ Main kya kar sakta hoon?\n\n"
          "🍽️ Mood ke hisaab se food recommend karta hoon\n"
          "💰 Budget ke andar best options dhoondhta hoon\n"
          "👨‍👩‍👧‍👦 Family aur Party combos suggest karta hoon\n"
          "⚡ Fast delivery wale restaurants batata hoon\n\n"
          "👇 Neeche diye gaye Quick Suggestions se shuruaat karein.",
      "isUser": false,
      "recommendations": [],
    },
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _preloadRecommendationImages(
    List<Map<String, dynamic>> recommendations,
  ) async {
    if (!mounted) {
      return;
    }

    for (final item in recommendations) {
      final imageUrl =
          (item["imageUrl"] ?? "").toString().trim();

      if (imageUrl.isEmpty) {
        continue;
      }

      try {
        await precacheImage(
          CachedNetworkImageProvider(imageUrl),
          context,
        );
      } catch (_) {
        // Image loading failure is handled by the card itself.
      }
    }
  }

  Future<void> sendMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty || isTyping) {
      return;
    }

    setState(() {
      messages.add({
        "text": message,
        "isUser": true,
        "recommendations": [],
      });

      isTyping = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final callable =
          _functions.httpsCallable("jambooAI");

      final stopwatch = Stopwatch()..start();

      final result = await callable.call({
        "message": message,
      });

      stopwatch.stop();

      debugPrint(
        "🤖 Jamboo AI response time: "
        "${stopwatch.elapsedMilliseconds} ms",
      );

      final data =
          Map<String, dynamic>.from(result.data);

      final reply =
          (data["reply"] ?? "").toString();

      final rawRecommendations =
          data["recommendations"];

      List<Map<String, dynamic>> recommendations = [];

      if (rawRecommendations is List) {
        recommendations =
            rawRecommendations.map((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isTyping = false;

        messages.add({
          "text": reply.isNotEmpty
              ? reply
              : "Sorry, mujhe abhi response nahi mila.",
          "isUser": false,
          "recommendations": recommendations,
        });
      });

      _scrollToBottom();

      // Recommendation images ko background me preload karo.
      _preloadRecommendationImages(
        recommendations,
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isTyping = false;

        messages.add({
          "text":
              "😔 Jamboo AI se connect nahi ho paaya.\n\n"
              "${error.message ?? "Please try again."}",
          "isUser": false,
          "recommendations": [],
        });
      });

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isTyping = false;

        messages.add({
          "text":
              "😔 Kuch problem aa gayi. Please thodi der baad try karein.",
          "isUser": false,
          "recommendations": [],
        });
      });

      _scrollToBottom();
    }
  }

  Future<void> addRecommendationToCart(
    Map<String, dynamic> item,
  ) async {
    final itemId =
        (item["id"] ?? "").toString();

    if (itemId.isEmpty ||
        _addingItems.contains(itemId) ||
        _addedItems.contains(itemId)) {
      return;
    }

    setState(() {
      _addingItems.add(itemId);
    });

    try {
      final cartItem = CartItemModel(
        id: itemId,
        restaurantId:
            (item["restaurantId"] ?? "").toString(),
        restaurantName:
            (item["restaurantName"] ?? "").toString(),
        itemName:
            (item["name"] ?? "").toString(),
        description:
            (item["description"] ?? "").toString(),
        price:
            ((item["price"] ?? 0) as num).toDouble(),
        quantity: 1,
        emoji:
            (item["emoji"] ?? "🍽️").toString(),
        preparationTime:
            ((item["preparationTime"] ?? 20) as num)
                .toInt(),
      );

      await _cartService.addToCart(cartItem);

      if (!mounted) {
        return;
      }

      setState(() {
        _addingItems.remove(itemId);
        _addedItems.add(itemId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${item["name"]} cart me add ho gaya ✓",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _addingItems.remove(itemId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Item cart me add nahi ho paaya."),
        ),
      );
    }
  }

  Widget suggestionChip(String text) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (isTyping) {
          return;
        }

        _controller.text = text;
        sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: Colors.deepPurple.shade200,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  Widget recommendationCard(
    Map<String, dynamic> item,
  ) {
    final itemId =
        (item["id"] ?? "").toString();

    final isAdding =
        _addingItems.contains(itemId);

    final isAdded =
        _addedItems.contains(itemId);

    final imageUrl =
        (item["imageUrl"] ?? "").toString();

    final name =
        (item["name"] ?? "Food item").toString();

    final restaurant =
        (item["restaurantName"] ?? "Restaurant")
            .toString();

    final price =
        ((item["price"] ?? 0) as num).toDouble();

    final rating =
        ((item["rating"] ?? 0) as num).toDouble();

    final emoji =
        (item["emoji"] ?? "🍽️").toString();

    return Container(
      margin: const EdgeInsets.only(
        top: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: SizedBox(
              width: 92,
              height: 92,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) {
                        return Center(
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.deepPurple,
                          ),
                        );
                      },
                      errorWidget:
                          (context, url, error) {
                        return Center(
                          child: Text(
                            emoji,
                            style:
                                const TextStyle(
                              fontSize: 32,
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        emoji,
                        style:
                            const TextStyle(
                          fontSize: 32,
                        ),
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    restaurant,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "₹${price.toStringAsFixed(0)}",
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (rating > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color:
                                  Colors.amber,
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            Text(
                              rating
                                  .toStringAsFixed(1),
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(
              right: 10,
            ),
            child: InkWell(
              onTap: isAdding || isAdded
                  ? null
                  : () {
                      addRecommendationToCart(
                        item,
                      );
                    },
              borderRadius:
                  BorderRadius.circular(24),
              child: CircleAvatar(
                radius: 21,
                backgroundColor:
                    isAdded
                        ? Colors.green
                        : Colors.deepPurple,
                child: isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isAdded
                            ? Icons.check
                            : Icons.add,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor:
            Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                "assets/images/jamboo_avatar.png",
                width: 105,
                height: 105,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Jamboo AI",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder:
                  (context, index) {
                final msg =
                    messages[index];

                if (index == 0) {
                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment:
                            Alignment.centerLeft,
                        child: Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),
                          constraints:
                              const BoxConstraints(
                            maxWidth: 330,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              15,
                            ),
                          ),
                          child: Text(
                            msg["text"],
                            style:
                                const TextStyle(
                              fontSize: 14,
                              color:
                                  Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width:
                                MediaQuery.of(
                                          context,
                                        ).size.width /
                                    2 -
                                24,
                            child:
                                suggestionChip(
                              "💸 Under ₹200",
                            ),
                          ),
                          SizedBox(
                            width:
                                MediaQuery.of(
                                          context,
                                        ).size.width /
                                    2 -
                                24,
                            child:
                                suggestionChip(
                              "🥗 Healthy",
                            ),
                          ),
                          SizedBox(
                            width:
                                MediaQuery.of(
                                          context,
                                        ).size.width /
                                    2 -
                                24,
                            child:
                                suggestionChip(
                              "😋 Tasty & Healthy",
                            ),
                          ),
                          SizedBox(
                            width:
                                MediaQuery.of(
                                          context,
                                        ).size.width /
                                    2 -
                                24,
                            child:
                                suggestionChip(
                              "👨‍👩‍👧‍👦 Family Pack",
                            ),
                          ),
                          SizedBox(
                            width:
                                MediaQuery.of(
                                          context,
                                        ).size.width /
                                    2 -
                                24,
                            child:
                                suggestionChip(
                              "🎉 Party Vibe",
                            ),
                          ),
                          SizedBox(
                            width:
                                MediaQuery.of(
                                          context,
                                        ).size.width /
                                    2 -
                                24,
                            child:
                                suggestionChip(
                              "🎁 Surprise Me",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  );
                }

                final recommendations =
                    msg["recommendations"];

                return Column(
                  crossAxisAlignment:
                      msg["isUser"]
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment:
                          msg["isUser"]
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
                        margin:
                            const EdgeInsets.only(
                          bottom: 8,
                        ),
                        padding:
                            const EdgeInsets.all(
                          14,
                        ),
                        constraints:
                            const BoxConstraints(
                          maxWidth: 300,
                        ),
                        decoration:
                            BoxDecoration(
                          color: msg["isUser"]
                              ? Colors.deepPurple
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),
                        child: Text(
                          msg["text"],
                          style: TextStyle(
                            color: msg["isUser"]
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    if (!msg["isUser"] &&
                        recommendations is List &&
                        recommendations.isNotEmpty)
                      ...recommendations.map(
                        (item) {
                          return recommendationCard(
                            Map<String, dynamic>.from(
                              item,
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
          if (isTyping)
            const Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 8,
              ),
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  "🤖 Jamboo AI is typing...",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          Container(
            padding:
                const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _controller,
                    enabled: !isTyping,
                    textInputAction:
                        TextInputAction.send,
                    onSubmitted: (_) {
                      sendMessage();
                    },
                    decoration:
                        InputDecoration(
                      hintText:
                          "Ask Jamboo AI...",
                      filled: true,
                      fillColor:
                          Colors.grey.shade100,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Colors.deepPurple,
                  child: IconButton(
                    onPressed: isTyping
                        ? null
                        : sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}