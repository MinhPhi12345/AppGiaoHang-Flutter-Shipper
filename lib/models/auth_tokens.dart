/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Tương ứng TokenResponse bên IdentityService:
///   record TokenResponse(string AccessToken, string RefreshToken, DateTime ExpiresAt)
///
/// Cần có field: accessToken, refreshToken, expiresAt (DateTime).
/// Nên có factory `fromJson(Map<String, dynamic> json)`.
class AuthTokens {
  // TODO: implement
}
