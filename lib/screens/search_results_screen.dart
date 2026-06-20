import 'package:flutter/material.dart';
import 'restaurant_details_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final String searchQuery;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.toLowerCase();

    final foodResults = [
      "Cheese Pizza",
      "Veg Burger",
      "Cold Coffee",
      "Special Biryani",
      "Chicken Biryani",
    ].where(
      (item) => item.toLowerCase().contains(query),
    ).toList();

    final restaurantResults = [
      "Pizza Hub",
      "Biryani King",
    ].where(
      (item) => item.toLowerCase().contains(query),
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        title: Text(
          "Results for \"$searchQuery\"",
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          if (foodResults.isNotEmpty) ...[
            const Text(
              "🍽 Foods",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...foodResults.map(
  (food) => Card(
    child: ListTile(
      leading: Text(
        food.contains("Pizza")
            ? "🍕"
            : food.contains("Burger")
                ? "🍔"
                : food.contains("Coffee")
                    ? "🥤"
                    : "🍛",
        style: const TextStyle(
          fontSize: 28,
        ),
      ),
      title: Text(food),
    ),
  ),
),
          ],

          if (restaurantResults.isNotEmpty) ...[
            const SizedBox(height: 25),

            const Text(
              "🏪 Restaurants",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...restaurantResults.map(
              (restaurant) => Card(
                child: ListTile(
                  title: Text(restaurant),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RestaurantDetailsScreen(
  restaurantId: restaurant == "Pizza Hub"
      ? "pizza_hub"
      : "biryani_king",
  restaurantName: restaurant,
),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          if (foodResults.isEmpty &&
              restaurantResults.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 80,
                ),
                child: Text(
                  "No Results Found 😕",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}