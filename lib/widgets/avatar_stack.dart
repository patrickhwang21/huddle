import 'package:flutter/material.dart';

/// Overlapping row of circular avatars with an optional "+N" overflow badge.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.imageUrls,
    this.extraCount = 0,
    this.size = 24,
  });

  final List<String> imageUrls;
  final int extraCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final url in imageUrls) {
      children.add(_avatar(child: ClipOval(child: Image.network(url, fit: BoxFit.cover))));
    }
    if (extraCount > 0) {
      children.add(_avatar(
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: Text(
            '+$extraCount',
            style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
          ),
        ),
      ));
    }

    return SizedBox(
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < children.length; i++)
            Positioned(
              left: i * (size * 0.72),
              child: children[i],
            ),
        ],
      ),
    );
  }

  Widget _avatar({required Widget child, Color? color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.grey.shade200,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: child,
    );
  }
}
