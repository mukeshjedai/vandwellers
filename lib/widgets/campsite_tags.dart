import 'package:flutter/material.dart';

import '../models/campsite.dart';

List<String> collectCampsiteTags(List<Campsite> campsites) {
  final tags = <String>{};
  for (final site in campsites) {
    tags.addAll(campsiteTags(site));
  }
  return tags.toList()..sort();
}

List<String> campsiteTags(Campsite campsite) {
  final tags = <String>[];
  if (campsite.hasToilet) tags.add('Toilet');
  if (campsite.hasTap) tags.add('Tap');
  tags.addAll(campsite.amenities);
  if (campsite.region.isNotEmpty) tags.add(campsite.region);
  return tags;
}

bool campsiteMatchesTag(Campsite campsite, String tag) {
  if (tag == 'Toilet') return campsite.hasToilet;
  if (tag == 'Tap') return campsite.hasTap;
  return campsite.amenities.contains(tag) || campsite.region == tag;
}

class CampsiteTagWrap extends StatelessWidget {
  const CampsiteTagWrap({
    super.key,
    required this.campsite,
    this.compact = false,
    this.highlightAvailable = true,
  });

  final Campsite campsite;
  final bool compact;
  final bool highlightAvailable;

  @override
  Widget build(BuildContext context) {
    final tags = campsiteTags(campsite);
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: compact ? 4 : 8,
      runSpacing: compact ? 4 : 8,
      children: tags
          .map(
            (tag) => _TagChip(
              label: tag,
              compact: compact,
              highlighted: highlightAvailable &&
                  (tag == 'Toilet' || tag == 'Tap'),
            ),
          )
          .toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.compact,
    required this.highlighted,
  });

  final String label;
  final bool compact;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? Colors.green.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted ? Colors.greenAccent : Colors.white24,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? Colors.greenAccent : Colors.white70,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
