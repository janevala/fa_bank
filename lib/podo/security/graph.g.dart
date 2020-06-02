// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Graph _$GraphFromJson(Map<String, dynamic> json) {
  return Graph(
    json['date'] == null ? null : DateTime.parse(json['date'] as String),
    (json['price'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$GraphToJson(Graph instance) => <String, dynamic>{
      'date': instance.date?.toIso8601String(),
      'price': instance.price,
    };
