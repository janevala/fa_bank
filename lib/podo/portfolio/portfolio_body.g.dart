// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PortfolioBody _$PortfolioBodyFromJson(Map<String, dynamic> json) {
  return PortfolioBody(
    json['portfolio'] == null
        ? null
        : Portfolio.fromJson(json['portfolio'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$PortfolioBodyToJson(PortfolioBody instance) =>
    <String, dynamic>{
      'portfolio': instance.portfolio,
    };
