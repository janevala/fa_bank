import 'package:fa_bank/podo/security/security.dart';
import 'package:json_annotation/json_annotation.dart';

part 'security_body.g.dart';

@JsonSerializable()
class SecurityBody {
  List<Security> securities;

  SecurityBody(this.securities);

  factory SecurityBody.fromJson(Map<String, dynamic> json) => _$SecurityBodyFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityBodyToJson(this);
}