import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class TblMvCategory extends Equatable {
  final int id;
  final String name;
  final Uint8List image;
  final String desc;
  TblMvCategory({
    required this.id,
    required this.name,
    required this.image,
    required this.desc,
  });

  @override
  List<Object> get props => [id, name, image, desc];

  TblMvCategory copyWith({
    int? id,
    String? name,
    Uint8List? image,
    String? desc,
  }) {
    return TblMvCategory(
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

  factory TblMvCategory.fromMap(Map<String, dynamic> map) {
    return TblMvCategory(
      id: map['id'],
      name: map['name'],
      image: base64Decode(map['image']),
      desc: map['desc'],
    );
  }

  String toJson() => json.encode(toMap());

  factory TblMvCategory.fromJson(String source) =>
      TblMvCategory.fromMap(json.decode(source));

  @override
  bool get stringify => true;
}
