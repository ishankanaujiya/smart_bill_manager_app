import 'package:flutter/material.dart';

class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Background blob shape
            Positioned(
              top: height * 0.05,
              child: Container(
                width: width * 0.85,
                height: height * 0.7,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F6),
                  borderRadius: BorderRadius.circular(width * 0.4),
                ),
              ),
            ),

            // Table
            Positioned(
              bottom: height * 0.12,
              child: Container(
                width: width * 0.55,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8C9A0),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8C9A0).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),

            // Left person (woman with phone)
            Positioned(
              bottom: height * 0.15,
              left: width * 0.08,
              child: _PersonWidget(
                height: height * 0.52,
                bodyColor: const Color(0xFF6C5CE7),
                skinColor: const Color(0xFFF5CBA7),
                isLeft: true,
              ),
            ),

            // Center person (man with money)
            Positioned(
              bottom: height * 0.18,
              child: _PersonWidget(
                height: height * 0.58,
                bodyColor: const Color(0xFF2D8A7E),
                skinColor: const Color(0xFFEDBDA1),
                isCenter: true,
              ),
            ),

            // Right person (man)
            Positioned(
              bottom: height * 0.15,
              right: width * 0.08,
              child: _PersonWidget(
                height: height * 0.5,
                bodyColor: const Color(0xFF4ECDC4),
                skinColor: const Color(0xFFF0C998),
                isRight: true,
              ),
            ),

            // Floating checkmark icon (top center)
            Positioned(
              top: height * 0.08,
              child: _FloatingIcon(
                icon: Icons.check_rounded,
                color: const Color(0xFF4CAF50),
                backgroundColor: const Color(0xFFE8F5E9),
                size: 36,
              ),
            ),

            // Floating document icon (top right)
            Positioned(
              top: height * 0.15,
              right: width * 0.1,
              child: _FloatingIcon(
                icon: Icons.description_outlined,
                color: const Color(0xFF6C5CE7),
                backgroundColor: const Color(0xFFEDE7F6),
                size: 30,
              ),
            ),

            // Floating checklist icon (right)
            Positioned(
              top: height * 0.22,
              right: width * 0.04,
              child: _FloatingIcon(
                icon: Icons.checklist_rounded,
                color: const Color(0xFF4ECDC4),
                backgroundColor: const Color(0xFFE0F7FA),
                size: 26,
              ),
            ),

            // Floating coin (top left)
            Positioned(
              top: height * 0.18,
              left: width * 0.06,
              child: _CoinWidget(size: 22),
            ),

            // Floating coin (top right area)
            Positioned(
              top: height * 0.32,
              right: width * 0.02,
              child: _CoinWidget(size: 18),
            ),

            // Floating coin (bottom left)
            Positioned(
              bottom: height * 0.3,
              left: width * 0.02,
              child: _CoinWidget(size: 16),
            ),
          ],
        );
      },
    );
  }
}

class _PersonWidget extends StatelessWidget {
  const _PersonWidget({
    required this.height,
    required this.bodyColor,
    required this.skinColor,
    this.isLeft = false,
    this.isCenter = false,
    this.isRight = false,
  });

  final double height;
  final Color bodyColor;
  final Color skinColor;
  final bool isLeft;
  final bool isCenter;
  final bool isRight;

  @override
  Widget build(BuildContext context) {
    final headSize = height * 0.18;
    final bodyWidth = height * 0.32;

    return SizedBox(
      height: height,
      width: bodyWidth + 10,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Head
          Positioned(
            top: 0,
            child: Container(
              width: headSize,
              height: headSize,
              decoration: BoxDecoration(
                color: skinColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Hair
          Positioned(
            top: 0,
            child: Container(
              width: headSize,
              height: headSize * 0.5,
              decoration: BoxDecoration(
                color: isLeft
                    ? const Color(0xFF2D3142)
                    : isCenter
                        ? const Color(0xFF3D3D3D)
                        : const Color(0xFF2D3142),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(headSize * 0.5),
                  topRight: Radius.circular(headSize * 0.5),
                ),
              ),
            ),
          ),

          // Body
          Positioned(
            top: headSize * 0.85,
            child: Container(
              width: bodyWidth,
              height: height * 0.55,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(bodyWidth * 0.4),
                  topRight: Radius.circular(bodyWidth * 0.4),
                  bottomLeft: Radius.circular(bodyWidth * 0.15),
                  bottomRight: Radius.circular(bodyWidth * 0.15),
                ),
              ),
            ),
          ),

          // Arms area with holding item
          if (isCenter)
            Positioned(
              top: headSize + height * 0.2,
              child: Container(
                width: 20,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Center(
                  child: Text(
                    '\$',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 12,
      height: size + 12,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.6),
    );
  }
}

class _CoinWidget extends StatelessWidget {
  const _CoinWidget({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD93D),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFF4C430),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD93D).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '\$',
          style: TextStyle(
            color: const Color(0xFFB8860B),
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
