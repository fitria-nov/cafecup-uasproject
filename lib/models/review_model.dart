import 'package:pocketbase/pocketbase.dart';

class Review {
  final String id;
  final String name;
  final int rating;
  final String comment;
  final String time;
  final String cafeId;

  Review({
    required this.id,
    required this.name,
    required this.rating,
    required this.comment,
    required this.time,
    required this.cafeId,
  });

  factory Review.fromRecord(RecordModel record) {
    return Review(
      id: record.id,
      name: record.data['name'] as String,
      rating: record.data['rating'] as int,
      comment: record.data['comment'] as String,
      time: record.data['time'] as String,
      cafeId: record.data['cafe'] as String,
    );
  }
}