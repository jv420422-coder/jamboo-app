import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../screens/restaurant_details_screen.dart';
import '../screens/search_results_screen.dart';

class OfferBanner extends StatefulWidget {
  const OfferBanner({super.key});

  @override
  State<OfferBanner> createState() => _OfferBannerState();
}

class _OfferBannerState extends State<OfferBanner> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<String> _fallbackBanners = [
    "assets/images/offer_banner1.png",
    "assets/images/offer_banner2.png",
    "assets/images/offer_banner3.png",
  ];

  Timer? _timer;

  List<Map<String, dynamic>> _promotions = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadPromotions();

    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        if (_pageController.hasClients) {
          final bannerCount = _promotions.isNotEmpty
              ? _promotions.length
              : _fallbackBanners.length;

          if (bannerCount <= 1) return;

          _currentPage++;

          if (_currentPage >= bannerCount) {
            _currentPage = 0;
          }

          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD ACTIVE PROMOTIONS
  // ============================================================

  Future<void> _loadPromotions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('promotions')
.where('placement', isEqualTo: 'home_top_banner')
.where('isActive', isEqualTo: true)
.where('status', isEqualTo: 'active')
.get();

      final now = DateTime.now();

      final promotions = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          ...data,
        };
      }).where((promotion) {
        final status =
            (promotion['status'] ?? '').toString();

        if (status != 'active') {
          return false;
        }

        final startAt =
            _dateTimeFromFirestore(promotion['startAt']);

        final endAt =
            _dateTimeFromFirestore(promotion['endAt']);

        if (startAt != null && now.isBefore(startAt)) {
          return false;
        }

        if (endAt != null && now.isAfter(endAt)) {
          return false;
        }

        return true;
      }).toList();

      promotions.sort((a, b) {
        final priorityA =
            _toInt(a['priority']);

        final priorityB =
            _toInt(b['priority']);

        if (priorityA != priorityB) {
          return priorityB.compareTo(priorityA);
        }

        final orderA =
            _toInt(a['displayOrder']);

        final orderB =
            _toInt(b['displayOrder']);

        return orderA.compareTo(orderB);
      });

      if (!mounted) return;

      setState(() {
        _promotions = promotions;
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (e) {
      debugPrint(
        'CUSTOMER PROMOTION LOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _promotions = [];
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // FIRESTORE DATE HELPER
  // ============================================================

  DateTime? _dateTimeFromFirestore(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // INTEGER HELPER
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // BANNER IMAGE
  // ============================================================

  String _promotionImage(
    Map<String, dynamic> promotion,
  ) {
    return (promotion['imageUrl'] ?? '')
        .toString()
        .trim();
  }

  // ============================================================
  // BANNER CLICK
  // ============================================================

  Future<void> _handlePromotionTap(
    Map<String, dynamic> promotion,
  ) async {
    final targetType =
        (promotion['targetType'] ?? 'none')
            .toString();

    final targetId =
        (promotion['targetId'] ?? '')
            .toString()
            .trim();

    if (targetType == 'none' ||
        targetId.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // RESTAURANT
    // ----------------------------------------------------------

    if (targetType == 'restaurant') {
      try {
        final restaurantSnapshot =
            await FirebaseFirestore.instance
                .collection('restaurant_registrations')
                .where(
                  'restaurantId',
                  isEqualTo: targetId,
                )
                .limit(1)
                .get();

        if (!mounted) return;

        if (restaurantSnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Restaurant is no longer available.',
              ),
            ),
          );

          return;
        }

        final data =
            restaurantSnapshot.docs.first.data();

        final isApproved =
            data['verificationStatus'] ==
                'approved';

        final isActive =
            data['isActive'] == true;

        final isOpen =
            data['isOpen'] == true;

        if (!isApproved ||
            !isActive ||
            !isOpen) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Restaurant is currently unavailable.',
              ),
            ),
          );

          return;
        }

        final restaurantName =
            (data['restaurantName'] ??
                    'Restaurant')
                .toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RestaurantDetailsScreen(
              restaurantId: targetId,
              restaurantName:
                  restaurantName,
            ),
          ),
        );
      } catch (e) {
        debugPrint(
          'PROMOTION RESTAURANT NAVIGATION ERROR: $e',
        );
      }

      return;
    }

    // ----------------------------------------------------------
    // CATEGORY
    // ----------------------------------------------------------

    if (targetType == 'category') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SearchResultsScreen(
            searchQuery: targetId,
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // MENU ITEM
    // ----------------------------------------------------------

    if (targetType == 'menu_item') {
      try {
        final menuSnapshot =
            await FirebaseFirestore.instance
                .collection('menu_items')
                .doc(targetId)
                .get();

        if (!mounted) return;

        if (!menuSnapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Menu item is no longer available.',
              ),
            ),
          );

          return;
        }

        final data =
            menuSnapshot.data();

        if (data == null) {
          return;
        }

        final restaurantId =
            (data['restaurantId'] ?? '')
                .toString();

        if (restaurantId.isEmpty) {
          return;
        }

        final restaurantSnapshot =
            await FirebaseFirestore.instance
                .collection('restaurant_registrations')
                .where(
                  'restaurantId',
                  isEqualTo: restaurantId,
                )
                .limit(1)
                .get();

        if (!mounted) return;

        if (restaurantSnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Restaurant is no longer available.',
              ),
            ),
          );

          return;
        }

        final restaurantData =
            restaurantSnapshot.docs.first.data();

        final isApproved =
            restaurantData[
                    'verificationStatus'] ==
                'approved';

        final isActive =
            restaurantData['isActive'] == true;

        final isOpen =
            restaurantData['isOpen'] == true;

        if (!isApproved ||
            !isActive ||
            !isOpen) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Restaurant is currently unavailable.',
              ),
            ),
          );

          return;
        }

        final restaurantName =
            (restaurantData[
                        'restaurantName'] ??
                    'Restaurant')
                .toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RestaurantDetailsScreen(
              restaurantId: restaurantId,
              restaurantName:
                  restaurantName,
            ),
          ),
        );
      } catch (e) {
        debugPrint(
          'PROMOTION MENU ITEM NAVIGATION ERROR: $e',
        );
      }

      return;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 16 / 6.5,
                child: Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final usePromotions =
        _promotions.isNotEmpty;

    final bannerCount = usePromotions
        ? _promotions.length
        : _fallbackBanners.length;

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 16 / 6.5,
              child: PageView.builder(
                controller:
                    _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: bannerCount,
                itemBuilder:
                    (context, index) {
                  if (usePromotions) {
                    final promotion =
                        _promotions[index];

                    final imageUrl =
                        _promotionImage(
                      promotion,
                    );

                    return GestureDetector(
                      onTap: () {
                        _handlePromotionTap(
                          promotion,
                        );
                      },
                      child: imageUrl.isNotEmpty
    ? CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) {
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        },
        errorWidget: (
          context,
          url,
          error,
        ) {
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      )
                          : Container(
                              color: Colors
                                  .grey
                                  .shade200,
                              alignment:
                                  Alignment.center,
                              child:
                                  const Icon(
                                Icons
                                    .image_not_supported_outlined,
                                size: 40,
                                color:
                                    Colors.grey,
                              ),
                            ),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      // Existing static banners
                      // have no destination.
                    },
                    child: Image.asset(
                      _fallbackBanners[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: List.generate(
              bannerCount,
              (index) => AnimatedContainer(
                duration:
                    const Duration(milliseconds: 300),
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                width:
                    _currentPage == index
                        ? 18
                        : 8,
                height: 8,
                decoration:
                    BoxDecoration(
                  color:
                      _currentPage == index
                          ? const Color(
                              0xFF7E57C2,
                            )
                          : Colors
                              .grey
                              .shade300,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}