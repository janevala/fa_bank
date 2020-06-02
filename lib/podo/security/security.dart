import 'package:fa_bank/podo/security/currency.dart';
import 'package:fa_bank/podo/security/graph.dart';
import 'package:fa_bank/podo/security/market_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'security.g.dart';

@JsonSerializable()
class Security {
  String name;
  String securityCode;
  MarketData marketData;
  Currency currency;
  List<Graph> graph;

  Security(this.name, this.securityCode, this.marketData, this.currency, this.graph);

  factory Security.fromJson(Map<String, dynamic> json) => _$SecurityFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityToJson(this);
}