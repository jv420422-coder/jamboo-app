import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'address_screen.dart';
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
    int pizzaQty = 2;
int burgerQty = 1;
bool couponApplied = false;

int get itemsTotal =>
    (pizzaQty * 249) +
    (burgerQty * 149);

int get grandTotal =>
    itemsTotal +
    30 +
    10 -
    (couponApplied ? 50 : 0);

  int get totalItems =>
    pizzaQty + burgerQty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
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
    builder: (context) => const HomeScreen(),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
           Container(margin: const EdgeInsets.only(bottom: 16),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    children: [

      const Icon(
        Icons.location_on,
        color: Colors.deepPurple,
      ),

      const SizedBox(width: 10),

      const Expanded(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              "Deliver To",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            SizedBox(height: 4),

            Text(
              "Jatin",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "Chauri Chaura, Gorakhpur",
            ),
          ],
        ),
      ),

      TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddressScreen(),
      ),
    );
  },
  child: const Text(
    "Change",
  ),
),
    ],
  ),
),
            if (pizzaQty > 0)
  cartItem(
    emoji: "🍕",
    name: "Cheese Pizza",
    quantity: pizzaQty,
    price: "₹${pizzaQty * 249}",
  ),

if (burgerQty > 0)
  cartItem(
    emoji: "🍔",
    name: "Veg Burger",
    quantity: burgerQty,
    price: "₹${burgerQty * 149}",
  ),
Container(
  margin: const EdgeInsets.only(bottom: 20),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    children: [

      const Icon(
        Icons.local_offer,
        color: Colors.deepPurple,
      ),

      const SizedBox(width: 12),

       Expanded(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              "Apply Coupon",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 4),

            Column(
  crossAxisAlignment:
      CrossAxisAlignment.start,
  children: [

    Text(
      couponApplied
          ? "✅ JAMBOO50 Applied"
          : "Use JAMBOO50",
      style: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),

    const SizedBox(height: 4),

    Text(
      couponApplied
          ? "You saved ₹50"
          : "Save ₹50 instantly",
      style: const TextStyle(
        color: Colors.grey,
      ),
    ),
  ],
),
          ],
        ),
      ),

      TextButton(
  onPressed: () {
    setState(() {
      couponApplied = true;
    });
  },
  child: Text(
    couponApplied
        ? "Applied"
        : "Apply",
  ),
),
    ],
  ),
),

            const SizedBox(height: 20),
           

const SizedBox(height: 20),
            const Divider(),

            const SizedBox(height: 10),

            billRow(
  "Items Total",
  "₹$itemsTotal",
),
            if (couponApplied)
  billRow(
    "Coupon Discount",
    "-₹50",
  ),
            billRow(
              "Delivery Fee",
              "₹30",
            ),

            billRow(
              "Platform Fee",
              "₹10",
            ),

            const Divider(),

            billRow(
  "Grand Total",
  "₹$grandTotal",
  isBold: true,
),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
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
  }

  Widget cartItem({
    required String emoji,
    required String name,
    required int quantity,
    required String price,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [

          Text(
            emoji,
            style: const TextStyle(
              fontSize: 36,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          Row(
  children: [

    IconButton(
      onPressed: () {
        setState(() {
          if (name ==
              "Cheese Pizza") {
            if (pizzaQty > 0) {
              pizzaQty--;
            }
          } else if (name ==
              "Veg Burger") {
            if (burgerQty > 0) {
              burgerQty--;
            }
          }
        });
      },
      icon: const Icon(
        Icons.remove_circle,
        color: Colors.deepPurple,
      ),
    ),

    Text(
      quantity.toString(),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
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
          }
        });
      },
      icon: const Icon(
        Icons.add_circle,
        color: Colors.deepPurple,
      ),
    ),
  ],
),

const SizedBox(width: 10),

          Text(
            price,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget billRow(
    String title,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [

          Text(
            title,
            style: TextStyle(
              fontWeight: isBold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontWeight: isBold
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}