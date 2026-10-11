import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme/app_colors.dart';
import '../services/location_service.dart';
import '../services/restaurant_serviceability_service.dart';
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
import 'location_unavailable_screen.dart';
import 'out_of_service_screen.dart';
import 'saved_addresses_screen.dart';

class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
int selectedIndex = 0;

final ScrollController _scrollController =
ScrollController();

final LocationService _locationService =
LocationService();

final RestaurantServiceabilityService
_serviceabilityService =
RestaurantServiceabilityService();

bool showAIPopup = false;
// Customer ki selected location ke coordinates.
double? _customerLatitude;
double? _customerLongitude;

// Location-related screen states.
bool _locationUnavailable = false;
bool _locationChecking = true;
bool _outOfService = false;

// GPS settings se app mein wapas aane par location dobara check karna.
bool _retryLocationOnResume = false;

// Serviceability check mein error aane par galat Out of Service
// screen dikhane se bachane ke liye.
bool _serviceabilityFailed = false;

Set<String> _serviceableRestaurantIds = {};

List<QueryDocumentSnapshot<Map<String, dynamic>>>
_restaurantDocs = [];

List<QueryDocumentSnapshot<Map<String, dynamic>>>
_recommendedMenuDocs = [];

List<Map<String, dynamic>> _promotions = [];

bool _restaurantsLoaded = false;
bool _recommendedMenuLoaded = false;
bool _promotionsLoaded = false;

bool _serviceabilityLoading = false;

StreamSubscription<
QuerySnapshot<Map<String, dynamic>>>?
_restaurantsSubscription;

StreamSubscription<
QuerySnapshot<Map<String, dynamic>>>?
_recommendedMenuSubscription;

// ---------------------------------------------------------------------------
// PERFORMANCE CACHE
// ---------------------------------------------------------------------------

// Serviceability radius ko baar-baar Firestore/service se fetch nahi karenge.
double? _cachedServiceableRadiusKm;

Future<double>? _serviceableRadiusFuture;

// Restaurant ke distance ko serviceability calculation ke time hi
// calculate karke store karenge. Ranking ke time dobara calculation nahi.
final Map<String, double>
_restaurantDistanceCache = {};

// Agar purana async serviceability request late complete ho,
// to naya result overwrite na ho.
int _serviceabilityRequestId = 0;

@override
void initState() {
super.initState();
WidgetsBinding.instance.addObserver(this);

_startHomeDataLoading();  

WidgetsBinding.instance.addPostFrameCallback((_) {  
  if (mounted) {  
    _updateCurrentLocation();  
  }  
});  

_scrollController.addListener(_handleScroll);

}

// ---------------------------------------------------------------------------
// HOME DATA
// ---------------------------------------------------------------------------

