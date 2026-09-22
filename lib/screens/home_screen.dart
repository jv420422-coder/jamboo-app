import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme/app_colors.dart';
import '../services/location_service.dart';
import '../widgets/ai_card.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/category_card.dart';
import '../widgets/header_widget.dart';
import '../widgets/home_hero_banner.dart';
import '../widgets/offer_banner.dart';
import '../widgets/recommended_card.dart';
import '../widgets/restaurant_card.dart';
import 'cart/cart_screen.dart';
import 'jamboo_ai_screen.dart';
import 'profile_screen.dart';
import 'restaurant_details_screen.dart';
import 'search_results_screen.dart';
import 'under_199_screen.dart';
import '../services/restaurant_serviceability_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final LocationService _locationService = LocationService();
  final RestaurantServiceabilityService
    _serviceabilityService =
    RestaurantServiceabilityService();

  bool showAIPopup = false;
  Position? _currentPosition;
Set<String> _serviceableRestaurantIds = {};

  late final Future<QuerySnapshot<Map<String, dynamic>>>
      _promotionsFuture;

  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      _recommendedMenuStream;

  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      _restaurantsStream;
      

  @override
  void initState() {
    super.initState();

    _promotionsFuture = FirebaseFirestore.instance
        .collection('promotions')
        .where(
          'placement',
          isEqualTo: 'recommended_for_you',
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .get();

    _recommendedMenuStream = FirebaseFirestore.instance
        .collection('menu_items')
        .where(
          'isRecommended',
          isEqualTo: true,
        )
        .snapshots();

    _restaurantsStream = FirebaseFirestore.instance
        .collection('restaurant_registrations')
        .where(
          'verificationStatus',
          isEqualTo: 'approved',
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .where(
          'isOpen',
          isEqualTo: true,
        )
        .snapshots();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateCurrentLocation();
      }
    });

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final shouldShow = _scrollController.offset > 250;

    if (shouldShow != showAIPopup && mounted) {
      setState(() {
        showAIPopup = shouldShow;
      });
    }
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final permissionReady =
          await _locationService.ensureLocationPermission();

      if (!permissionReady) {
        if (!mounted) return;

        final permission =
            await _locationService.checkPermission();

        if (permission == LocationPermission.deniedForever) {
          await showDialog<void>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text(
                  'Location Permission Required',
                ),
                content: const Text(
                  'Jamboo needs your location to show nearby restaurants and calculate delivery distance. Please enable location permission from Settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Later'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _locationService.openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              );
            },
          );
        } else {
          final serviceEnabled =
              await _locationService.isLocationServiceEnabled();

          if (!serviceEnabled) {
            await showDialog<void>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text(
                    'Turn On Location',
                  ),
                  content: const Text(
                    'Please turn on your device location so Jamboo can show restaurants near you.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Later'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _locationService
                            .openLocationSettings();
                      },
                      child: const Text(
                        'Turn On Location',
                      ),
                    ),
                  ],
                );
              },
            );
          }
        }

        return;
      }

      final position =
          await _locationService.getCurrentPosition();

      if (position == null) return;

      final latitude = position.latitude;
final longitude = position.longitude;

if (mounted) {
  setState(() {
    _currentPosition = position;
  });
}

