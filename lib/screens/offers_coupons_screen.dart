import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final functionName =
          widget.isCartMode
              ? 'getAvailableCoupons'
              : 'getCustomerCoupons';

      final callable =
          _functions.httpsCallable(
        functionName,
      );

      final Map<String, dynamic> requestData = {};

      if (widget.isCartMode) {
        requestData['restaurantId'] =
            widget.restaurantId;
        requestData['subtotal'] =
            widget.subtotal;
      }

      final response =
          await callable.call(requestData);

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

      if (!mounted) return;

      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.message ??
            'Unable to load coupons.';
      });
    } catch (_) {
      if (!mounted) return;

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