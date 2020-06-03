import 'package:fa_bank/podo/portfolio/daily_values.dart';
import 'package:json_annotation/json_annotation.dart';

part 'graph.g.dart';

@JsonSerializable()
class Graph {
  DailyValues dailyValues;

  Graph(this.dailyValues);

  factory Graph.fromJson(Map<String, dynamic> json) => _$GraphFromJson(json);

  Map<String, dynamic> toJson() => _$GraphToJson(this);
}