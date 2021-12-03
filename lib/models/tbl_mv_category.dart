import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

class TblMvCategory extends Equatable {
  final int id;
  final String name;
  final Uint8List image;
  final String desc;
  final int type;
  TblMvCategory({
    required this.id,
    required this.name,
    required this.image,
    required this.desc,
    required this.type,
  });

  @override
  List<Object> get props => [id, name, image, desc, type];

  TblMvCategory copyWith({
    int? id,
    String? name,
    Uint8List? image,
    String? desc,
    int? type,
  }) {
    return TblMvCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      desc: desc ?? this.desc,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': base64Encode(image),
      'desc': desc,
      'type': type
    };
  }

  factory TblMvCategory.fromMap(Map<String, dynamic> map) {
    return TblMvCategory(
      id: map['id'],
      name: map['name'],
      image: base64Decode(map['image']),
      desc: map['desc'],
      type: map['type'],
    );
  }

  static Future<TblMvCategory> initMap(Map<String, dynamic> map) async {
    ByteData bytes = await rootBundle.load(map['image']);
    Uint8List image = bytes.buffer.asUint8List();
    return TblMvCategory(
      id: map['id'],
      name: map['name'],
      image: image,
      desc: map['desc'],
      type: map['type'],
    );
  }

  String toJson() => json.encode(toMap());

  factory TblMvCategory.fromJson(String source) =>
      TblMvCategory.fromMap(json.decode(source));

  @override
  bool get stringify => true;
}

class TempCat {
  final String name;
  final double value;
  final int type;
  TempCat({required this.name, required this.type, required this.value});
}
