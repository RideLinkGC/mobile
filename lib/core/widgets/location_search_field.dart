import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/gebeta_maps_service.dart';
import '../services/place_search_storage.dart';

class LocationSearchField extends StatefulWidget {
  final String hintText;
  final IconData prefixIcon;
  final ValueChanged<GeocodingResult> onPlaceSelected;
  final String? initialValue;
  final TextEditingController? controller;

  const LocationSearchField({
    super.key,
    this.hintText = 'Search location...',
    this.prefixIcon = Icons.location_on_outlined,
    required this.onPlaceSelected,
    this.initialValue,
    this.controller,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  late final TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<GeocodingResult> _results = [];
  bool _isLoading = false;
  Timer? _debounce;
  /// Last debounced query string (for history, distinct from selected place name).
  String _lastDebouncedQuery = '';
  List<String> _recentQueries = [];
  bool _loadedRecents = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedRecents) {
      _loadedRecents = true;
      _loadRecentQueries();
    }
  }

  Future<void> _loadRecentQueries() async {
    final storage = context.read<PlaceSearchStorage>();
    final q = await storage.getRecentQueries();
    if (mounted) setState(() => _recentQueries = q);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    if (value.trim().length < 2) {
      _removeOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(value);
    });
  }

  Future<void> _search(String query) async {
    _lastDebouncedQuery = query;
    setState(() => _isLoading = true);

    final storage = context.read<PlaceSearchStorage>();
    final mapsService = context.read<GebetaMapsService>();

    final cached = await storage.getGeocodeCache(query);
    final List<GeocodingResult> results;
    if (cached != null && cached.isNotEmpty) {
      results = cached;
    } else {
      results = await mapsService.searchPlace(query);
      if (results.isNotEmpty) {
        await storage.putGeocodeCache(query, results);
      }
    }

    if (!mounted) return;

    setState(() {
      _results = results;
      _isLoading = false;
    });

    if (results.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      result.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    subtitle: (result.city != null && result.city!.isNotEmpty) ||
                            (result.type != null && result.type!.isNotEmpty)
                        ? Text(
                            [
                              if (result.city != null &&
                                  result.city!.isNotEmpty)
                                result.city,
                              if (result.type != null &&
                                  result.type!.isNotEmpty)
                                result.type,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : null,
                    onTap: () async {
                      final storage = context.read<PlaceSearchStorage>();
                      if (_lastDebouncedQuery.trim().length >= 2) {
                        await storage.addRecentQuery(_lastDebouncedQuery.trim());
                        await _loadRecentQueries();
                      }
                      _controller.text = result.shortLabel;
                      widget.onPlaceSelected(result);
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getFieldWidth() {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
        controller: _controller,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: Icon(widget.prefixIcon),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                        _removeOverlay();
                      },
                    )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
          if (_controller.text.trim().length < 2 && _recentQueries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _recentQueries.take(6).map((q) {
                  return ActionChip(
                    backgroundColor: Colors.transparent,
                    
                    label: Text(
                      q,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:  TextStyle(fontSize: 13,
                       color:Colors.grey
                       ),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed: () {
                      _controller.text = q;
                      _onChanged(q);
                    },
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
