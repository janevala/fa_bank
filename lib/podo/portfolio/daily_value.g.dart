// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyValue _$DailyValueFromJson(Map<String, dynamic> json) {
  return DailyValue(
    json['date'] == null ? null : DateTime.parse(json['date'] as String),
    (json['benchmarkMinus100'] as num)?.toDouble(),
    (json['portfolioMinus100'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$DailyValueToJson(DailyValue instance) =>
    <String, dynamic>{
      'date': instance.date?.toIso8601String(),
      'portfolioMinus100': instance.portfolioMinus100,
      'benchmarkMinus100': instance.benchmarkMinus100,
    };
