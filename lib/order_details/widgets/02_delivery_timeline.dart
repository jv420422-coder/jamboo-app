import 'package:flutter/material.dart';

class DeliveryTimeline extends StatelessWidget {
  final Color statusColor;
  final String orderStatus;
  final Widget Function(
    String emoji,
    String title,
    bool completed,
  ) journeyStep;

  const DeliveryTimeline({
    super.key,
    required this.statusColor,
    required this.orderStatus,
    required this.journeyStep,
  });

  @override
  Widget build(BuildContext context) {
    final status = orderStatus
        .trim()
        .toLowerCase()
        .replaceAll(" ", "")
        .replaceAll("_", "");

    bool isCompleted(
      List<String> statuses,
    ) {
      return statuses.contains(status);
    }

    final showLiveTracking =
        status == "pickedup" ||
        status == "outfordelivery";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        18,
        14,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.045,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: statusColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Delivery Journey",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
              if (showLiveTracking)
                Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration:
                          const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Live tracking",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 22),

          LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              return SizedBox(
                width: constraints.maxWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 470,
                    child: Row(
                      children: [
                        journeyStep(
                          "🏪",
                          "Placed",
                          true,
                        ),

                        _connector(
                          statusColor,
                        ),

                        journeyStep(
                          "👨‍🍳",
                          "Preparing",
                          isCompleted([
                            "accepted",
                            "preparing",
                            "ready",
                            "pickedup",
                            "outfordelivery",
                            "delivered",
                          ]),
                        ),

                        _connector(
                          statusColor,
                        ),

                        journeyStep(
                          "📦",
                          "Ready",
                          isCompleted([
                            "ready",
                            "pickedup",
                            "outfordelivery",
                            "delivered",
                          ]),
                        ),

                        _connector(
                          statusColor,
                        ),

                        journeyStep(
                          "🛵",
                          "Out For Delivery",
                          isCompleted([
                            "pickedup",
                            "outfordelivery",
                            "delivered",
                          ]),
                        ),

                        _connector(
                          statusColor,
                        ),

                        journeyStep(
                          "🏠",
                          "Delivered",
                          isCompleted([
                            "delivered",
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _connector(
    Color color,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 3,
        ),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.30,
            ),
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}