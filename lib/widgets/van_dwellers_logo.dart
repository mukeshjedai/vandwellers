import 'package:flutter/material.dart';

class VanDwellersLogo extends StatelessWidget {
  const VanDwellersLogo({
    super.key,
    this.size = 96,
    this.showTitle = true,
  });

  final double size;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(size * 0.22),
              ),
              child: Icon(
                Icons.directions_bus_filled,
                size: size * 0.55,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 12),
          Text(
            'Van Dwellers',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
          Text(
            'Find your people on the road',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                ),
          ),
        ],
      ],
    );
  }
}
