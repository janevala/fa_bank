import 'package:fa_bank/podo/portfolio/client.dart';
import 'package:fa_bank/podo/portfolio/graph.dart';
import 'package:fa_bank/podo/portfolio/portfolio_report.dart';
import 'package:fa_bank/podo/portfolio/trade_order.dart';
import 'package:json_annotation/json_annotation.dart';

part 'portfolio.g.dart';

@JsonSerializable()
class Portfolio {
  Client client;
  String portfolioName;
  String shortName;
  PortfolioReport portfolioReport;
  Graph graph;
  List<TradeOrder> tradeOrders;

  Portfolio(this.client, this.portfolioName, this.shortName, this.portfolioReport, this.graph, this.tradeOrders);

  factory Portfolio.fromJson(Map<String, dynamic> json) => _$PortfolioFromJson(json);

  Map<String, dynamic> toJson() => _$PortfolioToJson(this);
}