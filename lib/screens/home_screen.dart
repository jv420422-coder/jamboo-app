import 'package:flutter/material.dart';

import '../widgets/header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/offer_banner.dart';
import '../widgets/category_card.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/ai_card.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/recommended_card.dart';
import 'jamboo_ai_screen.dart';
import 'cart/cart_screen.dart';
import 'profile_screen.dart';
import 'under_199_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final ScrollController _scrollController =
      ScrollController();

  bool showAIPopup = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.offset > 250) {
        if (!showAIPopup) {
          setState(() {
            showAIPopup = true;
          });
        }
      } else {
        if (showAIPopup) {
          setState(() {
            showAIPopup = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const HeaderWidget(),

                  const SizedBox(height: 10),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "What would you like to eat today?",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const SearchBarWidget(),

                  const SizedBox(height: 20),

                  const AICard(),

                  const OfferBanner(),

                  const SizedBox(height: 25),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection:
                          Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 20),
                      children: const [
CategoryCard(
  imagePath: "assets/images/pizza.png",
  title: "Pizza",
),

CategoryCard(
  imagePath: "assets/images/burger.png",
  title: "Burger",
),

CategoryCard(
  imagePath: "assets/images/noodles.png",
  title: "Noodles",
),

CategoryCard(
  imagePath: "assets/images/momos.png",
  title: "Momos",
),

CategoryCard(
  imagePath: "assets/images/biryani.png",
  title: "Biryani",
),

CategoryCard(
  imagePath: "assets/images/paneer.png",
  title: "Paneer",
),

CategoryCard(
  imagePath: "assets/images/chicken.png",
  title: "Chicken",
),

CategoryCard(
  imagePath: "assets/images/dessert.png",
  title: "Dessert",
),

],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "❤️ Recommended for You",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    height: 290,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: const [

                        RecommendedCard(
                          emoji: "🍕",
                          title: "Cheese Pizza",
                          price: "₹249",
                          rating: "4.9",
                          time: "20 min",
                        ),

                        RecommendedCard(
                          emoji: "🍔",
                          title: "Chicken Burger",
                          price: "₹199",
                          rating: "4.8",
                          time: "18 min",
                        ),

                        RecommendedCard(
                          emoji: "🍛",
                          title: "Special Biryani",
                          price: "₹299",
                          rating: "4.9",
                          time: "25 min",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Popular Restaurants",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('restaurants')
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
        child: Text("No restaurants found"),
      );
    }

    return Column(
      children: snapshot.data!.docs.map((doc) {

        final data =
            doc.data() as Map<String, dynamic>;

        return RestaurantCard(
  restaurantId: doc.id,
  name: data['name'] ?? '',
  cuisine: data['address'] ?? '',
  rating: (data['rating'] ?? 0).toString(),
  time: data['deliveryTime'] ?? '',
);

      }).toList(),
    );
  },
),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
if (showAIPopup)
            Positioned(
              right: 20,
              bottom: 90,
              child: AnimatedScale(
                scale: showAIPopup ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: FloatingActionButton.extended(
                  heroTag: "jamboo_ai",
                  backgroundColor: Colors.deepPurple,
                  elevation: 8,
                  icon: ClipOval(
  child: Image.asset(
    "assets/images/jamboo_avatar.png",
    width: 80,
    height: 80,
    fit: BoxFit.cover,
  ),
),
                  label: const Text(
                    "Jamboo AI",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const JambooAIScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),

      bottomNavigationBar: BottomNavbar(
        currentIndex: selectedIndex,
        onTap: (index) {
  setState(() {
    selectedIndex = index;
  });

  if (index == 1) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          const Under199Screen(),
    ),
  );
}

  if (index == 2) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CartScreen(),
      ),
    );
  }

  if (index == 3) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ProfileScreen(),
      ),
    );
  }
},
      ),
    );
  }
}