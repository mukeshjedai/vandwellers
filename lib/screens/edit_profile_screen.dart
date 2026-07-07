import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/van_dwellers_api.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final UserProfile user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _vanTypeController;
  late final TextEditingController _homeBaseController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.user.displayName);
    _bioController = TextEditingController(text: widget.user.bio);
    _vanTypeController = TextEditingController(text: widget.user.vanType);
    _homeBaseController = TextEditingController(text: widget.user.homeBase);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _vanTypeController.dispose();
    _homeBaseController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await VanDwellersApi.instance.updateProfile(
        displayName: _displayNameController.text,
        bio: _bioController.text,
        vanType: _vanTypeController.text,
        homeBase: _homeBaseController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vanTypeController,
              decoration: const InputDecoration(labelText: 'Van type'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _homeBaseController,
              decoration: const InputDecoration(labelText: 'Home base'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
