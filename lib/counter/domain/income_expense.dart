import 'package:equatable/equatable.dart';
import 'package:wallet/counter/domain/counter_category.dart';

class IncomeExpense extends Equatable {
  //<editor-fold desc="Data Methods">
  const IncomeExpense({
    required this.uuid,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.description,
    this.category,
  });
  factory IncomeExpense.fromMap(Map<String, dynamic> map) {
    return IncomeExpense(
      uuid: map['uuid'] as String,
      amount: map['amount'] as double,
      title: map['title'] as String?,
      description: map['description'] as String?,
      category: map['category'] != null
          ? CounterCategory.fromMap(
              map['category'] as Map<String, dynamic>,
            )
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  factory IncomeExpense.fromList(List<String> data) {
    return IncomeExpense(
      uuid: data[0],
      amount: double.parse(data[1]),
      title: data[2].isNotEmpty ? data[2] : null,
      description: data[3].isNotEmpty ? data[3] : null,
      updatedAt: DateTime.parse(data[4]),
      createdAt: DateTime.parse(data[5]),
      category: data.length == 13
          ? CounterCategory.fromList(
              data.sublist(6),
            )
          : null,
    );
  }
  //</editor-fold>

  final String uuid;
  final double amount;
  final String? title;
  final String? description;
  final CounterCategory? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [uuid, updatedAt];

  //<editor-fold desc="Data Methods">
  @override
  String toString() {
    return 'IncomeExpense( '
        "uuid: '$uuid', "
        'amount: $amount, '
        "title: '$title', "
        "description: '$description', "
        'category: $category, '
        "createdAt: DateTime.parse('$createdAt'), "
        "updatedAt: DateTime.parse('$updatedAt'), "
        ')';
  }

  IncomeExpense copyWith({
    String? uuid,
    double? amount,
    String? title,
    String? description,
    CounterCategory? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeExpense(
      uuid: uuid ?? this.uuid,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<String> toListString() {
    return [
      uuid,
      amount.toString(),
      title ?? '',
      description ?? '',
      updatedAt.toString(),
      createdAt.toString(),
      if (category != null) ...category!.toListString(),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'amount': amount,
      'title': title,
      'description': description,
      'category': category?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  //</editor-fold>
}
