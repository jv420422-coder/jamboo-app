import 'package:flutter/material.dart';
import '../screens/search_results_screen.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController searchController = TextEditingController();

  void performSearch() {
    if (searchController.text.trim().isEmpty) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          searchQuery: searchController.text.trim(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: searchController,
        onTapOutside: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        textInputAction: TextInputAction.search,
        onSubmitted: (_) {
          performSearch();
        },
        decoration: InputDecoration(
          hintText: 'Search food or restaurants',
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 24,
            color: Color(0xFF7E57C2),
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.grey,
                    size: 18,
                  ),
                  onPressed: () {
                    searchController.clear();
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF7E57C2),
              width: 1,
            ),
          ),
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }
}