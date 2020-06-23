class MutationResponse {
  List<dynamic> response;
  String error;

  MutationResponse(this.response, this.error);

  MutationResponse.withList(this.response);

  MutationResponse.withError(this.error);
}