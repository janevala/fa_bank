import 'package:json_annotation/json_annotation.dart';

part 'graph.g.dart';

@JsonSerializable()
class Graph {
  DateTime date;
  double price;

  Graph(this.date, this.price);

  factory Graph.fromJson(Map<String, dynamic> json) => _$GraphFromJson(json);

  Map<String, dynamic> toJson() => _$GraphToJson(this);
}