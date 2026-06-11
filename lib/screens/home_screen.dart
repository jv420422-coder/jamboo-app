import 'package:flutter/material.dart';

import '../widgets/header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/offer_banner.dart';
import '../widgets/category_card.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/ai_card.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/recommended_card.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderWidget(),

              const SizedBox(height: 10),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
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
                padding: EdgeInsets.symmetric(horizontal: 20),
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
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
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
    padding: EdgeInsets.symmetric(horizontal: 20),
    children: [

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

              const RestaurantCard(
                name: "Biryani King",
                cuisine: "Biryani • North Indian",
                rating: "4.8",
                time: "30 min",
              ),

              const RestaurantCard(
                name: "Pizza Hub",
                cuisine: "Pizza • Italian",
                rating: "4.7",
                time: "25 min",
              ),

              

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavbar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}