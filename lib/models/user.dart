/// KHUNG - chưa có logic thật, cần triển khai.
///
/// Tương ứng UserResponse bên IdentityService:
///   record UserResponse(Guid UserId, string FullName, string Email, string Phone, string Role)
///
/// Cần có field: userId, fullName, email, phone, role (String, "DRIVER"/"CUSTOMER"/"ADMIN").
/// Nên có factory `fromJson(Map<String, dynamic> json)`.
class AppUser {
  // TODO: implement
}
