import 'package:equatable/equatable.dart';

/// A monthly spending limit for a single expense category.
///
/// [categoryUuid] links the budget to its `CounterCategory`; the limit resets
/// implicitly every calendar month (spending is recomputed from the current
/// month's transactions, so no per-period record is stored).
class CategoryBudget extends Equatable {
  const CategoryBudget({
    required this.categoryUuid,
    required this.limit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      categoryUuid: map['categoryUuid'] as String,
      limit: (map['limit'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  final String categoryUuid;
  final double limit;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [categoryUuid, limit, updatedAt];

  CategoryBudget copyWith({
    String? categoryUuid,
    double? limit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryBudget(
      categoryUuid: categoryUuid ?? this.categoryUuid,
      limit: limit ?? this.limit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryUuid': categoryUuid,
      'limit': limit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
