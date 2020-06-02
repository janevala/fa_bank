// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_values.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyValues _$DailyValuesFromJson(Map<String, dynamic> json) {
  return DailyValues(
    (json['dailyValue'] as List)
        ?.map((e) =>
            e == null ? null : DailyValue.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$DailyValuesToJson(DailyValues instance) =>
    <String, dynamic>{
      'dailyValue': instance.dailyValue,
    };
