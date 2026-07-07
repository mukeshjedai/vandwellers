import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/media_service.dart';
import '../services/van_dwellers_api.dart';
import '../widgets/van_dwellers_logo.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onUpdated});

  final VoidCallback? onUpdated;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await VanDwellersApi.instance.getMe();
      if (mounted) setState(() { _user = user; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    final user = _user;
    if (user == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => EditProfileScreen(user: user)),
    );
    if (saved == true) {
      await _load();
      widget.onUpdated?.call();
    }
  }

  Future<void> _addPhoto() async {
    final file = await MediaService.instance.pickPhoto(source: ImageSource.gallery);
    if (file == null) return;
    try {
      await VanDwellersApi.instance.uploadProfilePhoto(file);
      await _load();
      widget.onUpdated?.call();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Could not load profile')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        actions: [
          IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit), tooltip: 'Edit'),
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout), tooltip: 'Sign out'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.displayName, style: Theme.of(context).textTheme.headlineSmall),
                  Text('@${user.username}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Edit profile'),
            ),
            const SizedBox(height: 24),
            _InfoTile(label: 'Bio', value: user.bio),
            _InfoTile(label: 'Van type', value: user.vanType),
            _InfoTile(label: 'Home base', value: user.homeBase),
            const SizedBox(height: 16),
            Text('Photos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...user.photoUrls.map(
                    (url) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Upload'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const VanDwellersLogo(size: 64, showTitle: false),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
