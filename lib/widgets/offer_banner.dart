import 'dart:async';
import 'package:flutter/material.dart';

class OfferBanner extends StatefulWidget {
  const OfferBanner({super.key});

  @override
  State<OfferBanner> createState() => _OfferBannerState();
}

class _OfferBannerState extends State<OfferBanner> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<String> banners = [
    "assets/images/offer_banner1.png",
    "assets/images/offer_banner2.png",
    "assets/images/offer_banner3.png",
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        if (_pageController.hasClients) {
          _currentPage++;

          if (_currentPage >= banners.length) {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Column(
        children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(22),

            child: AspectRatio(
              aspectRatio: 16 / 4.5,

              child: PageView.builder(
                controller: _pageController,

                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },

                itemCount: banners.length,

                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Future me alag offer screen open karenge

                      // if(index==0){}
                      // if(index==1){}
                      // if(index==2){}
                    },

                    child: Image.asset(
                      banners[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              banners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),

                margin:
                    const EdgeInsets.symmetric(horizontal: 4),

                width: _currentPage == index ? 18 : 8,

                height: 8,

                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF7E57C2)
                      : Colors.grey.shade300,

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