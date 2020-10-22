import 'package:json_annotation/json_annotation.dart';

part 'esg.g.dart';

@JsonSerializable()
class EsgObject {
  DateTime date;
  double value;

  EsgObject(this.date, this.value);

  factory EsgObject.fromJson(Map<String, dynamic> json) => _$EsgObjectFromJson(json);

  Map<String, dynamic> toJson() => _$EsgObjectToJson(this);
}