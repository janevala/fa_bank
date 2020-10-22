import 'package:fa_bank/podo/security/esg.dart';
import 'package:fa_bank/podo/security/risk.dart';
import 'package:json_annotation/json_annotation.dart';

part 'latest_values.g.dart';

@JsonSerializable()
class LatestValues {
  @JsonKey(name: 'ESG')
  EsgObject esgObject;
  @JsonKey(name: 'RISK')
  RiskObject riskObject;

  LatestValues(this.esgObject, this.riskObject);

  factory LatestValues.fromJson(Map<String, dynamic> json) => _$LatestValuesFromJson(json);

  Map<String, dynamic> toJson() => _$LatestValuesToJson(this);
}