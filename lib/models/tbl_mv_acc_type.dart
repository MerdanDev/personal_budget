import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

class TblMvAccType extends Equatable {
  final int id;
  final String name;
  final Uint8List image;
  final String desc;
  TblMvAccType({
    required this.id,
    required this.name,
    required this.image,
    required this.desc,
  });

  @override
  List<Object> get props => [id, name, image, desc];

  TblMvAccType copyWith({
    int? id,
    String? name,
    Uint8List? image,
    String? desc,
  }) {
    return TblMvAccType(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      desc: desc ?? this.desc,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': base64Encode(image),
      'desc': desc,
    };
  }

  factory TblMvAccType.fromMap(Map<String, dynamic> map) {
    return TblMvAccType(
      id: map['id'],
      name: map['name'],
      image: base64Decode(map['image']),
      desc: map['desc'],
    );
  }

  static Future<TblMvAccType> initMap(Map<String, dynamic> map) async {
    ByteData bytes = await rootBundle.load(map['image']);
    Uint8List image = bytes.buffer.asUint8List();
    return TblMvAccType(
      id: map['id'],
      name: map['name'],
      image: image,
      desc: map['desc'],
    );
  }

  String toJson() => json.encode(toMap());

  factory TblMvAccType.fromJson(String source) =>
      TblMvAccType.fromMap(json.decode(source));

  @override
  bool get stringify => true;
}
