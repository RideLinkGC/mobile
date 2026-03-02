import 'package:flutter/material.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
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

  final List<String> _recentSearches = [
    'Bole → Megenagna',
    'Kazanchis → CMC',
    'Piassa → Bole',
    'CMC → Kazanchis',
  ];

  void _onSearch() {
    if (_originResult == null || _destinationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both origin and destination')),
      );
      return;
    }
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
            const SizedBox(height: 32),
            Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._recentSearches.map(
              (search) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {},
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
                      ],
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
