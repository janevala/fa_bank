import 'package:fa_bank/podo/security/security.dart';
import 'package:json_annotation/json_annotation.dart';

part 'security_body.g.dart';

@JsonSerializable()
class SecurityBody {
  List<Security> securities;

  @JsonKey(ignore: true)
  String error;

  SecurityBody(this.securities);

  factory SecurityBody.fromJson(Map<String, dynamic> json) => _$SecurityBodyFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityBodyToJson(this);

  SecurityBody.withError(this.error);
}