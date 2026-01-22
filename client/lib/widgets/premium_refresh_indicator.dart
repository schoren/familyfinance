import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class PremiumRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const PremiumRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      offsetToArmed: 60,
      builder: (
        BuildContext context,
        Widget child,
        IndicatorController controller,
      ) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final double value = controller.value.clamp(0.0, 1.5);
            // Move the child down slightly as we pull (common pattern on Android/iOS)
            // But don't move it too much once it's already armed
            final double childTranslation = controller.isIdle ? 0.0 : math.min(value * 60, 80.0);
            
            return Stack(
              children: <Widget>[
                // Content gets slightly shifted down
                Transform.translate(
                  offset: Offset(0, childTranslation),
                  child: child,
                ),
                
                // Indicator is now on TOP of the content
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: controller.state == IndicatorState.idle ? 0 : 1,
                    child: Center(
                      child: Transform.translate(
                        // Follow the pull gesture
                        offset: Offset(0, (value * 30).clamp(0.0, 30.0)),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (controller.state == IndicatorState.loading)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                                  ),
                                )
                              else
                                Transform.rotate(
                                  angle: math.pi * value * 3, // Faster rotation
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    color: const Color(0xFF22C55E).withOpacity((value * 2).clamp(0.0, 1.0)),
                                    size: 24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: child,
    );
  }
}
