import 'package:equatable/equatable.dart';

enum CategoryType {
  income,
  expense;

  static CategoryType fromString(String value) {
    if (value == 'income') {
      return income;
    } else {
      return expense;
    }
  }
}

class CounterCategory extends Equatable {
  //<editor-fold desc="Data Methods">
  const CounterCategory({
    required this.uuid,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.colorCode,
    this.iconCode,
  });
  factory CounterCategory.fromMap(Map<String, dynamic> map) {
    return CounterCategory(
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      type: CategoryType.fromString(map['type'] as String),
      colorCode: map['colorCode'] as int?,
      iconCode: map['iconCode'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  factory CounterCategory.fromList(List<String> data) {
    return CounterCategory(
      uuid: data[0],
      name: data[1].replaceAll(';', ''),
      type: CategoryType.fromString(data[2]),
      iconCode: int.tryParse(data[3]),
      colorCode: int.tryParse(data[4]),
      updatedAt: DateTime.parse(data[5]),
      createdAt: DateTime.parse(data[6]),
    );
  }
  //</editor-fold>

  final String uuid;
  final String name;
  final CategoryType type;
  final int? colorCode;
  final int? iconCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [uuid, updatedAt];

  //<editor-fold desc="Data Methods">
  @override
  String toString() {
    return 'CounterCategory( '
        "uuid: '$uuid', "
        "name: '$name', "
        'type: $type, '
        'colorCode: $colorCode, '
        'iconCode: $iconCode, '
        "createdAt: DateTime.parse('$createdAt'), "
        "updatedAt: DateTime.parse('$updatedAt'), "
        ')';
  }

  CounterCategory copyWith({
    String? uuid,
    String? name,
    CategoryType? type,
    int? colorCode,
    int? iconCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CounterCategory(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      type: type ?? this.type,
      colorCode: colorCode ?? this.colorCode,
      iconCode: iconCode ?? this.iconCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<String> toListString() {
    return [
      uuid,
      name.replaceAll(',', ';'),
      type.name,
      iconCode?.toString() ?? '',
      colorCode?.toString() ?? '',
      updatedAt.toString(),
      createdAt.toString(),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'type': type.name,
      'colorCode': colorCode,
      'iconCode': iconCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  //</editor-fold>
}
