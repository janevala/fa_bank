// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RiskObject _$RiskObjectFromJson(Map<String, dynamic> json) {
  return RiskObject(
    json['date'] == null ? null : DateTime.parse(json['date'] as String),
    (json['value'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$RiskObjectToJson(RiskObject instance) =>
    <String, dynamic>{
      'date': instance.date?.toIso8601String(),
      'value': instance.value,
    };
