import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/home_banner_service.dart';
import 'search_bar_widget.dart';

class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final service = HomeBannerService();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              Positioned.fill(
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: service.getCurrentBanner(),
                  builder: (context, snapshot) {
                    final data = snapshot.data;

                    final isActive =
                        data?['isActive'] == true;

                    final mediaUrl =
                        data?['mediaUrl']
                                ?.toString() ??
                            '';

                    if (isActive &&
                        mediaUrl.isNotEmpty) {
                      return CachedNetworkImage(
                        imageUrl: mediaUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) {
                          return Image.asset(
                            'assets/images/home_food_banner.png',
                            fit: BoxFit.cover,
                          );
                        },
                        errorWidget: (
                          context,
                          url,
                          error,
                        ) {
                          return Image.asset(
                            'assets/images/home_food_banner.png',
                            fit: BoxFit.cover,
                          );
                        },
                      );
                    }

                    return Image.asset(
                      'assets/images/home_food_banner.png',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(
                          alpha: 0.22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: const SearchBarWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}