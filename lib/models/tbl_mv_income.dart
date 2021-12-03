import 'dart:convert';

import 'package:equatable/equatable.dart';

class TblMvIncome extends Equatable {
  final int id;
  final int categoryId;
  final int accId;
  final double value;
  final String? desc;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  TblMvIncome({
    required this.id,
    required this.categoryId,
    required this.accId,
    required this.value,
    this.desc,
    this.createdDate,
    this.modifiedDate,
  });

  TblMvIncome copyWith({
    int? id,
    int? categoryId,
    int? accId,
    double? value,
    String? desc,
    DateTime? createdDate,
    DateTime? modifiedDate,
  }) {
    return TblMvIncome(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      accId: accId ?? this.accId,
      value: value ?? this.value,
      desc: desc ?? this.desc,
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'acc_id': accId,
      'value': value,
      'desc': desc,
      'created_date': createdDate.toString(),
      'modified_date': modifiedDate.toString(),
    };
  }

  factory TblMvIncome.fromMap(Map<String, dynamic> map) {
    return TblMvIncome(
      id: map['id'] ?? 0,
      categoryId: map['category_id'] ?? 0,
      accId: map['acc_id'] ?? 0,
      value: map['value'] ?? 0,
      desc: map['desc'],
      createdDate: map['created_date'] != null
          ? DateTime.parse(map['created_date'])
          : DateTime.now(),
      modifiedDate: map['modified_date'] != null
          ? DateTime.parse(map['modified_date'])
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory TblMvIncome.fromJson(String source) =>
      TblMvIncome.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      id,
      categoryId,
      accId,
      value,
      desc ?? '',
      createdDate ?? DateTime.parse('1970-01-01 00:00:00'),
      modifiedDate ?? DateTime.parse('1970-01-01 00:00:00'),
    ];
  }
}
