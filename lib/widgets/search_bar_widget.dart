import 'package:flutter/material.dart';
import '../screens/search_results_screen.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() =>
      _SearchBarWidgetState();
}

class _SearchBarWidgetState
    extends State<SearchBarWidget> {

  final TextEditingController
      searchController =
      TextEditingController();

  void performSearch() {
    if (searchController.text
        .trim()
        .isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SearchResultsScreen(
          searchQuery:
              searchController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Row(
        children: [

          Expanded(
            child: TextField(
              controller:
                  searchController,

              textInputAction:
                  TextInputAction.search,

              onSubmitted: (_) {
                performSearch();
              },

              decoration:
                  InputDecoration(
                hintText:
                    "Search food or restaurants",

                prefixIcon:
                    IconButton(
                  icon: const Icon(
                    Icons.search,
                  ),
                  onPressed:
                      performSearch,
                ),

                filled: true,
                fillColor:
                    Colors.white,

                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 18,
                ),

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                              18),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Container(
            height: 58,
            width: 58,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                      0xFF7E57C2),
              borderRadius:
                  BorderRadius
                      .circular(18),
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}