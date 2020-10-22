import 'package:json_annotation/json_annotation.dart';

part 'risk.g.dart';

@JsonSerializable()
class RiskObject {
  DateTime date;
  double value;

  RiskObject(this.date, this.value);

  factory RiskObject.fromJson(Map<String, dynamic> json) => _$RiskObjectFromJson(json);

  Map<String, dynamic> toJson() => _$RiskObjectToJson(this);
}