import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/rating_model.dart';
import '../services/rating_service.dart';

class RatingScreen extends StatefulWidget {

  final String orderId;
  final String orderNumber;

  final String restaurantId;
  final String restaurantName;

  const RatingScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _selectedRating = 0;

  final TextEditingController _reviewController =
      TextEditingController();

  bool _isSubmitting = false;

  String get emoji {
    switch (_selectedRating) {
      case 1:
        return "😡";
      case 2:
        return "😕";
      case 3:
        return "😐";
      case 4:
        return "🙂";
      case 5:
        return "😍";
      default:
        return "🍽️";
    }
  }

  String get title {
    switch (_selectedRating) {
      case 1:
        return "Very Bad";
      case 2:
        return "Bad";
      case 3:
        return "Average";
      case 4:
        return "Good";
      case 5:
        return "Excellent";
      default:
        return "Rate Your Order";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F5FF),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          "Rate Your Order",
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [

              const SizedBox(height: 15),

              AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 300,
                ),

                child: Text(
                  emoji,
                  key: ValueKey(emoji),
                  style: const TextStyle(
                    fontSize: 70,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "How was your food?\nYour feedback helps other customers.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 35),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: List.generate(
                  5,
                  (index) {

                    return IconButton(

                      splashRadius: 26,

                      onPressed: () {

                        setState(() {

                          _selectedRating =
                              index + 1;

                        });

                      },

                      icon: Icon(

                        index < _selectedRating
                            ? Icons.star
                            : Icons.star_border,

                        color: Colors.amber,
                        size: 40,

                      ),

                    );

                  },
                ),
              ),

              const SizedBox(height: 35),

              TextField(

                controller: _reviewController,

                minLines: 5,
                maxLines: 7,

                decoration: InputDecoration(

                  hintText:
                      "Write your review (optional)",

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),

                    borderSide:
                        const BorderSide(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                  ),

                ),

              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(

                  onPressed: _isSubmitting
                      ? null
                      : () async {

                          if (_selectedRating == 0) {

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please select a rating.",
                                ),
                              ),
                            );

                            return;
                          }

                          setState(() {
  _isSubmitting = true;
});

final rating = RatingModel(
  ratingId:
      FirebaseFirestore.instance
          .collection("ratings")
          .doc()
          .id,

  orderId: widget.orderId,
  orderNumber: widget.orderNumber,

  restaurantId: widget.restaurantId,
  restaurantName: widget.restaurantName,

  customerId:
      FirebaseAuth.instance.currentUser!.uid,

  customerName:
      FirebaseAuth.instance.currentUser?.displayName ??
          "Customer",

  rating: _selectedRating.toDouble(),

  review:
      _reviewController.text.trim(),

  createdAt: DateTime.now(),
);

await RatingService().submitRating(
  rating: rating,
);

if (!mounted) return;

setState(() {
  _isSubmitting = false;
});

                          showDialog(

                            context: context,

                            builder: (_) {

                              return AlertDialog(

                                title: const Text(
                                  "Thank You ❤️",
                                ),

                                content: const Text(
                                  "Your review has been submitted successfully.",
                                ),

                                actions: [

                                  ElevatedButton(

                                    onPressed: () {

  Navigator.pop(context);          // Dialog close

Navigator.pop(context, "rated"); // RatingScreen close + result bhejo

},

                                    child: const Text(
                                      "OK",
                                    ),

                                  ),

                                ],

                              );

                            },

                          );

                        },

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                        Colors.deepPurple,

                    foregroundColor:
                        Colors.white,

                    shape: RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(14),

                    ),

                  ),

                  child: _isSubmitting

                      ? const SizedBox(

                          width: 22,
                          height: 22,

                          child:
                              CircularProgressIndicator(

                            strokeWidth: 2,

                            color: Colors.white,

                          ),

                        )

                      : const Text(

                          "Submit Review",

                          style: TextStyle(

                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,

                          ),

                        ),

                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {

    _reviewController.dispose();

    super.dispose();

  }

}