import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/gebeta_maps_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/location_search_field.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  GeocodingResult? _originResult;
  GeocodingResult? _destinationResult;
  List<String> _recentSearches = [];

  static const _recentSearchesKey = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];
    if (mounted) setState(() => _recentSearches = searches);
  }

  Future<void> _saveSearch(String search) async {
    _recentSearches.remove(search);
    _recentSearches.insert(0, search);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  void _onSearch() {
    if (_originResult == null || _destinationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both origin and destination')),
      );
      return;
    }
    final searchLabel =
        '${_originResult!.name} → ${_destinationResult!.name}';
    _saveSearch(searchLabel);

    context.push('/search-results', extra: {
      'origin': _originResult!.name,
      'destination': _destinationResult!.name,
      'originLat': _originResult!.lat,
      'originLng': _originResult!.lng,
      'destLat': _destinationResult!.lat,
      'destLng': _destinationResult!.lng,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.search),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocationSearchField(
              hintText: l10n.origin,
              prefixIcon: Icons.trip_origin,
              onPlaceSelected: (result) {
                setState(() => _originResult = result);
              },
            ),
            const SizedBox(height: 16),
            LocationSearchField(
              hintText: l10n.destination,
              prefixIcon: Icons.location_on,
              onPlaceSelected: (result) {
                setState(() => _destinationResult = result);
              },
            ),
            const SizedBox(height: 24),
            AppButton(
              text: l10n.search,
              onPressed: _onSearch,
            ),
            if (_recentSearches.isNotEmpty) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove(_recentSearchesKey);
                      setState(() => _recentSearches = []);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._recentSearches.map(
                (search) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      final parts = search.split(' → ');
                      if (parts.length == 2) {
                        context.push('/search-results', extra: {
                          'origin': parts[0],
                          'destination': parts[1],
                          'originLat': 0.0,
                          'originLng': 0.0,
                          'destLat': 0.0,
                          'destLng': 0.0,
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightDivider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 20,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              search,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Icon(
                            Icons.north_west,
                            size: 16,
                            color: AppColors.textHintLight,
                          ),
                        ],
                      ),
                    ),
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
