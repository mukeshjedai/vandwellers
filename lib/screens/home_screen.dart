import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/campsite.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/media_service.dart';
import '../services/google_places_service.dart';
import '../services/location_service.dart';
import '../services/van_dwellers_api.dart';
import '../widgets/campsite_map.dart';
import '../widgets/campsite_tags.dart';
import '../widgets/google_address_field.dart';
import '../widgets/van_dwellers_logo.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  UserProfile? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await VanDwellersApi.instance.getMe();
      if (mounted) setState(() => _user = user);
    } catch (_) {}
  }

  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(user: _user),
      const InboxTab(),
      FeedTab(
        user: _user,
        onOpenInbox: () => _goToTab(1),
        onOpenProfile: () => _goToTab(3),
      ),
      ProfileScreen(onUpdated: _loadUser),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _goToTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.white54,
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            activeIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed_outlined),
            activeIcon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.user});

  final UserProfile? user;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  GoogleMapController? _mapController;
  List<Campsite> _campsites = [];
  bool _loading = true;
  bool _pickLocationMode = false;
  String? _selectedTag;
  String? _selectedCampsiteId;
  LatLng? _currentLocation;
  final _pendingLocation = ValueNotifier<LatLng?>(null);

  @override
  void dispose() {
    _pendingLocation.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final location = await LocationService.instance.getCurrentLocation();
    if (mounted && location != null) {
      setState(() => _currentLocation = location);
    }
  }

  List<Campsite> get _filteredCampsites {
    if (_selectedTag == null) return _campsites;
    return _campsites
        .where((site) => campsiteMatchesTag(site, _selectedTag!))
        .toList();
  }

  List<String> get _allTags => collectCampsiteTags(_campsites);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final campsites = await VanDwellersApi.instance.getCampsites();
      if (mounted) {
        setState(() {
          _campsites = campsites;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onMapTap(LatLng point) {
    if (_pickLocationMode) {
      _pendingLocation.value = point;
    }
  }

  void _focusCampsite(Campsite site) {
    if (site.latitude == 0 && site.longitude == 0) return;
    setState(() => _selectedCampsiteId = site.id);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(site.latitude, site.longitude),
        14,
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    final location =
        _currentLocation ?? await LocationService.instance.getCurrentLocation();
    if (location == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location unavailable')),
        );
      }
      return;
    }
    setState(() => _currentLocation = location);
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 13),
    );
  }

  void _onAddressSelectedFromSheet(ValidatedAddress address) {
    final point = LatLng(address.latitude, address.longitude);
    _pendingLocation.value = point;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 14));
  }

  Future<void> _openAddLocationSheet() async {
    setState(() => _pickLocationMode = true);
    _pendingLocation.value ??= const LatLng(-25.27, 133.77);

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _AddLocationSheet(
        pendingLocation: _pendingLocation,
        onAddressSelected: _onAddressSelectedFromSheet,
        onSaved: () async {
          setState(() => _pickLocationMode = false);
          _pendingLocation.value = null;
          await _load();
        },
      ),
    );

    if (mounted) {
      setState(() => _pickLocationMode = false);
      _pendingLocation.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCampsites;
    final allTags = _allTags;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<LatLng?>(
              valueListenable: _pendingLocation,
              builder: (context, pending, _) {
                return CampsiteMap(
                  onMapCreated: (controller) => _mapController = controller,
                  campsites: filtered,
                  pickMode: _pickLocationMode,
                  pendingLocation: pending,
                  currentLocation: _currentLocation,
                  selectedCampsiteId: _selectedCampsiteId,
                  onTap: _onMapTap,
                  onCampsiteTap: _focusCampsite,
                  fullScreen: true,
                  zoomOnTap: !_pickLocationMode,
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Van Dwellers',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.55),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _goToMyLocation,
                    icon: const Icon(Icons.my_location),
                    tooltip: 'My location',
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _openAddLocationSheet,
                    icon: const Icon(Icons.add_location_alt, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.24,
            minChildSize: 0.18,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.24, 0.55, 0.92],
            builder: (context, scrollController) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            'Campsites',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${filtered.length}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          const Spacer(),
                          if (_loading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                    if (allTags.isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('All'),
                                selected: _selectedTag == null,
                                onSelected: (_) =>
                                    setState(() => _selectedTag = null),
                              ),
                            ),
                            for (final tag in allTags)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(tag),
                                  selected: _selectedTag == tag,
                                  onSelected: (selected) => setState(
                                    () => _selectedTag = selected ? tag : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _loading && _campsites.isEmpty
                            ? ListView(
                                controller: scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 48),
                                  Center(child: CircularProgressIndicator()),
                                ],
                              )
                            : ListView(
                                controller: scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                                children: [
                                  if (filtered.isEmpty)
                                    const _EmptySection(
                                      message:
                                          'No campsites match these tags yet.',
                                    )
                                  else
                                    ...filtered.map(
                                      (site) => _CampsiteCard(
                                        campsite: site,
                                        onTap: () => _focusCampsite(site),
                                        selected: _selectedCampsiteId == site.id,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddLocationSheet extends StatefulWidget {
  const _AddLocationSheet({
    required this.pendingLocation,
    required this.onAddressSelected,
    required this.onSaved,
  });

  final ValueNotifier<LatLng?> pendingLocation;
  final ValueChanged<ValidatedAddress> onAddressSelected;
  final Future<void> Function() onSaved;

  @override
  State<_AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<_AddLocationSheet> {
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _photos = <File>[];
  bool _hasToilet = false;
  bool _hasTap = false;
  bool _saving = false;
  bool _addressValidated = false;
  bool _reverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    widget.pendingLocation.addListener(_onPinMoved);
  }

  @override
  void dispose() {
    widget.pendingLocation.removeListener(_onPinMoved);
    _titleController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onPinMoved() async {
    if (_reverseGeocoding || _saving) return;
    final location = widget.pendingLocation.value;
    if (location == null) return;

    _reverseGeocoding = true;
    final validated = await GooglePlacesService.instance.reverseGeocode(
      location.latitude,
      location.longitude,
    );
    _reverseGeocoding = false;

    if (!mounted || validated == null) return;
    setState(() {
      _addressController.text = validated.formattedAddress;
      _addressValidated = true;
    });
  }

  Future<void> _pickPhotos() async {
    final picked = await MediaService.instance.pickPhotos();
    if (picked.isEmpty || !mounted) return;
    setState(() => _photos.addAll(picked));
  }

  Future<void> _save() async {
    var location = widget.pendingLocation.value;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a location on the map or enter an address.')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }

    setState(() => _saving = true);

    var address = _addressController.text.trim();
    if (address.isNotEmpty && !_addressValidated) {
      final validated = await GooglePlacesService.instance.geocodeAddress(address);
      if (validated == null) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address not found. Pick a Google Maps suggestion.'),
            ),
          );
        }
        return;
      }
      address = validated.formattedAddress;
      location = LatLng(validated.latitude, validated.longitude);
      widget.pendingLocation.value = location;
      _addressController.text = address;
      _addressValidated = true;
    }

    try {
      await VanDwellersApi.instance.createCampsite(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        address: address,
        latitude: location.latitude,
        longitude: location.longitude,
        hasToilet: _hasToilet,
        hasTap: _hasTap,
        photos: _photos,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campsite added')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return ValueListenableBuilder<LatLng?>(
      valueListenable: widget.pendingLocation,
      builder: (context, location, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add campsite', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Search an address or tap the map to place a pin.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                GoogleAddressField(
                  controller: _addressController,
                  enabled: !_saving,
                  onChanged: () => setState(() => _addressValidated = false),
                  onAddressSelected: (address) {
                    setState(() => _addressValidated = true);
                    widget.onAddressSelected(address);
                  },
                ),
                if (_addressValidated && _addressController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Address verified with Google Maps',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Toilet available'),
                  value: _hasToilet,
                  onChanged: _saving ? null : (v) => setState(() => _hasToilet = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tap water available'),
                  value: _hasTap,
                  onChanged: _saving ? null : (v) => setState(() => _hasTap = v),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickPhotos,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Add photos'),
                ),
                if (_photos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _photos[index],
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: _saving
                                    ? null
                                    : () => setState(() => _photos.removeAt(index)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                if (location != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Pin: ${location.latitude.toStringAsFixed(4)}, '
                    '${location.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving || location == null ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save campsite'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FeedTab extends StatefulWidget {
  const FeedTab({
    super.key,
    required this.user,
    required this.onOpenInbox,
    required this.onOpenProfile,
  });

  final UserProfile? user;
  final VoidCallback onOpenInbox;
  final VoidCallback onOpenProfile;

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  List<UserProfile> _users = [];
  List<CamperUpdate> _updates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        VanDwellersApi.instance.discoverUsers(),
        VanDwellersApi.instance.getCamperUpdates(),
      ]);
      if (mounted) {
        setState(() {
          _users = results[0] as List<UserProfile>;
          _updates = results[1] as List<CamperUpdate>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final file = await MediaService.instance.pickPhoto(source: ImageSource.gallery);
    if (file == null) return;
    try {
      await VanDwellersApi.instance.uploadProfilePhoto(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user?.displayName ?? 'Traveler';

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              'Recent from campers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_loading && _updates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_updates.isEmpty)
              const _EmptySection(
                message: 'No updates from other campers yet.',
              )
            else
              ..._updates.map((update) => _CamperUpdateCard(update: update)),
            const SizedBox(height: 28),
            Text(
              'Welcome, $name',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Center(child: VanDwellersLogo(size: 72)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _QuickLinkCard(
                    icon: Icons.inbox,
                    label: 'Inbox',
                    onTap: widget.onOpenInbox,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickLinkCard(
                    icon: Icons.person,
                    label: 'Profile',
                    onTap: widget.onOpenProfile,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _QuickLinkCard(
              icon: Icons.photo_library,
              label: 'Share a photo',
              onTap: _uploadPhoto,
            ),
            const SizedBox(height: 28),
            Text('Van dwellers', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_loading && _users.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_users.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No other users yet.')),
              )
            else
              ..._users.map((user) => _UserCard(user: user)),
          ],
        ),
      ),
    );
  }
}

class _CampsiteCard extends StatelessWidget {
  const _CampsiteCard({
    required this.campsite,
    this.onTap,
    this.selected = false,
  });

  final Campsite campsite;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.terrain,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campsite.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (campsite.region.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  campsite.region,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        CampsiteTagWrap(campsite: campsite),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(campsite.rating.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(campsite.description),
              if (campsite.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: campsite.photoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          campsite.photoUrls[index],
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 96,
                            height: 96,
                            color: Colors.white12,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CamperUpdateCard extends StatelessWidget {
  const _CamperUpdateCard({required this.update});

  final CamperUpdate update;

  IconData get _icon => switch (update.updateType) {
        'photo' => Icons.photo_camera,
        'profile' => Icons.edit_note,
        'van' => Icons.directions_bus,
        _ => Icons.person_add,
      };

  String _timeAgo(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    update.displayName.isNotEmpty
                        ? update.displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        update.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '@${update.userName}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (update.timestamp != null)
                  Text(
                    _timeAgo(update.timestamp),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(update.text)),
              ],
            ),
            if (update.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  update.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: Colors.white12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(message, style: const TextStyle(color: Colors.white54)),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          child: Text(
            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}'),
            if (user.vanType.isNotEmpty)
              Text(user.vanType, style: const TextStyle(fontSize: 12)),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.chat),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChatScreen(otherUserId: user.id),
            ),
          ),
        ),
      ),
    );
  }
}

class InboxTab extends StatefulWidget {
  const InboxTab({super.key});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  List<ConversationPreview> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await VanDwellersApi.instance.getConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('Inbox is empty'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, i) {
                      final c = _conversations[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(c.otherUser[0])),
                        title: Text(c.otherUser),
                        subtitle: Text(c.lastMessage, maxLines: 1),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ChatScreen(otherUserId: c.otherUserId),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
