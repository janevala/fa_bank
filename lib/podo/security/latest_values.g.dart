// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'latest_values.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LatestValues _$LatestValuesFromJson(Map<String, dynamic> json) {
  return LatestValues(
    json['ESG'] == null
        ? null
        : EsgObject.fromJson(json['ESG'] as Map<String, dynamic>),
    json['RISK'] == null
        ? null
        : RiskObject.fromJson(json['RISK'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$LatestValuesToJson(LatestValues instance) =>
    <String, dynamic>{
      'ESG': instance.esgObject,
      'RISK': instance.riskObject,
    };