final restaurantsSnapshot =
    await FirebaseFirestore.instance
        .collection('restaurant_registrations')
        .where(
          'verificationStatus',
          isEqualTo: 'approved',
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .where(
          'isOpen',
          isEqualTo: true,
        )
        .get();

await _updateServiceableRestaurants(
  restaurantsSnapshot.docs,
);

      final address =
          await _locationService.getAddressFromCoordinates(
        latitude,
        longitude,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'currentLatitude': latitude,
          'currentLongitude': longitude,
          'currentAddress': address ?? '',
          'currentLocationUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint(
        'CURRENT LOCATION UPDATED: $latitude, $longitude',
      );
    } catch (e) {
      debugPrint(
        'CURRENT LOCATION ERROR: $e',
      );
    }
  }
  Future<void> _updateServiceableRestaurants(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> restaurants,
) async {
  final position = _currentPosition;

  if (position == null) {
    if (!mounted) return;

    setState(() {
      _serviceableRestaurantIds = {};
    });

    return;
  }

  final radiusKm =
      await _serviceabilityService.getServiceableRadiusKm();

  final serviceableIds = <String>{};

  for (final restaurantDoc in restaurants) {
    final data = restaurantDoc.data();

    final latitude = data['latitude'];
    final longitude = data['longitude'];

    if (latitude is! num || longitude is! num) {
      continue;
    }

    final distanceKm =
        _serviceabilityService.calculateDistanceKm(
      customerLatitude: position.latitude,
      customerLongitude: position.longitude,
      restaurantLatitude: latitude.toDouble(),
      restaurantLongitude: longitude.toDouble(),
    );

    if (distanceKm <= radiusKm) {
      final restaurantId =
          (data['restaurantId'] ?? restaurantDoc.id).toString();

      serviceableIds.add(restaurantId);
    }
  }

  if (!mounted) return;

  setState(() {
    _serviceableRestaurantIds = serviceableIds;
  });
}

  Future<void> _openRecommendedPromotion(
    Map<String, dynamic> promotion,
  ) async {
    final targetType =
        (promotion['targetType'] ?? '').toString();

    final targetId =
        (promotion['targetId'] ?? '').toString();

    if (targetId.isEmpty ||
        targetType.isEmpty ||
        targetType == 'none') {
      return;
    }

    try {
      if (targetType == 'restaurant') {
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
                'Restaurant is currently unavailable.',
              ),
            ),
          );
          return;
        }

        final restaurantData =
            restaurantSnapshot.docs.first.data();

        final restaurantName =
            (restaurantData['restaurantName'] ??
                    restaurantData['name'] ??
                    'Restaurant')
                .toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailsScreen(
              restaurantId: targetId,
              restaurantName: restaurantName,
            ),
          ),
        );

        return;
      }

      if (targetType == 'category') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(
              searchQuery: targetId,
            ),
          ),
        );

        return;
      }

      if (targetType == 'menu_item') {
        final menuItemSnapshot =
            await FirebaseFirestore.instance
                .collection('menu_items')
                .doc(targetId)
                .get();

        if (!mounted) return;

        if (!menuItemSnapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Menu item is currently unavailable.',
              ),
            ),
          );
          return;
        }

        final menuData =
            menuItemSnapshot.data() ?? {};

        final restaurantId =
            (menuData['restaurantId'] ?? '')
                .toString();

        if (restaurantId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Restaurant information is unavailable.',
              ),
            ),
          );
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
                'Restaurant is currently unavailable.',
              ),
            ),
          );
          return;
        }

        final restaurantData =
            restaurantSnapshot.docs.first.data();

        final restaurantName =
            (restaurantData['restaurantName'] ??
                    restaurantData['name'] ??
                    'Restaurant')
                .toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailsScreen(
              restaurantId: restaurantId,
              restaurantName: restaurantName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'RECOMMENDED PROMOTION OPEN ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open this promotion.',
          ),
        ),
      );
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _getActivePromotions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final now = DateTime.now();

    final promotions = snapshot.docs.where((doc) {
      final data = doc.data();

      final startTimestamp = data['startAt'];
      final endTimestamp = data['endAt'];

      DateTime? startAt;
      DateTime? endAt;

      if (startTimestamp is Timestamp) {
        startAt = startTimestamp.toDate();
      }

      if (endTimestamp is Timestamp) {
        endAt = endTimestamp.toDate();
      }

      final scheduleActive =
          (startAt == null ||
              !now.isBefore(startAt)) &&
          (endAt == null ||
              now.isBefore(endAt));

      final targetAudience =
          (data['targetAudience'] ??
                  'all_customers')
              .toString();

      return scheduleActive &&
          targetAudience == 'all_customers';
    }).toList();

    promotions.sort((a, b) {
      final aData = a.data();
      final bData = b.data();

      final aPriority =
          (aData['priority'] ?? 0) as num;

      final bPriority =
          (bData['priority'] ?? 0) as num;

      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }

      final aOrder =
          (aData['displayOrder'] ?? 0) as num;

      final bOrder =
          (bData['displayOrder'] ?? 0) as num;

      return aOrder.compareTo(bOrder);
    });

    return promotions;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Text(
                      'What would you like to eat today?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const HomeHeroBanner(),
                  const SizedBox(height: 10),
                  const AICard(),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection:
                          Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      children: const [
                        CategoryCard(
                          imagePath:
                              'assets/images/pizza.png',
                          title: 'Pizza',
                        ),
                        CategoryCard(
                          imagePath:
                              'assets/images/burger.png',
                          title: 'Burger',
                        ),
                        CategoryCard(
                          imagePath:
                              'assets/images/noodles.png',
                          title: 'Noodles',
                        ),
                        CategoryCard(
                          imagePath:
                              'assets/images/momos.png',
                          title: 'Momos',
                        ),
                        CategoryCard(
                          imagePath:
                              'assets/images/biryani.png',
                          title: 'Biryani',
                        ),
                        CategoryCard(
                          imagePath:
                              'assets/images/paneer.png',
                          title: 'Paneer',
                        ),
                        CategoryCard(
                          imagePath:
                              'assets/images/chicken.png',
                          title: 'Chicken',
                        ),
                        CategoryCard(
                          imagePath:
                              'assets/images/dessert.png',
                          title: 'Dessert',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const OfferBanner(),
                  const SizedBox(height: 25),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Text(
                      '❤️ Recommended for You',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  StreamBuilder<
                      QuerySnapshot<
                          Map<String, dynamic>>>(
                    stream: _restaurantsStream,
                    builder: (
                      context,
                      restaurantStreamSnapshot,
                    ) {
                      final restaurants =
                          restaurantStreamSnapshot
                                  .data
                                  ?.docs ??
                              [];

                      final openRestaurantIds =
                          restaurants
                              .map(
                                (doc) =>
                                    (doc.data()[
                                                'restaurantId'] ??
                                            doc.id)
                                        .toString(),
                              )
                              .toSet();

                      return FutureBuilder<
                          QuerySnapshot<
                              Map<String, dynamic>>>(
                        future: _promotionsFuture,
                        builder: (
                          context,
                          promotionSnapshot,
                        ) {
                          if (promotionSnapshot
                                  .connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 250,
                              child: Center(
                                child:
                                    CircularProgressIndicator(),
                              ),
                            );
                          }

                          final promotions =
                              promotionSnapshot
                                      .hasData
                                  ? _getActivePromotions(
                                      promotionSnapshot
                                          .data!,
                                    )
                                  : [];

                          return StreamBuilder<
                              QuerySnapshot<
                                  Map<String, dynamic>>>(
                            stream:
                                _recommendedMenuStream,
                            builder: (
                              context,
                              menuSnapshot,
                            ) {
                              if (menuSnapshot
                                      .connectionState ==
                                  ConnectionState
                                      .waiting) {
                                return const SizedBox(
                                  height: 250,
                                  child: Center(
                                    child:
                                        CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final recommendedDocs =
                                  menuSnapshot.data?.docs
                                          .where(
                                            (doc) {
                                              final data =
                                                  doc.data();

                                              return data[
                                                          'isActive'] ==
                                                      true &&
                                                  data[
                                                          'isAvailable'] ==
                                                      true &&
                                                  (data[
                                                              'restaurantId'] ??
                                                          '')
                                                      .toString()
                                                      .isNotEmpty;
                                            },
                                          )
                                          .toList() ??
                                      [];

                              final recommendedItems =
    recommendedDocs.where((doc) {
  final restaurantId =
      (doc.data()['restaurantId'] ?? '')
          .toString();

  return openRestaurantIds.contains(restaurantId) &&
      _serviceableRestaurantIds.contains(restaurantId);
}).toList();

                              if (promotions.isEmpty &&
                                  recommendedItems
                                      .isEmpty) {
                                return const SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: Text(
                                      'No recommendations available',
                                    ),
                                  ),
                                );
                              }

                              return SizedBox(
                                height: 220,
                                child: ListView(
                                  scrollDirection:
                                      Axis.horizontal,
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 20,
                                  ),
                                  children: [
                                    ...promotions.map(
                                      (doc) {
                                        final data =
                                            doc.data();

                                        final imageUrl =
                                            (data[
                                                        'imageUrl'] ??
                                                    '')
                                                .toString();

                                        final title =
                                            (data[
                                                        'title'] ??
                                                    '')
                                                .toString();

                                        final subtitle =
                                            (data[
                                                        'subtitle'] ??
                                                    '')
                                                .toString();

                                        final ctaText =
                                            (data[
                                                        'ctaText'] ??
                                                    '')
                                                .toString();

                                        return GestureDetector(
                                          onTap: () =>
                                              _openRecommendedPromotion(
                                            data,
                                          ),
                                          child: Container(
  width: 250,
  margin: const EdgeInsets.only(
    right: 16,
  ),
                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  Colors.white,
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                18,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors
                                                      .black
                                                      .withOpacity(
                                                    0.08,
                                                  ),
                                                  blurRadius:
                                                      10,
                                                  offset:
                                                      const Offset(
                                                    0,
                                                    4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            clipBehavior:
                                                Clip.antiAlias,
                                            child:
                                                Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                SizedBox(
                                                  height:
                                                      135,
                                                  width:
                                                      double.infinity,
                                                  child: imageUrl
                                                          .isNotEmpty
                                                      ? CachedNetworkImage(
                                                          imageUrl:
                                                              imageUrl,
                                                          fit: BoxFit
                                                              .cover,
                                                          placeholder:
                                                              (
                                                            context,
                                                            url,
                                                          ) {
                                                            return const Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2,
                                                              ),
                                                            );
                                                          },
                                                          errorWidget:
                                                              (
                                                            context,
                                                            url,
                                                            error,
                                                          ) {
                                                            return const Center(
                                                              child:
                                                                  Icon(
                                                                Icons
                                                                    .broken_image_outlined,
                                                                size:
                                                                    40,
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      : const Center(
                                                          child:
                                                              Icon(
                                                            Icons
                                                                .campaign_outlined,
                                                            size:
                                                                40,
                                                          ),
                                                        ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets
                                                          .fromLTRB(
                                                    14,
                                                    12,
                                                    14,
                                                    4,
                                                  ),
                                                  child:
                                                      Text(
                                                    title,
                                                    maxLines:
                                                        1,
                                                    overflow:
                                                        TextOverflow
                                                            .ellipsis,
                                                    style:
                                                        const TextStyle(
                                                      fontSize:
                                                          17,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                    ),
                                                  ),
                                                ),
                                                if (subtitle
                                                    .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .fromLTRB(
                                                      14,
                                                      0,
                                                      14,
                                                      4,
                                                    ),
                                                    child:
                                                        Text(
                                                      subtitle,
                                                      maxLines:
                                                          2,
                                                      overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                      style:
                                                          TextStyle(
                                                        fontSize:
                                                            13,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
Padding(
  padding: const EdgeInsets.fromLTRB(
    14,
    4,
    14,
    8,
  ),
  child: Text(
    ctaText.isNotEmpty
        ? ctaText
        : 'View Now',
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.deepPurple,
    ),
  ),
),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    ...recommendedItems.map(
                                      (doc) {
                                        final data =
                                            doc.data();

                                        final category =
                                            (data[
                                                        'category'] ??
                                                    '')
                                                .toString()
                                                .toLowerCase();

                                        final emoji =
                                            category.contains(
                                                    'pizza')
                                                ? '🍕'
                                                : category
                                                        .contains(
                                                        'burger',
                                                      )
                                                    ? '🍔'
                                                    : category
                                                            .contains(
                                                            'biryani',
                                                          )
                                                        ? '🍛'
                                                        : category
                                                                .contains(
                                                                'momo',
                                                              )
                                                            ? '🥟'
                                                            : '🍽️';

                                        final price =
                                            (data[
                                                        'price'] ??
                                                    0) as num;

                                        final totalRatings =
                                            (data[
                                                        'totalRatings'] ??
                                                    0) as num;

                                        final ratingValue =
                                            (data[
                                                        'rating'] ??
                                                    0) as num;

                                        final rating =
                                            totalRatings > 0
                                                ? ratingValue
                                                    .toStringAsFixed(
                                                    1,
                                                  )
                                                : 'New';

                                        final preparationTime =
                                            (data[
                                                        'preparationTime'] ??
                                                    20) as num;

                                        final restaurantId =
                                            (data[
                                                        'restaurantId'] ??
                                                    '')
                                                .toString();

                                        final imageUrl =
                                            (data[
                                                        'imageUrl'] ??
                                                    '')
                                                .toString();

                                        final matchingRestaurant =
                                            restaurants
                                                .where(
                                          (restaurantDoc) {
                                            final restaurantData =
                                                restaurantDoc
                                                    .data();

                                            final id =
                                                (restaurantData[
                                                            'restaurantId'] ??
                                                        restaurantDoc
                                                            .id)
                                                    .toString();

                                            return id ==
                                                restaurantId;
                                          },
                                        ).toList();

                                        final restaurantName =
                                            matchingRestaurant
                                                    .isNotEmpty
                                                ? (matchingRestaurant
                                                                .first
                                                                .data()[
                                                            'restaurantName'] ??
                                                        'Restaurant')
                                                    .toString()
                                                : 'Restaurant';

                                        return RecommendedCard(
                                          emoji: emoji,
                                          title:
                                              (data[
                                                          'name'] ??
                                                      '')
                                                  .toString(),
                                          price:
                                              '₹${price.toStringAsFixed(0)}',
                                          rating:
                                              rating,
                                          time:
                                              '${preparationTime.toInt()} min',
                                          restaurantId:
                                              restaurantId,
                                          restaurantName:
                                              restaurantName,
                                          imageUrl:
                                              imageUrl,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Text(
                      'Restaurants Near You',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: _restaurantsStream,
  builder: (
    context,
    snapshot,
  ) {
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
        child: Text(
          'No restaurants found',
        ),
      );
    }

    final restaurants = snapshot.data!.docs;

    if (_currentPosition == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Getting your location...',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final serviceableRestaurants =
        restaurants.where((doc) {
      final data = doc.data();

      final latitude = data['latitude'];
      final longitude = data['longitude'];

      if (latitude is! num ||
          longitude is! num) {
        return false;
      }

      final restaurantId =
          (data['restaurantId'] ?? doc.id)
              .toString();

      return _serviceableRestaurantIds
          .contains(restaurantId);
    }).toList();

    if (serviceableRestaurants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Sorry, your location is currently not serviceable.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Column(
      children: serviceableRestaurants.map(
        (doc) {
          final data = doc.data();

          return RestaurantCard(
            restaurantId:
                data['restaurantId'] ??
                    doc.id,
            name:
                data['restaurantName'] ??
                    '',
            cuisine:
                data['address'] ?? '',
            rating:
                (data['totalRatings'] ??
                            0) >
                        0
                    ? ((data[
                                    'averageRating'] ??
                                0) as num)
                        .toStringAsFixed(
                        1,
                      )
                    : 'New',
            time:
                '${data['estimatedDeliveryTime'] ?? 30} min',
            logoUrl:
                data['logoUrl'] as String?,
          );
        },
      ).toList(),
    );
  },
),
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
                duration:
                    const Duration(milliseconds: 300),
                child:
                    FloatingActionButton.extended(
                  heroTag: 'jamboo_ai',
                  backgroundColor:
                      Colors.deepPurple,
                  elevation: 8,
                  icon: ClipOval(
                    child: Image.asset(
                      'assets/images/jamboo_avatar.png',
                      width: 30,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  label: const Text(
                    'Jamboo AI',
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