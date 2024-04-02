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
    this.colorCode,
    this.iconCode,
  });
  factory CounterCategory.fromMap(Map<String, dynamic> map) {
    return CounterCategory(
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      type: CategoryType.fromString(map['type'] as String),
      colorCode: map['colorCode'] as int,
      iconCode: map['iconCode'] as int,
    );
  }
  //</editor-fold>

  final String uuid;
  final String name;
  final CategoryType type;
  final int? colorCode;
  final int? iconCode;

  @override
  List<Object?> get props => [uuid];

  //<editor-fold desc="Data Methods">
  @override
  String toString() {
    return 'CounterCategory{ '
        'uuid: $uuid, '
        'name: $name, '
        'type: $type, '
        'colorCode: $colorCode, '
        'iconCode: $iconCode, '
        '}';
  }

  CounterCategory copyWith({
    String? uuid,
    String? name,
    CategoryType? type,
    int? colorCode,
    int? iconCode,
  }) {
    return CounterCategory(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      type: type ?? this.type,
      colorCode: colorCode ?? this.colorCode,
      iconCode: iconCode ?? this.iconCode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'name': name,
      'type': type.toString(),
      'colorCode': colorCode,
      'iconCode': iconCode,
    };
  }
  //</editor-fold>
}
