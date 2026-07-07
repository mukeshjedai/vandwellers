import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/campsite.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/media_service.dart';
import '../services/van_dwellers_api.dart';
import '../widgets/campsites_map.dart';
import '../widgets/van_dwellers_logo.dart';
import 'campsite_detail_screen.dart';
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
      AddTab(onDone: () {
        _goToTab(0);
        _loadUser();
      }),
      OthersTab(
        user: _user,
        onOpenInbox: () => _goToTab(1),
        onOpenProfile: () => _goToTab(4),
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
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Others',
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
  List<Campsite> _campsites = [];
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
        VanDwellersApi.instance.getCampsites(),
        VanDwellersApi.instance.getCamperUpdates(),
      ]);
      if (mounted) {
        setState(() {
          _campsites = results[0] as List<Campsite>;
          _updates = results[1] as List<CamperUpdate>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCampsite(Campsite campsite) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CampsiteDetailScreen(campsiteId: campsite.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user?.displayName ?? 'Traveler';

    return Scaffold(
      appBar: AppBar(title: const Text('Van Dwellers')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  Text(
                    'Welcome back, $name',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Find campsites and see what other campers are up to.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (_campsites.isNotEmpty)
                    CampsitesMap(
                      campsites: _campsites,
                      onCampsiteTap: _openCampsite,
                    ),
                  const SizedBox(height: 24),
                  Text('Campsites', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (_campsites.isEmpty)
                    const _EmptySection(message: 'No campsites listed yet.')
                  else
                    ..._campsites.map(
                      (site) => _CampsiteCard(
                        campsite: site,
                        onTap: () => _openCampsite(site),
                      ),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    'Recent from campers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_updates.isEmpty)
                    const _EmptySection(message: 'No updates from other campers yet.')
                  else
                    ..._updates.map((update) => _CamperUpdateCard(update: update)),
                ],
              ),
      ),
    );
  }
}

class OthersTab extends StatefulWidget {
  const OthersTab({
    super.key,
    required this.user,
    required this.onOpenInbox,
    required this.onOpenProfile,
  });

  final UserProfile? user;
  final VoidCallback onOpenInbox;
  final VoidCallback onOpenProfile;

  @override
  State<OthersTab> createState() => _OthersTabState();
}

class _OthersTabState extends State<OthersTab> {
  List<UserProfile> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await VanDwellersApi.instance.discoverUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user?.displayName ?? 'Traveler';

    return Scaffold(
      appBar: AppBar(title: const Text('Others')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Center(child: VanDwellersLogo(size: 80)),
            const SizedBox(height: 16),
            Text(
              'Welcome, $name',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
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
            const SizedBox(height: 28),
            Text('Van dwellers', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_loading)
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
  const _CampsiteCard({required this.campsite, required this.onTap});

  final Campsite campsite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
                          campsite.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          campsite.region,
                          style: const TextStyle(color: Colors.white70),
                        ),
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
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                campsite.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (campsite.amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: campsite.amenities
                      .take(3)
                      .map(
                        (amenity) => Chip(
                          label: Text(amenity),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
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

class AddTab extends StatelessWidget {
  const AddTab({super.key, required this.onDone});

  final VoidCallback onDone;

  Future<void> _uploadPhoto(BuildContext context) async {
    final file = await MediaService.instance.pickPhoto(source: ImageSource.gallery);
    if (file == null) return;
    try {
      await VanDwellersApi.instance.uploadProfilePhoto(file);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded')),
        );
        onDone();
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share with the community',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _uploadPhoto(context),
              icon: const Icon(Icons.photo_library),
              label: const Text('Upload photo'),
            ),
          ],
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
