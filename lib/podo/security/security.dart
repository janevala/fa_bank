import 'package:fa_bank/podo/security/currency.dart';
import 'package:fa_bank/podo/security/figures_as_object.dart';
import 'package:fa_bank/podo/security/graph.dart';
import 'package:fa_bank/podo/security/market_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'security.g.dart';

@JsonSerializable()
class Security {
  String name;
  String securityCode;
  String url;
  MarketData marketData;
  FiguresAsObject figuresAsObject;
  Currency currency;
  List<Graph> graph;

  Security(this.name, this.securityCode, this.url, this.marketData, this.figuresAsObject, this.currency, this.graph);

  factory Security.fromJson(Map<String, dynamic> json) => _$SecurityFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityToJson(this);
}