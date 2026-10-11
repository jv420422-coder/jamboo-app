import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OffersCouponsScreen extends StatefulWidget {
  final String? restaurantId;
  final double? subtotal;

  const OffersCouponsScreen({
    super.key,
    this.restaurantId,
    this.subtotal,
  });

  bool get isCartMode =>
      restaurantId != null &&
      restaurantId!.trim().isNotEmpty &&
      subtotal != null &&
      subtotal! > 0;

  @override
  State<OffersCouponsScreen> createState() =>
      _OffersCouponsScreenState();
}

class _OffersCouponsScreenState
    extends State<OffersCouponsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _coupons = [];

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  static const String _cacheKey =
      'jamboo_customer_coupons_cache';

  static const Duration _cacheDuration =
      Duration(minutes: 10);

  static const Duration _cartCacheDuration =
      Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    if (widget.isCartMode) {
      await _loadCachedCartCoupons();

      if (!mounted) {
        return;
      }

      await _refreshCartCoupons();
      return;
    }

    await _loadCachedCoupons();

    if (!mounted) {
      return;
    }

    await _refreshCustomerCoupons();
  }

  Future<void> _loadCachedCoupons() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final cachedData =
          prefs.getString(_cacheKey);

      final cachedTime =
          prefs.getInt(
        '${_cacheKey}_time',
      );

      if (cachedData == null ||
          cachedTime == null) {
        return;
      }

      final cacheAge =
          DateTime.now().millisecondsSinceEpoch -
              cachedTime;

      if (cacheAge >
          _cacheDuration.inMilliseconds) {
        return;
      }

      final decoded =
          jsonDecode(cachedData);

      if (decoded is! List) {
        return;
      }

      final coupons = decoded
          .map(
            (coupon) =>
                Map<String, dynamic>.from(
              coupon as Map,
            ),
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _coupons = coupons;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      // Cache failure should never block
      // fresh coupon loading.
    }
  }

  Future<void> _refreshCustomerCoupons() async {
    try {
      final callable =
          _functions.httpsCallable(
        'getCustomerCoupons',
      );

      final response =
          await callable.call({});

      final data =
          Map<String, dynamic>.from(
        response.data as Map,
      );

      final rawCoupons =
          data['coupons'] is List
              ? data['coupons'] as List
              : [];

      final coupons = rawCoupons
          .map(
            (coupon) =>
                Map<String, dynamic>.from(
              coupon as Map,
            ),
          )
          .toList();

      await _saveCouponsToCache(coupons);

      if (!mounted) {
        return;
      }

      setState(() {
        _coupons = coupons;
        _isLoading = false;
        _errorMessage = null;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) {
        return;
      }

      if (_coupons.isNotEmpty) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.message ??
                'Unable to load coupons.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (_coupons.isNotEmpty) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load coupons. Please try again.';
      });
    }
  }

  Future<void> _saveCouponsToCache(
    List<Map<String, dynamic>> coupons,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        _cacheKey,
        jsonEncode(coupons),
      );

      await prefs.setInt(
        '${_cacheKey}_time',
        DateTime.now()
            .millisecondsSinceEpoch,
      );
    } catch (_) {
      // Cache failure should not affect
      // coupon functionality.
    }
  }

  String get _cartCacheKey {
    final restaurantId =
        widget.restaurantId!.trim();

    final subtotal =
        widget.subtotal!.toStringAsFixed(2);

    return 'jamboo_cart_coupons_${restaurantId}_$subtotal';
  }

  String get _cartCacheTimeKey =>
      '${_cartCacheKey}_time';

  Future<void> _loadCachedCartCoupons() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final cachedData =
          prefs.getString(_cartCacheKey);

      final cachedTime =
          prefs.getInt(_cartCacheTimeKey);

      if (cachedData == null ||
          cachedTime == null) {
        return;
      }

      final cacheAge =
          DateTime.now().millisecondsSinceEpoch -
              cachedTime;

      if (cacheAge >
          _cartCacheDuration.inMilliseconds) {
        return;
      }

      final decoded =
          jsonDecode(cachedData);

      if (decoded is! List) {
        return;
      }

      final coupons = decoded
          .map(
            (coupon) =>
                Map<String, dynamic>.from(
              coupon as Map,
            ),
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _coupons = coupons;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      // Cache failure should never block
      // fresh coupon loading.
    }
  }

  Future<void> _saveCartCouponsToCache(
    List<Map<String, dynamic>> coupons,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        _cartCacheKey,
        jsonEncode(coupons),
      );

      await prefs.setInt(
        _cartCacheTimeKey,
        DateTime.now()
            .millisecondsSinceEpoch,
      );
    } catch (_) {
      // Cache failure should not affect
      // coupon functionality.
    }
  }

  Future<void> _refreshCartCoupons() async {
    try {
      final callable =
          _functions.httpsCallable(
        'getAvailableCoupons',
      );

      final response =
          await callable.call({
        'restaurantId':
            widget.restaurantId,
        'subtotal':
            widget.subtotal,
      });

      final data =
          Map<String, dynamic>.from(
        response.data as Map,
      );

      final rawCoupons =
          data['coupons'] is List
              ? data['coupons'] as List
              : [];

      final coupons = rawCoupons
          .map(
            (coupon) =>
                Map<String, dynamic>.from(
              coupon as Map,
            ),
          )
          .toList();

      await _saveCartCouponsToCache(coupons);

      if (!mounted) {
        return;
      }

      setState(() {
        _coupons = coupons;
        _isLoading = false;
        _errorMessage = null;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) {
        return;
      }

      if (_coupons.isNotEmpty) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.message ??
                'Unable to load coupons.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (_coupons.isNotEmpty) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load coupons. Please try again.';
      });
    }
  }

  String _discountText(
    Map<String, dynamic> coupon,
  ) {
    final type =
        coupon['discountType'] ?? '';

    final value =
        (coupon['discountValue'] ?? 0)
            .toDouble();

    if (type == 'percentage') {
      return '${value.toStringAsFixed(0)}% OFF';
    }

    return '₹${value.toStringAsFixed(0)} OFF';
  }

  String _minimumOrderText(
    Map<String, dynamic> coupon,
  ) {
    final minimum =
        (coupon['minimumOrderValue'] ?? 0)
            .toDouble();

    if (minimum <= 0) {
      return 'No minimum order';
    }

    return 'Minimum order ₹${minimum.toStringAsFixed(0)}';
  }

  String _fundingText(
    Map<String, dynamic> coupon,
  ) {
    final fundedBy =
        coupon['fundedBy'] ?? 'jamboo';

    if (fundedBy == 'restaurant') {
      return 'Restaurant offer';
    }

    return 'Jamboo offer';
  }

  Widget _couponCard(
    BuildContext context,
    Map<String, dynamic> coupon,
  ) {
    final code =
        coupon['couponCode']?.toString() ?? '';

    final description =
        coupon['description']?.toString() ?? '';

    final discount =
        (coupon['discount'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.deepPurple,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  _discountText(coupon),
                  style: const TextStyle(
                    color:
                        Colors.deepPurple,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 10),
          Text(
            _minimumOrderText(coupon),
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fundingText(coupon),
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          if (widget.isCartMode) ...[
            const SizedBox(height: 4),
            Text(
              'You save ₹${discount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (widget.isCartMode) {
                  Navigator.pop(
                    context,
                    code,
                  );
                  return;
                }

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Add items to your cart to apply this coupon.',
                    ),
                  ),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.deepPurple,
                foregroundColor:
                    Colors.white,
              ),
              child: Text(
                widget.isCartMode
                    ? 'Apply'
                    : 'Use in Order',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 60,
                color:
                    Colors.deepPurple,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton(
                onPressed: _loadCoupons,
                child: const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_coupons.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Text(
                '🎁',
                style: TextStyle(
                  fontSize: 70,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              const Text(
                'No Coupons Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                widget.isCartMode
                    ? 'There are no coupons available for this restaurant right now.'
                    : 'There are no Jamboo coupons available right now.',
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.all(20),
      itemCount: _coupons.length,
      itemBuilder: (
        context,
        index,
      ) {
        return _couponCard(
          context,
          _coupons[index],
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F0FF),
        elevation: 0,
        title: Text(
          widget.isCartMode
              ? '🎁 Offers & Coupons'
              : '🎁 Jamboo Coupons',
          style: const TextStyle(
            color: Colors.black,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
}