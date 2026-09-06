/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Gọi các API của IdentityService qua Gateway: /api/identity/...
/// Cần có các hàm (nhận ApiClient qua constructor):
/// - register({email, password, fullName, phone}) -> POST /api/identity/register
/// - login({email, password})                     -> POST /api/identity/login
/// - refresh(refreshToken)                         -> POST /api/identity/refresh
/// - logout(refreshToken)                          -> POST /api/identity/logout
/// - getMe()                                       -> GET  /api/identity/me
class AuthService {
  // TODO: implement
}