void _startHomeDataLoading() {
_restaurantsSubscription =
FirebaseFirestore.instance
.collection(
'restaurant_registrations',
)
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
.snapshots()
.listen(
(snapshot) {
if (!mounted) return;

setState(() {  
      _restaurantDocs =  
          snapshot.docs;  

      _restaurantsLoaded = true;  
    });  

    if (_customerLatitude != null &&
    _customerLongitude != null) {
  unawaited(
    _updateServiceableRestaurants(
      _restaurantDocs,
    ),
  );
}
  },  
  onError: (error) {  
    debugPrint(  
      'CUSTOMER RESTAURANT STREAM ERROR: $error',  
    );  

    if (!mounted) return;  

    setState(() {  
      _restaurantDocs = [];  
      _restaurantsLoaded = true;  
    });  
  },  
);  

_recommendedMenuSubscription =  
    FirebaseFirestore.instance  
        .collection('menu_items')  
        .where(  
          'isRecommended',  
          isEqualTo: true,  
        )  
        .snapshots()  
        .listen(  
  (snapshot) {  
    if (!mounted) return;  

    setState(() {  
      _recommendedMenuDocs =  
          snapshot.docs;  

      _recommendedMenuLoaded =  
          true;  
    });  
  },  
  onError: (error) {  
    debugPrint(  
      'CUSTOMER RECOMMENDED MENU STREAM ERROR: $error',  
    );  

    if (!mounted) return;  

    setState(() {  
      _recommendedMenuDocs = [];  
      _recommendedMenuLoaded = true;  
    });  
  },  
);  

_loadPromotions();

}
Future<void> _loadPromotions() async {
try {
final snapshot =
await FirebaseFirestore.instance
.collection('promotions')
.where(
'placement',
isEqualTo:
'recommended_for_you',
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

final promotions =  
      _getActivePromotions(  
    snapshot,  
  );  

  if (!mounted) return;  

  setState(() {  
    _promotions = promotions;  
    _promotionsLoaded = true;  
  });  
} catch (e) {  
  debugPrint(  
    'CUSTOMER RECOMMENDED PROMOTION LOAD ERROR: $e',  
  );  

  if (!mounted) return;  

  setState(() {  
    _promotions = [];  
    _promotionsLoaded = true;  
  });  
}

}

// ---------------------------------------------------------------------------
// SCROLL
// ---------------------------------------------------------------------------

void _handleScroll() {
if (!_scrollController.hasClients) {
return;
}

final shouldShow =  
    _scrollController.offset > 250;  

if (shouldShow != showAIPopup &&  
    mounted) {  
  setState(() {  
    showAIPopup = shouldShow;  
  });  
}

}

// ---------------------------------------------------------------------------
// LOCATION
// ---------------------------------------------------------------------------

Future<void> _updateCurrentLocation() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    if (!mounted) return;

    setState(() {
      _locationChecking = false;
      _locationUnavailable = true;
      _serviceabilityLoading = false;
    });

    return;
  }

  if (mounted) {
    setState(() {
      _locationChecking = true;
    });
  }

  try {
    final permissionReady =
        await _locationService.ensureLocationPermission();

    if (!permissionReady) {
      if (!mounted) return;

      setState(() {
        _locationChecking = false;
        _locationUnavailable = true;
        _serviceabilityLoading = false;
      });

      return;
    }

    final position =
        await _locationService.getCurrentPosition();

    if (position == null) {
      if (!mounted) return;

      setState(() {
        _locationChecking = false;
        _locationUnavailable = true;
        _serviceabilityLoading = false;
      });

      return;
    }

    if (!mounted) return;

    setState(() {

      _customerLatitude = position.latitude;
      _customerLongitude = position.longitude;

      _locationUnavailable = false;
      _locationChecking = false;
      _outOfService = false;
      _serviceabilityFailed = false;
      _serviceabilityLoading = true;
    });

    // Restaurant stream load ho chuka hai toh serviceability check karo.
    if (_restaurantsLoaded) {
      await _updateServiceableRestaurants(
        _restaurantDocs,
      );
    }

    try {
      final address =
          await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (address != null && address.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(
          {
            'currentLatitude': position.latitude,
            'currentLongitude': position.longitude,
            'currentAddress': address,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      debugPrint(
        'CURRENT LOCATION: '
        '${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint(
        'CUSTOMER LOCATION ADDRESS UPDATE ERROR: $e',
      );
    }
  } catch (e) {
    debugPrint('CUSTOMER LOCATION ERROR: $e');

    if (!mounted) return;

    setState(() {
      _locationChecking = false;
      _locationUnavailable = true;
      _serviceabilityLoading = false;
    });
  }
}

// ---------------------------------------------------------------------------
// SERVICEABILITY RADIUS CACHE
// ---------------------------------------------------------------------------

Future<double>
_getCachedServiceableRadiusKm() async {
// Already loaded.
if (_cachedServiceableRadiusKm !=
null) {
return _cachedServiceableRadiusKm!;
}

// If another request is already loading the radius,  
// reuse the same Future instead of creating another request.  
if (_serviceableRadiusFuture !=  
    null) {  
  return _serviceableRadiusFuture!;  
}  

final future =  
    _serviceabilityService  
        .getServiceableRadiusKm();  

_serviceableRadiusFuture =  
    future;  

try {  
  final radiusKm =  
      await future;  

  _cachedServiceableRadiusKm =  
      radiusKm;  

  return radiusKm;  
} finally {  
  if (identical(  
    _serviceableRadiusFuture,  
    future,  
  )) {  
    _serviceableRadiusFuture =  
        null;  
  }  
}

}

// ---------------------------------------------------------------------------
// SERVICEABLE RESTAURANTS
// ---------------------------------------------------------------------------

Future<void> _updateServiceableRestaurants(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> restaurants,
) async {
  final latitude = _customerLatitude;
  final longitude = _customerLongitude;

  if (latitude == null || longitude == null) {
    if (mounted) {
      setState(() {
        _serviceabilityLoading = false;
      });
    }
    return;
  }

  // Current request ID.
  final requestId = ++_serviceabilityRequestId;

  try {
    // Configured service radius.
    final radiusKm = await _getCachedServiceableRadiusKm();

    // Newer request start ho gayi ho toh purana result ignore karo.
    if (!mounted || requestId != _serviceabilityRequestId) {
      return;
    }

    final serviceableIds = <String>{};
    final distanceCache = <String, double>{};

    var hasRestaurantWithCoordinates = false;

    for (final restaurantDoc in restaurants) {
      final data = restaurantDoc.data();

      final restaurantLatitude = data['latitude'];
      final restaurantLongitude = data['longitude'];

      if (restaurantLatitude is! num ||
          restaurantLongitude is! num) {
        continue;
      }

      hasRestaurantWithCoordinates = true;

      final restaurantId =
          (data['restaurantId'] ?? restaurantDoc.id).toString();

      final distanceKm = Geolocator.distanceBetween(
            latitude,
            longitude,
            restaurantLatitude.toDouble(),
            restaurantLongitude.toDouble(),
          ) /
          1000;

      distanceCache[restaurantId] = distanceKm;

      if (distanceKm <= radiusKm) {
        serviceableIds.add(restaurantId);
      }
    }

    if (!mounted || requestId != _serviceabilityRequestId) {
      return;
    }

    setState(() {
      _serviceableRestaurantIds = serviceableIds;

      _restaurantDistanceCache
        ..clear()
        ..addAll(distanceCache);

      _serviceabilityFailed = false;

      _outOfService =
          restaurants.isNotEmpty &&
          hasRestaurantWithCoordinates &&
          serviceableIds.isEmpty;

      _serviceabilityLoading = false;
      _locationChecking = false;
    });
  } catch (e) {
    debugPrint('CUSTOMER SERVICEABILITY ERROR: $e');

    if (!mounted || requestId != _serviceabilityRequestId) {
      return;
    }

    setState(() {
      _serviceabilityFailed = true;
      _outOfService = false;
      _serviceabilityLoading = false;
      _locationChecking = false;
    });
  }
}
// ---------------------------------------------------------------------------
// PROMOTION NAVIGATION
// ---------------------------------------------------------------------------
Future<void> _openRecommendedPromotion(
Map<String, dynamic> data,
) async {
final targetType =
(data['targetType'] ?? 'none')
.toString();

final targetId =  
    (data['targetId'] ?? '')  
        .toString()  
        .trim();  

if (targetType == 'none' ||  
    targetId.isEmpty) {  
  return;  
}  

if (targetType ==  
    'restaurant') {  
  try {  
    final restaurantSnapshot =  
        await FirebaseFirestore.instance  
            .collection(  
              'restaurant_registrations',  
            )  
            .where(  
              'restaurantId',  
              isEqualTo: targetId,  
            )  
            .limit(1)  
            .get();  

    if (!mounted) return;  

    if (restaurantSnapshot  
        .docs.isEmpty) {  
      ScaffoldMessenger.of(  
        context,  
      ).showSnackBar(  
        const SnackBar(  
          content: Text(  
            'Restaurant is no longer available.',  
          ),  
        ),  
      );  

      return;  
    }  

    final restaurantData =  
        restaurantSnapshot  
            .docs  
            .first  
            .data();  

    final isApproved =  
        restaurantData[  
                'verificationStatus'] ==  
            'approved';  

    final isActive =  
        restaurantData[  
                'isActive'] ==  
            true;  

    final isOpen =  
        restaurantData[  
                'isOpen'] ==  
            true;  

    if (!isApproved ||  
        !isActive ||  
        !isOpen) {  
      ScaffoldMessenger.of(  
        context,  
      ).showSnackBar(  
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
          restaurantId:  
              targetId,  
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

if (targetType ==  
    'category') {  
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

if (targetType ==  
    'menu_item') {  
  try {  
    final menuSnapshot =  
        await FirebaseFirestore.instance  
            .collection(  
              'menu_items',  
            )  
            .doc(targetId)  
            .get();  

    if (!mounted) return;  

    if (!menuSnapshot.exists) {  
      ScaffoldMessenger.of(  
        context,  
      ).showSnackBar(  
        const SnackBar(  
          content: Text(  
            'Menu item is no longer available.',  
          ),  
        ),  
      );  

      return;  
    }  

    final menuData =  
        menuSnapshot.data();  

    if (menuData == null) {  
      return;  
    }  

    final restaurantId =  
        (menuData[  
                    'restaurantId'] ??  
                '')  
            .toString();  

    if (restaurantId.isEmpty) {  
      return;  
    }  

    final restaurantSnapshot =  
        await FirebaseFirestore.instance  
            .collection(  
              'restaurant_registrations',  
            )  
            .where(  
              'restaurantId',  
              isEqualTo:  
                  restaurantId,  
            )  
            .limit(1)  
            .get();  

    if (!mounted) return;  

    if (restaurantSnapshot  
        .docs.isEmpty) {  
      ScaffoldMessenger.of(  
        context,  
      ).showSnackBar(  
        const SnackBar(  
          content: Text(  
            'Restaurant is no longer available.',  
          ),  
        ),  
      );  

      return;  
    }  

    final restaurantData =  
        restaurantSnapshot  
            .docs  
            .first  
            .data();  

    final isApproved =  
        restaurantData[  
                'verificationStatus'] ==  
            'approved';  

    final isActive =  
        restaurantData[  
                'isActive'] ==  
            true;  

    final isOpen =  
        restaurantData[  
                'isOpen'] ==  
            true;  

    if (!isApproved ||  
        !isActive ||  
        !isOpen) {  
      ScaffoldMessenger.of(  
        context,  
      ).showSnackBar(  
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
          restaurantId:  
              restaurantId,  
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

// ---------------------------------------------------------------------------
// PROMOTIONS
// ---------------------------------------------------------------------------
List<Map<String, dynamic>>
_getActivePromotions(
QuerySnapshot<
Map<String, dynamic>>
snapshot,
) {
final now =
DateTime.now();

final promotions =  
    snapshot.docs  
        .map((doc) {  
  final data =  
      doc.data();  

  return {  
    'id': doc.id,  
    ...data,  
  };  
}).where((promotion) {  
  final startAt =  
      _dateTimeFromFirestore(  
    promotion['startAt'],  
  );  

  final endAt =  
      _dateTimeFromFirestore(  
    promotion['endAt'],  
  );  

  final targetAudience =  
      (promotion[  
                  'targetAudience'] ??  
              'all_customers')  
          .toString();  

  if (targetAudience !=  
      'all_customers') {  
    return false;  
  }  

  if (startAt != null &&  
      now.isBefore(startAt)) {  
    return false;  
  }  

  if (endAt != null &&  
      now.isAfter(endAt)) {  
    return false;  
  }  

  return true;  
}).toList();  

promotions.sort((a, b) {  
  final priorityA =  
      _toInt(  
    a['priority'],  
  );  

  final priorityB =  
      _toInt(  
    b['priority'],  
  );  

  if (priorityA !=  
      priorityB) {  
    return priorityB  
        .compareTo(  
      priorityA,  
    );  
  }  

  final orderA =  
      _toInt(  
    a['displayOrder'],  
  );  

  final orderB =  
      _toInt(  
    b['displayOrder'],  
  );  

  return orderA.compareTo(  
    orderB,  
  );  
});  

return promotions;

}

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
  return DateTime.tryParse(  
    value,  
  );  
}  

return null;

}

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

// ---------------------------------------------------------------------------
// RECOMMENDED ITEMS
// ---------------------------------------------------------------------------

List<QueryDocumentSnapshot<Map<String, dynamic>>>
    _getRecommendedItems() {
  if (!_recommendedMenuLoaded ||
      !_restaurantsLoaded ||
      _customerLatitude == null ||
      _customerLongitude == null ||
      _serviceabilityLoading ||
      _serviceabilityFailed) {
    return [];
  }

  final openRestaurantIds = _restaurantDocs
      .map(
        (doc) => (doc.data()['restaurantId'] ?? doc.id)
            .toString(),
      )
      .toSet();

  return _recommendedMenuDocs.where((doc) {
    final data = doc.data();

    final isActive = data['isActive'] == true;
    final isAvailable = data['isAvailable'] == true;

    final restaurantId =
        (data['restaurantId'] ?? '').toString();

    if (!isActive ||
        !isAvailable ||
        restaurantId.isEmpty) {
      return false;
    }

    return openRestaurantIds.contains(restaurantId) &&
        _serviceableRestaurantIds.contains(restaurantId);
  }).toList();
}

// ---------------------------------------------------------------------------
// RECOMMENDED SECTION
// ---------------------------------------------------------------------------

Widget _buildRecommendedSection() {
final recommendedItems =
_getRecommendedItems();

final hasPromotions =  
    _promotions.isNotEmpty;  

final hasRecommendedItems =  
    recommendedItems  
        .isNotEmpty;  

final stillLoading =  
    !_promotionsLoaded ||  
    !_restaurantsLoaded ||  
    !_recommendedMenuLoaded ||  
    _serviceabilityLoading;  

if (!hasPromotions &&  
    !hasRecommendedItems &&  
    stillLoading) {  
  return const SizedBox(  
    height: 220,  
    child: Center(  
      child:  
          CircularProgressIndicator(),  
    ),  
  );  
}  

if (!hasPromotions &&  
    !hasRecommendedItems) {  
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
      ..._promotions.map(  
        (doc) {  
          final imageUrl =  
              (doc['imageUrl'] ??  
                      '')  
                  .toString();  

          final title =  
              (doc['title'] ??  
                      '')  
                  .toString();  

          final subtitle =  
              (doc['subtitle'] ??  
                      '')  
                  .toString();  

          final ctaText =  
              (doc['ctaText'] ??  
                      '')  
                  .toString();  

          return GestureDetector(  
            onTap: () {  
              _openRecommendedPromotion(  
                doc,  
              );  
            },  
            child: Container(  
              width: 250,  
              margin:  
                  const EdgeInsets  
                      .only(  
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
              child: Column(  
                crossAxisAlignment:  
                    CrossAxisAlignment  
                        .start,  
                children: [  
                  SizedBox(  
                    height: 135,  
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
                              size: 40,  
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
                    child: Text(  
                      title,  
                      maxLines: 1,  
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
                      child: Text(  
                        subtitle,  
                        maxLines: 2,  
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
                  const SizedBox(  
                    height: 4,  
                  ),  
                  Padding(  
                    padding:  
                        const EdgeInsets  
                            .fromLTRB(  
                      14,  
                      4,  
                      14,  
                      8,  
                    ),  
                    child: Text(  
                      ctaText  
                              .isNotEmpty  
                          ? ctaText  
                          : 'View Now',  
                      style:  
                          const TextStyle(  
                        fontSize:  
                            14,  
                        fontWeight:  
                            FontWeight  
                                .bold,  
                        color: Colors  
                            .deepPurple,  
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
              (data['category'] ??  
                      '')  
                  .toString()  
                  .toLowerCase();  

          final emoji =  
              category.contains(  
                      'pizza')  
                  ? '🍕'  
                  : category.contains(  
                          'burger')  
                      ? '🍔'  
                      : category.contains(  
                              'biryani')  
                          ? '🍛'  
                          : category.contains(  
                                  'momo')  
                              ? '🥟'  
                              : '🍽️';  

          final price =  
              (data['price'] ??  
                      0) as num;  

          final totalRatings =  
              (data[  
                          'totalRatings'] ??  
                      0) as num;  

          final ratingValue =  
              (data['rating'] ??  
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
              (data['imageUrl'] ??  
                      '')  
                  .toString();  

          final matchingRestaurant =  
              _restaurantDocs.where(  
            (restaurantDoc) {  
              final restaurantData =  
                  restaurantDoc  
                      .data();  

              final id =  
                  (restaurantData[  
                              'restaurantId'] ??  
                          restaurantDoc.id)  
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
                (data['name'] ??  
                        '')  
                    .toString(),  
            price:  
                '₹${price.toStringAsFixed(0)}',  
            rating: rating,  
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

}

// ---------------------------------------------------------------------------
// RESTAURANTS SECTION
// ---------------------------------------------------------------------------

Widget _buildRestaurantsSection() {
if (!_restaurantsLoaded) {
return const Center(
child:
CircularProgressIndicator(),
);
}

if (_restaurantDocs.isEmpty) {  
  return const Padding(  
    padding:  
        EdgeInsets.all(20),  
    child: Text(  
      'No restaurants found',  
    ),  
  );  
}  

if (_customerLatitude == null ||
    _customerLongitude == null ||
    _serviceabilityLoading) {  
  return const Padding(  
    padding:  
        EdgeInsets.all(20),  
    child: Center(  
      child: Text(  
        'Finding restaurants near you...',  
        textAlign:  
            TextAlign.center,  
      ),  
    ),  
  );  
}  

final serviceableRestaurants =  
    _restaurantDocs.where(  
  (doc) {  
    final data =  
        doc.data();  

    final latitude =  
        data['latitude'];  

    final longitude =  
        data['longitude'];  

    if (latitude is! num ||  
        longitude is! num) {  
      return false;  
    }  

    final restaurantId =  
        (data['restaurantId'] ??  
                doc.id)  
            .toString();  

    return _serviceableRestaurantIds  
        .contains(  
      restaurantId,  
    );  
  },  
).toList();  

if (serviceableRestaurants  
    .isEmpty) {  
  return const Padding(  
    padding:  
        EdgeInsets.all(20),  
    child: Center(  
      child: Text(  
        'No restaurants are currently open in your area.',  
        textAlign:  
            TextAlign.center,  
        style: TextStyle(  
          fontSize: 15,  
          fontWeight:  
              FontWeight.w500,  
        ),  
      ),  
    ),  
  );  
}  

// ----------------------------------------------------------  
// SMART RESTAURANT RANKING  
//  
// Nearby restaurants get higher priority.  
// Good rating gets higher priority.  
// Rating count adds trust.  
// ----------------------------------------------------------  

final rankedRestaurants =  
    serviceableRestaurants.map(  
  (doc) {  
    final data =  
        doc.data();  

    final latitude =  
        (data['latitude']  
                as num)  
            .toDouble();  

    final longitude =  
        (data['longitude']  
                as num)  
            .toDouble();  

    final restaurantId =  
        (data['restaurantId'] ??  
                doc.id)  
            .toString();  

    // ---------------------------------------------------------------------  
    // PERFORMANCE:  
    //  
    // Serviceability calculation ke waqt distance already calculate hua  
    // hai, isliye yahan cached distance use karenge.  
    //  
    // Fallback rakha gaya hai taaki agar cache mein kisi wajah se  
    // restaurant na mile to existing behaviour break na ho.  
    // ---------------------------------------------------------------------  

    double distanceKm =  
        _restaurantDistanceCache[  
                restaurantId] ??  
            -1;  

    if (distanceKm < 0) {
  distanceKm = Geolocator.distanceBetween(
        _customerLatitude!,
        _customerLongitude!,
        latitude,
        longitude,
      ) /
      1000;
}

    final rating =  
        _toDouble(  
      data['averageRating'] ??  
          data['rating'] ??  
          0,  
    ).clamp(  
      0.0,  
      5.0,  
    );  

    final totalRatings =  
        _toInt(  
      data['totalRatings'],  
    );  

    return _RestaurantRankingData(  
      doc: doc,  
      distanceKm:  
          distanceKm,  
      rating: rating,  
      totalRatings:  
          totalRatings,  
    );  
  },  
).toList();  

// Highest trust score first.  
rankedRestaurants.sort(  
  (a, b) {  
    final scoreDifference =  
        b.score.compareTo(  
      a.score,  
    );  

    if (scoreDifference !=  
        0) {  
      return scoreDifference;  
    }  

    // If scores are almost same,  
    // nearest restaurant comes first.  
    return a.distanceKm  
        .compareTo(  
      b.distanceKm,  
    );  
  },  
);  

return Column(  
  children:  
      rankedRestaurants.map(  
    (item) {  
      final data =  
          item.doc.data();  

      return RestaurantCard(  
        restaurantId:  
            item.doc.id,  
        name:  
            data['restaurantName'] ??  
                '',  
        cuisine:  
            data['address'] ??  
                '',  
        rating:  
            item.totalRatings >  
                    0  
                ? item.rating  
                    .toStringAsFixed(  
                    1,  
                  )  
                : 'New',  
        time:  
            '${data['estimatedDeliveryTime'] ?? 30} min',  
        logoUrl:  
            data['logoUrl']  
                as String?,  
      );  
    },  
  ).toList(),  
);

}

// ---------------------------------------------------------------------------
// DOUBLE
// ---------------------------------------------------------------------------
double _toDouble(
dynamic value,
) {
if (value is num) {
return value.toDouble();
}

return double.tryParse(  
      value?.toString() ?? '',  
    ) ??  
    0;

}
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed &&
      _retryLocationOnResume) {
    _retryLocationOnResume = false;

    _updateCurrentLocation();
  }
}
Future<void> _openLocationSettings() async {
  _retryLocationOnResume = true;

  final opened = await _locationService.openLocationSettings();

  if (!opened && mounted) {
    _retryLocationOnResume = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open location settings.'),
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// CHOOSE SAVED ADDRESS
// ---------------------------------------------------------------------------

Future<void> _chooseSavedAddress() async {
  final result = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      builder: (_) => const SavedAddressesScreen(),
    ),
  );

  if (!mounted || result == null) return;

  final latitude = result['latitude'];
  final longitude = result['longitude'];

  if (latitude is! num || longitude is! num) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This address does not have valid location coordinates. '
          'Please choose another address.',
        ),
      ),
    );
    return;
  }

  final user = FirebaseAuth.instance.currentUser;

  final addressParts = <String>[
    if ((result['address'] ?? '').toString().trim().isNotEmpty)
      result['address'].toString().trim(),
    if ((result['landmark'] ?? '').toString().trim().isNotEmpty)
      result['landmark'].toString().trim(),
    if ((result['city'] ?? '').toString().trim().isNotEmpty)
      result['city'].toString().trim(),
    if ((result['state'] ?? '').toString().trim().isNotEmpty)
      result['state'].toString().trim(),
    if ((result['pincode'] ?? '').toString().trim().isNotEmpty)
      result['pincode'].toString().trim(),
  ];

  setState(() {
    _customerLatitude = latitude.toDouble();
    _customerLongitude = longitude.toDouble();

    // Selected address GPS se nahi, saved address se aaya hai.

    _locationUnavailable = false;
    _locationChecking = false;
    _outOfService = false;
    _serviceabilityFailed = false;
    _serviceabilityLoading = true;
  });

  // Selected address ko user profile mein save karo.
  if (user != null) {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'currentLatitude': latitude.toDouble(),
          'currentLongitude': longitude.toDouble(),
          'currentAddress': addressParts.join(', '),
          if (result['addressId'] != null)
            'selectedAddressId': result['addressId'],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('SAVED ADDRESS UPDATE ERROR: $e');
    }
  }

  if (!mounted) return;

  // Agar restaurant stream load ho chuki hai, turant serviceability check karo.
  if (_restaurantsLoaded) {
    await _updateServiceableRestaurants(_restaurantDocs);
  }
}

// ---------------------------------------------------------------------------
// DISPOSE
// ---------------------------------------------------------------------------

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
_restaurantsSubscription
?.cancel();

_recommendedMenuSubscription  
    ?.cancel();  

_scrollController  
    .removeListener(  
  _handleScroll,  
);  

_scrollController  
    .dispose();  

super.dispose();

}

// ---------------------------------------------------------------------------
// BUILD
// ---------------------------------------------------------------------------

@override
Widget build(
BuildContext context,
) {
return Scaffold(
backgroundColor:
AppColors.background,
body: _locationChecking
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : _locationUnavailable
        ? LocationUnavailableScreen(
            onChooseSavedAddress: _chooseSavedAddress,
            onTurnOnLocation: _openLocationSettings,
          )
        : (_outOfService && !_serviceabilityFailed)
            ? OutOfServiceScreen(
                onChangeLocation: _chooseSavedAddress,
              )
            : Stack(
children: [
SafeArea(
child:
SingleChildScrollView(
controller:
_scrollController,
child: Column(
crossAxisAlignment:
CrossAxisAlignment
.start,
children: [
const HeaderWidget(),

const SizedBox(  
                height: 4,  
              ),  

              const Padding(  
                padding:  
                    EdgeInsets  
                        .symmetric(  
                  horizontal: 20,  
                ),  
                child: Text(  
                  'What would you like to eat today?',  
                  style: TextStyle(  
                    fontSize: 24,  
                    fontWeight:  
                        FontWeight  
                            .w700,  
                    color:  
                        Colors.black87,  
                    height: 1.2,  
                    letterSpacing:  
                        -0.2,  
                  ),  
                ),  
              ),  

              const SizedBox(  
                height: 14,  
              ),  

              const HomeHeroBanner(),  

              const SizedBox(  
                height: 10,  
              ),  

              const AICard(),  

              const SizedBox(  
                height: 12,  
              ),  

              const Padding(  
                padding:  
                    EdgeInsets  
                        .symmetric(  
                  horizontal: 20,  
                ),  
                child: Text(  
                  'Categories',  
                  style: TextStyle(  
                    fontSize: 22,  
                    fontWeight:  
                        FontWeight  
                            .bold,  
                  ),  
                ),  
              ),  

              const SizedBox(  
                height: 10,  
              ),  

              SizedBox(  
                height: 110,  
                child:  
                    ListView(  
                  scrollDirection:  
                      Axis.horizontal,  
                  padding:  
                      const EdgeInsets  
                          .symmetric(  
                    horizontal: 20,  
                  ),  
                  children: const [  
                    CategoryCard(  
                      imagePath:  
                          'assets/images/pizza.png',  
                      title:  
                          'Pizza',  
                    ),  
                    CategoryCard(  
                      imagePath:  
                          'assets/images/burger.png',  
                      title:  
                          'Burger',  
                    ),  
                    CategoryCard(  
                      imagePath:  
                          'assets/images/noodles.png',  
                      title:  
                          'Noodles',  
                    ),  
                    CategoryCard(  
                      imagePath:  
                          'assets/images/momos.png',  
                      title:  
                          'Momos',  
                    ),  
                    CategoryCard(  
                      imagePath:  
                          'assets/images/biryani.png',  
                      title:  
                          'Biryani',  
                    ),  
                    CategoryCard(  
                      imagePath:  
                          'assets/images/paneer.png',  
                      title:  
                          'Paneer',  
                    ),  
                    CategoryCard(  
                      imagePath:  
                          'assets/images/chicken.png',  
                      title:  
                          'Chicken',  
                    ),  
                    CategoryCard(  
                      imagePath:  
                          'assets/images/dessert.png',  
                      title:  
                          'Dessert',  
                    ),  
                  ],  
                ),  
              ),  

              const SizedBox(  
                height: 20,  
              ),  

              const OfferBanner(),  

              const SizedBox(  
                height: 25,  
              ),  

              const Padding(  
                padding:  
                    EdgeInsets  
                        .symmetric(  
                  horizontal: 20,  
                ),  
                child: Text(  
                  '❤️ Recommended for You',  
                  style: TextStyle(  
                    fontSize: 22,  
                    fontWeight:  
                        FontWeight  
                            .bold,  
                  ),  
                ),  
              ),  

              const SizedBox(  
                height: 15,  
              ),  

              _buildRecommendedSection(),  

              const SizedBox(  
                height: 25,  
              ),  

              const Padding(  
                padding:  
                    EdgeInsets  
                        .symmetric(  
                  horizontal: 20,  
                ),  
                child: Text(  
                  'Restaurants Near You',  
                  style: TextStyle(  
                    fontSize: 22,  
                    fontWeight:  
                        FontWeight  
                            .bold,  
                  ),  
                ),  
              ),  

              _buildRestaurantsSection(),  
            ],  
          ),  
        ),  
      ),  

      // -------------------------------------------------------------------  
      // JAMBOO AI FLOATING BUTTON  
      // -------------------------------------------------------------------  

      if (showAIPopup)  
        Positioned(  
          right: 20,  
          bottom: 90,  
          child:  
              AnimatedScale(  
            scale:  
                showAIPopup  
                    ? 1  
                    : 0,  
            duration:  
                const Duration(  
              milliseconds: 300,  
            ),  
            child:  
                FloatingActionButton  
                    .extended(  
              heroTag:  
                  'jamboo_ai',  
              backgroundColor:  
                  Colors  
                      .deepPurple,  
              elevation: 8,  
              icon:  
                  ClipOval(  
                child:  
                    Image.asset(  
                  'assets/images/jamboo_avatar.png',  
                  width: 30,  
                  height: 80,  
                  fit: BoxFit  
                      .cover,  
                ),  
              ),  
              label:  
                  const Text(  
                'Jamboo AI',  
                style:  
                    TextStyle(  
                  color:  
                      Colors.white,  
                  fontWeight:  
                      FontWeight  
                          .bold,  
                ),  
              ),  
              onPressed:  
                  () {  
                Navigator.push(  
                  context,  
                  MaterialPageRoute(  
                    builder:  
                        (context) =>  
                            const JambooAIScreen(),  
                  ),  
                );  
              },  
            ),  
          ),  
        ),  
    ],  
  ),  

  // -----------------------------------------------------------------------  
  // BOTTOM NAVIGATION  
  // -----------------------------------------------------------------------
  bottomNavigationBar:
    (_locationChecking ||
            _locationUnavailable ||
            (_outOfService && !_serviceabilityFailed))
        ? null
        : BottomNavbar(
    currentIndex:  
        selectedIndex,  
    onTap: (index) {  
      setState(() {  
        selectedIndex =  
            index;  
      });  

      if (index == 1) {  
        Navigator.push(  
          context,  
          MaterialPageRoute(  
            builder:  
                (context) =>  
                    const Under199Screen(),  
          ),  
        );  
      }  

      if (index == 2) {  
        Navigator.push(  
          context,  
          MaterialPageRoute(  
            builder:  
                (context) =>  
                    const CartScreen(),  
          ),  
        );  
      }  

      if (index == 3) {  
        Navigator.push(  
          context,  
          MaterialPageRoute(  
            builder:  
                (context) =>  
                    const ProfileScreen(),  
          ),  
        );  
      }  
    },  
  ),  
);

}
}

// =============================================================================
// RESTAURANT RANKING DATA
// =============================================================================

class _RestaurantRankingData {
final QueryDocumentSnapshot<
Map<String, dynamic>> doc;

final double distanceKm;
final double rating;
final int totalRatings;

_RestaurantRankingData({
required this.doc,
required this.distanceKm,
required this.rating,
required this.totalRatings,
});

double get score {
// Distance score:
// 0 km = 1.0
// 7 km = 0.0

final distanceScore =  
    (1 - (distanceKm / 7))  
        .clamp(  
  0.0,  
  1.0,  
);  

// Rating score:  
// 5 star = 1.0  

final ratingScore =  
    (rating / 5)  
        .clamp(  
  0.0,  
  1.0,  
);  

// Rating count trust score.  

final ratingCountScore =  
    (totalRatings /  
            (totalRatings + 50))  
        .clamp(  
  0.0,  
  1.0,  
);  

return  
    (distanceScore * 0.50) +  
    (ratingScore * 0.35) +  
    (ratingCountScore * 0.15);

}
}