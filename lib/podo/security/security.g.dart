// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Security _$SecurityFromJson(Map<String, dynamic> json) {
  return Security(
    json['name'] as String,
    json['securityCode'] as String,
    json['url'] as String,
    json['marketData'] == null
        ? null
        : MarketData.fromJson(json['marketData'] as Map<String, dynamic>),
    json['figuresAsObject'] == null
        ? null
        : FiguresAsObject.fromJson(
            json['figuresAsObject'] as Map<String, dynamic>),
    json['currency'] == null
        ? null
        : Currency.fromJson(json['currency'] as Map<String, dynamic>),
    (json['graph'] as List)
        ?.map(
            (e) => e == null ? null : Graph.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$SecurityToJson(Security instance) => <String, dynamic>{
      'name': instance.name,
      'securityCode': instance.securityCode,
      'url': instance.url,
      'marketData': instance.marketData,
      'figuresAsObject': instance.figuresAsObject,
      'currency': instance.currency,
      'graph': instance.graph,
    };
