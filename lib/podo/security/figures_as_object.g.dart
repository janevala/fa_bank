// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'figures_as_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FiguresAsObject _$FiguresAsObjectFromJson(Map<String, dynamic> json) {
  return FiguresAsObject(
    json['latestValues'] == null
        ? null
        : LatestValues.fromJson(json['latestValues'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$FiguresAsObjectToJson(FiguresAsObject instance) =>
    <String, dynamic>{
      'latestValues': instance.latestValues,
    };
