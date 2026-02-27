abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({required this.email, required this.password});
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String? email;
  final String password;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phone;

  RegisterRequested(
      {required this.name,
      this.email,
      required this.password,
      this.dateOfBirth,
      this.gender,
      required this.phone});
}

class GoogleLoginRequested extends AuthEvent {
  final String googleToken;
  final String email;
  final String displayName;
  final String uid;
  final String photoURL;
  final String phoneNumber;

  GoogleLoginRequested({
    required this.googleToken,
    required this.email,
    required this.displayName,
    required this.uid,
    required this.photoURL,
    required this.phoneNumber,
  });
}

class SendOtpRequested extends AuthEvent {
  final String phone;

  SendOtpRequested({required this.phone});
}

class VerifyLoginMobile extends AuthEvent {
  final String phone;
  final String name;
  final String email;
  final String password;

  final String otp;

  VerifyLoginMobile(
      {required this.phone,
      required this.name,
      required this.email,
      required this.password,
      required this.otp});
}
class LogoutRequested extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final String? gender;
  final DateTime? dateOfBirth;

  UpdateProfileRequested({
    this.gender,
    this.dateOfBirth,
  });
}

class AcceptPolicyRequested extends AuthEvent {
  final bool accepted;

  AcceptPolicyRequested({required this.accepted});
}