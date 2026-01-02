class LoginResponse {
  final String? username;
  final String? accessToken;
  final String? tokenType;
  final int? expiresIn;
  final String? detail; // For error messages
  final int? admin;

  LoginResponse({
    this.username,
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.detail,
    this.admin,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      username: json['username'] as String?,
      accessToken: json['access_token'] as String?,
      tokenType: json['token_type'] as String?,
      expiresIn: json['expires_in'] as int?,
      detail: json['detail'] as String?,
      admin: json['admin'] as int?,
    );
  }

  bool get isSuccess => accessToken != null;
  bool get isError => detail != null;
}
