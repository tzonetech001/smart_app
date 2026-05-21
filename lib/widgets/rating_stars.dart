import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final Function(double)? onRatingChanged;
  final bool allowHalfRating;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.allowHalfRating = true,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: onRatingChanged != null
              ? () => onRatingChanged!((index + 1).toDouble())
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              _getStarIcon(index + 1),
              size: size,
              color: Colors.amber,
            ),
          ),
        );
      }),
    );
  }

  IconData _getStarIcon(int starIndex) {
    if (rating >= starIndex) {
      return Icons.star;
    } else if (allowHalfRating && rating >= starIndex - 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }
}