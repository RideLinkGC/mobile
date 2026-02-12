import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../theme/app_colors.dart';

class AppRatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final bool readOnly;
  final void Function(double)? onRatingUpdate;

  const AppRatingWidget({
    super.key,
    required this.rating,
    this.size = 20,
    this.readOnly = true,
    this.onRatingUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: size,
      ignoreGestures: readOnly,
      unratedColor: Colors.grey.shade300,
      itemBuilder: (context, _) => const Icon(
        Icons.star_rounded,
        color: AppColors.ratingStar,
      ),
      onRatingUpdate: onRatingUpdate ?? (_) {},
    );
  }
}
