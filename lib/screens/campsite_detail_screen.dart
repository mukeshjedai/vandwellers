import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/campsite.dart';
import '../services/media_service.dart';
import '../services/van_dwellers_api.dart';

class CampsiteDetailScreen extends StatefulWidget {
  const CampsiteDetailScreen({super.key, required this.campsiteId});

  final String campsiteId;

  @override
  State<CampsiteDetailScreen> createState() => _CampsiteDetailScreenState();
}

class _CampsiteDetailScreenState extends State<CampsiteDetailScreen> {
  Campsite? _campsite;
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final campsite = await VanDwellersApi.instance.getCampsite(widget.campsiteId);
      if (mounted) setState(() {
        _campsite = campsite;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final file = await MediaService.instance.pickPhoto(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final updated = await VanDwellersApi.instance.uploadCampsitePhoto(
        campsiteId: widget.campsiteId,
        file: file,
      );
      if (mounted) {
        setState(() {
          _campsite = updated;
          _uploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final campsite = _campsite;

    return Scaffold(
      appBar: AppBar(
        title: Text(campsite?.name ?? 'Campsite'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : campsite == null
              ? const Center(child: Text('Campsite not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.terrain,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  campsite.name,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  campsite.region,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(campsite.rating.toStringAsFixed(1)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(campsite.description),
                      if (campsite.amenities.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Amenities',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: campsite.amenities
                              .map(
                                (amenity) => Chip(
                                  label: Text(amenity),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Text(
                            'Photos',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _uploading ? null : _uploadPhoto,
                            icon: _uploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add_photo_alternate_outlined),
                            label: Text(_uploading ? 'Uploading...' : 'Upload'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (campsite.photoUrls.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No photos yet. Be the first to share this campsite.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      else
                        ...campsite.photoUrls.map(
                          (url) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                url,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 180,
                                  color: Colors.white12,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
