import 'dart:convert';

import 'package:equatable/equatable.dart';

class TblMvExpence extends Equatable {
  final int id;
  final int categoryId;
  final int accId;
  final double value;
  final String? desc;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  TblMvExpence({
    required this.id,
    required this.categoryId,
    required this.accId,
    required this.value,
    this.desc,
    this.createdDate,
    this.modifiedDate,
  });

  TblMvExpence copyWith({
    int? id,
    int? categoryId,
    int? accId,
    double? value,
    String? desc,
    DateTime? createdDate,
    DateTime? modifiedDate,
  }) {
    return TblMvExpence(
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

  factory TblMvExpence.fromMap(Map<String, dynamic> map) {
    return TblMvExpence(
      id: map['id'],
      categoryId: map['category'] ?? 0,
      accId: map['acc_id'] ?? 0,
      value: map['value'] ?? 0,
      desc: map['desc'],
      createdDate: DateTime.parse(map['created_date']),
      modifiedDate: DateTime.parse(map['modified_date']),
    );
  }

  String toJson() => json.encode(toMap());

  factory TblMvExpence.fromJson(String source) =>
      TblMvExpence.fromMap(json.decode(source));

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
