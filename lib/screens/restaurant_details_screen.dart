import 'package:flutter/material.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  const RestaurantDetailsScreen({super.key});

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState
    extends State<RestaurantDetailsScreen> {

  String selectedFilter = "bestseller";
int pizzaQty = 0;
int burgerQty = 0;
int coffeeQty = 0;
int get totalItems =>
    pizzaQty + burgerQty + coffeeQty;

int get totalPrice =>
    (pizzaQty * 249) +
    (burgerQty * 149) +
    (coffeeQty * 99);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: const Color(0xFFF5F0FF),

  bottomNavigationBar: totalItems > 0
      ? Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.deepPurple,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [

              Text(
                "🛒 $totalItems Items | ₹$totalPrice",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              ElevatedButton(
                onPressed: () {},
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
        )
      : null,

  body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Stack(
              children: [

                Image.asset(
                  "assets/images/restaurant_banner.png",
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),

                SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [

                        CircleAvatar(
                          backgroundColor:
                              Colors.white,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                            ),
                            onPressed: () {
                              Navigator.pop(
                                  context);
                            },
                          ),
                        ),

                        CircleAvatar(
                          backgroundColor:
                              Colors.white,
                          child: IconButton(
                            icon: const Icon(
                              Icons.favorite_border,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    "Pizza Hub",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [

                      Icon(
                        Icons.star,
                        color: Colors.orange,
                        size: 20,
                      ),

                      SizedBox(width: 5),

                      Text(
                        "4.8",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
SizedBox(width: 20),

                      Icon(
                        Icons.access_time,
                        size: 18,
                      ),

                      SizedBox(width: 5),

                      Text("25 min"),

                      SizedBox(width: 20),

                      Icon(
                        Icons.delivery_dining,
                        size: 20,
                      ),

                      SizedBox(width: 5),

                      Text("Free Delivery"),
                    ],
                  ),

                  SizedBox(height: 12),

                  Row(
                    children: [

                      Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),

                      SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          "Chauri Chaura, Gorakhpur",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
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
                    "🥬 Veg",
                    "veg",
                  ),

                  filterChip(
                    "🍗 Non Veg",
                    "nonveg",
                  ),

                  filterChip(
                    "💰 Under ₹99",
                    "under99",
                  ),

                  filterChip(
                    "💰 Under ₹199",
                    "under199",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

          foodItem(
  emoji: "🍕",
  name: "Cheese Pizza",
  description: "Classic cheese loaded pizza",
  price: "₹249",
  quantity: pizzaQty,
),

foodItem(
  emoji: "🍔",
  name: "Veg Burger",
  description: "Fresh veggie burger",
  price: "₹149",
  quantity: burgerQty,
),

foodItem(
  emoji: "🥤",
  name: "Cold Coffee",
  description: "Chilled creamy coffee",
  price: "₹99",
  quantity: coffeeQty,
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

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple
              : Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color:
                Colors.deepPurple.shade200,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.deepPurple,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget foodItem({
  required String emoji,
  required String name,
  required String description,
  required String price,
  required int quantity,
}) {
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

        Text(
          emoji,
          style: const TextStyle(
            fontSize: 40,
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

        quantity == 0
            ? ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (name ==
                        "Cheese Pizza") {
                      pizzaQty = 1;
                    } else if (name ==
                        "Veg Burger") {
                      burgerQty = 1;
                    } else if (name ==
                        "Cold Coffee") {
                      coffeeQty = 1;
                    }
                  });
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepPurple,
                  foregroundColor:
                      Colors.white,
                ),
                child: const Text("Add"),
              )
            : Row(
                children: [

                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (name ==
                            "Cheese Pizza") {
                          pizzaQty--;
                        } else if (name ==
                            "Veg Burger") {
                          burgerQty--;
                        } else if (name ==
                            "Cold Coffee") {
                          coffeeQty--;
                        }
                      });
                    },
                    icon: const Icon(
                      Icons.remove_circle,
                      color:
                          Colors.deepPurple,
                    ),
                  ),

                  Text(
                    quantity.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (name ==
                            "Cheese Pizza") {
                          pizzaQty++;
                        } else if (name ==
                            "Veg Burger") {
                          burgerQty++;
                        } else if (name ==
                            "Cold Coffee") {
                          coffeeQty++;
                        }
                      });
                    },
                    icon: const Icon(
                      Icons.add_circle,
                      color:
                          Colors.deepPurple,
                    ),
                  ),
                ],
              ),
      ],
    ),
  );
}
    }