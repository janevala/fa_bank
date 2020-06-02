// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Graph _$GraphFromJson(Map<String, dynamic> json) {
  return Graph(
    json['dailyValues'] == null
        ? null
        : DailyValues.fromJson(json['dailyValues'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$GraphToJson(Graph instance) => <String, dynamic>{
      'dailyValues': instance.dailyValues,
    };
