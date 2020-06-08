// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Portfolio _$PortfolioFromJson(Map<String, dynamic> json) {
  return Portfolio(
    json['client'] == null
        ? null
        : Client.fromJson(json['client'] as Map<String, dynamic>),
    json['portfolioName'] as String,
    json['shortName'] as String,
    json['portfolioReport'] == null
        ? null
        : PortfolioReport.fromJson(
            json['portfolioReport'] as Map<String, dynamic>),
    json['graph'] == null
        ? null
        : Graph.fromJson(json['graph'] as Map<String, dynamic>),
    (json['tradeOrders'] as List)
        ?.map((e) =>
            e == null ? null : TradeOrder.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$PortfolioToJson(Portfolio instance) => <String, dynamic>{
      'client': instance.client,
      'portfolioName': instance.portfolioName,
      'shortName': instance.shortName,
      'portfolioReport': instance.portfolioReport,
      'graph': instance.graph,
      'tradeOrders': instance.tradeOrders,
    };
