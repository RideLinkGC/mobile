import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../../../core/theme/app_shadows.dart';
import '../providers/search_provider.dart';

/// Bottom sheet styled like the "Filter Rides" mock: filters + sort (name, price, rating only).
class FilterRidesSheet extends StatefulWidget {
  const FilterRidesSheet({super.key});

  static Future<void> show(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(top: h * 0.05),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: Material(
              color:Theme.of(context).scaffoldBackgroundColor,
              child: SizedBox(
                height: h * 0.95,
                child: const FilterRidesSheet(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<FilterRidesSheet> createState() => _FilterRidesSheetState();
}

class _FilterRidesSheetState extends State<FilterRidesSheet> {
  late BrowseSortMode _sort;
  late bool _recommendedOnly;
  late BrowseServiceTier _tier;
  double? _minRating;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    final p = context.read<SearchProvider>();
    _sort = p.browseSortMode;
    _recommendedOnly = p.browseRecommendedOnly;
    _tier = p.browseServiceTier;
    _minRating = p.browseMinRating;
    _priceRange = RangeValues(
      p.browsePriceFilterMin,
      p.browsePriceFilterMax,
    );
  }

  void _localReset() {
    setState(() {
      _sort = BrowseSortMode.rating;
      _recommendedOnly = false;
      _tier = BrowseServiceTier.any;
      _minRating = null;
      _priceRange = RangeValues(
        SearchProvider.browsePriceSliderMin,
        SearchProvider.browsePriceSliderMax,
      );
    });
    context.read<SearchProvider>().resetBrowseFilters();
  }

  void _apply() {
    context.read<SearchProvider>().applyBrowseFilters(
          sort: _sort,
          recommendedOnly: _recommendedOnly,
          serviceTier: _tier,
          minRating: _minRating,
          priceMin: _priceRange.start,
          priceMax: _priceRange.end,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = scheme.surfaceDim.withAlpha(125);
    final onMuted = scheme.onSurfaceVariant;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color:onMuted.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Row(
            children: [
              TextButton(
                onPressed: _localReset,
                child: Text(
                  'Reset',
                  style: TextStyle(color: onMuted),
                ),
              ),
              Expanded(
                child: Text(
                  'Filter Rides',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Material(
                color: cardBg,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            children: [
              _sectionCard(
                context,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.auto_awesome_rounded,
                          color: scheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommended only',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Top-rated drivers & fast pickups',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: onMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      // change border of switch to primary color
                      trackOutlineColor: WidgetStateProperty.all(scheme.primary.withValues(alpha: 0.35)),
                      value: _recommendedOnly,
                      inactiveThumbColor: scheme.shadow.withValues(alpha: 0.35),
                      inactiveTrackColor: scheme.surface,
                      activeThumbColor: scheme.primary,
                      activeTrackColor: scheme.primary.withValues(alpha: 0.35),
                      onChanged: (v) => setState(() => _recommendedOnly = v),
                    ),
                  ],
                ),
              ),
              
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      setState(() => _tier = BrowseServiceTier.any),
                  child: Text(
                    _tier == BrowseServiceTier.any
                        ? 'All categories'
                        : 'Clear category filter',
                    style: TextStyle(
                      color: _tier == BrowseServiceTier.any
                          ? onMuted
                          : scheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _sectionLabel(context, 'SORT BY'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sortChip(context, BrowseSortMode.name, 'Name'),
                  _sortChip(context, BrowseSortMode.price, 'Price'),
                  _sortChip(context, BrowseSortMode.rating, l10n.rating),
                ],
              ),
              const SizedBox(height: 20),
              _sectionLabel(context, 'MINIMUM RATING'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ratingChip(context, null, 'Any'),
                  _ratingChip(context, 4.0, '4.0+'),
                  _ratingChip(context, 4.5, '4.5+'),
                  _ratingChip(context, 4.8, '4.8+'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _sectionLabel(context, 'PRICE RANGE')),
                  Text(
                    '${_priceRange.start.round()} — ${_priceRange.end.round()} ${l10n.etb}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RangeSlider(
                values: _priceRange,
                min: SearchProvider.browsePriceSliderMin,
                max: SearchProvider.browsePriceSliderMax,
                divisions: 19,
                activeColor: scheme.primary,
                inactiveColor: onMuted.withValues(alpha: 0.25),
                
                labels: RangeLabels(

                  '${_priceRange.start.round()}',
                  '${_priceRange.end.round()}+',
                ),
                onChanged: (v) => setState(() => _priceRange = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${SearchProvider.browsePriceSliderMin.round()} ${l10n.etb}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: onMuted,
                        ),
                  ),
                  Text(
                    '${SearchProvider.browsePriceSliderMax.round()}+ ${l10n.etb}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: onMuted,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.paddingOf(context).bottom + 30,
          ),
          child: FilledButton.icon(
            onPressed: _apply,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: isDark ? 0 : 2,
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: const Text(
              'Apply Filters',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceDim.withAlpha(125),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.softCard(context),
      ),
      child: child,
    );
  }

  Widget _sortChip(
      BuildContext context, BrowseSortMode mode, String label) {
    final selected = _sort == mode;
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _sort = mode),
      selectedColor: Colors.transparent,
      checkmarkColor: scheme.primary,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: selected ? scheme.primary : scheme.onSurface,
        fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
      ),
      side: BorderSide(
        color: selected ? scheme.primary : Colors.transparent,
        width: selected ? 1 : 0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _ratingChip(BuildContext context, double? value, String label) {
    final selected = _minRating == value;
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _minRating = value),
      selectedColor: Colors.transparent,
      checkmarkColor: scheme.primary,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(color: selected ? scheme.primary : scheme.onSurface, fontWeight: FontWeight.w400),
      side: BorderSide(color: selected ? scheme.primary : Colors.transparent, width: selected ? 1 : 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
