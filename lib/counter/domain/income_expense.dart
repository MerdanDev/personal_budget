import 'package:equatable/equatable.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/csv_codec.dart';

class IncomeExpense extends Equatable {
  //<editor-fold desc="Data Methods">
  const IncomeExpense({
    required this.uuid,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.category,
  });
  factory IncomeExpense.fromMap(Map<String, dynamic> map) {
    final category = map['category'] != null
        ? CounterCategory.fromMap(map['category'] as Map<String, dynamic>)
        : null;
    return IncomeExpense(
      uuid: map['uuid'] as String,
      amount: map['amount'] as double,
      // `title` was removed; fold any legacy value into the description so no
      // user-entered text is lost when older data is read.
      description: _foldTitle(
        map['title'] as String?,
        map['description'] as String?,
        category?.name,
      ),
      category: category,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  factory IncomeExpense.fromList(List<String> data) {
    final category =
        data.length == 13 ? CounterCategory.fromList(data.sublist(6)) : null;
    return IncomeExpense(
      uuid: data[0],
      amount: double.parse(data[1]),
      // index 2 is the legacy `title` column, kept for positional
      // compatibility; fold it into the description on import.
      description: _foldTitle(
        data[2].isNotEmpty ? csvDecodeField(data[2]) : null,
        data[3].isNotEmpty ? csvDecodeField(data[3]) : null,
        category?.name,
      ),
      updatedAt: DateTime.parse(data[4]),
      createdAt: DateTime.parse(data[5]),
      category: category,
    );
  }

  /// Merges a legacy [title] into [description]. Drops the title when it is
  /// empty or merely echoes the category name; otherwise prepends it so its
  /// content survives. Idempotent: re-reading already-migrated data is a no-op
  /// because the title source is always null by then.
  ///
  /// A space (not a newline) joins the two so the result stays on one line —
  /// important because CSV backups are parsed line by line.
  static String? _foldTitle(
    String? title,
    String? description,
    String? categoryName,
  ) {
    final t = title?.trim();
    if (t == null || t.isEmpty || t == categoryName) {
      return description;
    }
    if (description == null || description.isEmpty) {
      return t;
    }
    return '$t $description';
  }
  //</editor-fold>

  final String uuid;
  final double amount;
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
        "description: '$description', "
        'category: $category, '
        "createdAt: DateTime.parse('$createdAt'), "
        "updatedAt: DateTime.parse('$updatedAt'), "
        ')';
  }

  IncomeExpense copyWith({
    String? uuid,
    double? amount,
    String? description,
    CounterCategory? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeExpense(
      uuid: uuid ?? this.uuid,
      amount: amount ?? this.amount,
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
      // legacy `title` column kept empty for positional CSV compatibility
      '',
      if (description != null) csvEncodeField(description!) else '',
      updatedAt.toString(),
      createdAt.toString(),
      if (category != null) ...category!.toListString(),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'amount': amount,
      'description': description,
      'category': category?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  //</editor-fold>
}
