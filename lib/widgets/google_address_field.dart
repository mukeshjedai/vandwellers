import 'dart:async';

import 'package:flutter/material.dart';

import '../services/google_places_service.dart';

class GoogleAddressField extends StatefulWidget {
  const GoogleAddressField({
    super.key,
    required this.controller,
    required this.onAddressSelected,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<ValidatedAddress> onAddressSelected;
  final VoidCallback? onChanged;
  final bool enabled;

  @override
  State<GoogleAddressField> createState() => _GoogleAddressFieldState();
}

class _GoogleAddressFieldState extends State<GoogleAddressField> {
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  bool _suppressSearch = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_suppressSearch) return;
    widget.onChanged?.call();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _fetchSuggestions);
  }

  Future<void> _fetchSuggestions() async {
    final query = widget.controller.text.trim();
    if (query.length < 3) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }

    setState(() => _loading = true);
    final results = await GooglePlacesService.instance.autocomplete(query);
    if (mounted) {
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    setState(() {
      _loading = true;
      _suggestions = [];
    });

    final validated =
        await GooglePlacesService.instance.placeDetails(suggestion.placeId);
    if (!mounted) return;

    setState(() => _loading = false);
    if (validated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not validate that address.')),
      );
      return;
    }

    _suppressSearch = true;
    widget.controller.text = validated.formattedAddress;
    _suppressSearch = false;
    widget.onAddressSelected(validated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: 'Address',
            hintText: 'Start typing to search Google Maps',
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(
                    item.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => _selectSuggestion(item),
                );
              },
            ),
          ),
      ],
    );
  }
}
