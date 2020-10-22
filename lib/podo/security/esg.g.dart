// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'esg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EsgObject _$EsgObjectFromJson(Map<String, dynamic> json) {
  return EsgObject(
    json['date'] == null ? null : DateTime.parse(json['date'] as String),
    (json['value'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$EsgObjectToJson(EsgObject instance) => <String, dynamic>{
      'date': instance.date?.toIso8601String(),
      'value': instance.value,
    };
