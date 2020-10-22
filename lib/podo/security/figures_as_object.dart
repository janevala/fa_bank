import 'package:fa_bank/podo/security/latest_values.dart';
import 'package:json_annotation/json_annotation.dart';

part 'figures_as_object.g.dart';

@JsonSerializable()
class FiguresAsObject {
  LatestValues latestValues;

  FiguresAsObject(this.latestValues);

  factory FiguresAsObject.fromJson(Map<String, dynamic> json) => _$FiguresAsObjectFromJson(json);

  Map<String, dynamic> toJson() => _$FiguresAsObjectToJson(this);
}