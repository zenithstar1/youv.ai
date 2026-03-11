import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skin_analysis_app/Api/Apiservice.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<GoogleLoginRequested>(_googleLogin);
    on<SendOtpRequested>(sendOtp);
    on<VerifyLoginMobile>(mobileLogin);
    on<LogoutRequested>(logout);
    on<UpdateProfileRequested>(_updateProfile);
    on<AcceptPolicyRequested>(_acceptPolicy);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      print("login");
      final response = await http.post(
        Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/auth/login',
        ),
        body: {'email': event.email, 'password': event.password},
      );
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLogin', true);

        // Optionally, store user info from response
        emit(AuthAuthenticated("Login successful!"));
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('data')) {
          print("User info received: ${responseData['data']}");
          prefs.setString('userInfo', json.encode(responseData['data']));
          prefs.setString('_token', responseData['data']['token'] ?? '');
          prefs.setBool(
            'isSubscribe',
            responseData['data']['isSubscribed'] ?? false,
          );

          print("User info stored: ${responseData['data']['token']}");
        } else {
          emit(AuthError('Invalid response format'));
          return;
        }
      } else {
        emit(AuthError('Login failed: ${response.body}'));
        return;
      }
    } catch (e) {
      print("Login error: $e");
      emit(AuthError('Login failed: $e'));
      return;
    }
    print(
      "Login requested with email: ${event.email} and password: ${event.password}",
    );
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    print(
      "Register requested with name: ${event.name}, email: ${event.email}, dateOfBirth: ${event.dateOfBirth}, gender: ${event.gender}, phone: ${event.phone}",
    );
    var isvalidate = validateRegistrationFields(
      name: event.name,
      // email: event.email,
      password: event.password,
      confirmPassword: event.password,
      phone: event.phone ?? '',
      // dateOfBirth: event.dateOfBirth?.toIso8601String(),
      // gender: event.gender,
      // address: event.address,
    );
    print("isvalidate: $isvalidate");
    if (!isvalidate['isValid']) {
      emit(AuthError(isvalidate['message']));
      return;
    }

    emit(AuthLoading());
    try {
      // Replace with your actual API endpoint
      final response = await http.post(
        Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/auth/register',
        ),
        body: {
          'name': event.name,
          'email': event.email,
          'password': event.password,
          'dateOfBirth': event.dateOfBirth?.toIso8601String() ?? '',
          'gender': event.gender ?? '',
          'phone': event.phone ?? '',
        },
      );
      print(response.body);

      if (response.statusCode == 201) {
        // Registration successful
        emit(AuthAuthenticated("Registration successful!"));
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLogin', true);

        final responseData = json.decode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          print("User info received: ${responseData['data']}");
          prefs.setString('userInfo', json.encode(responseData['data']));
          prefs.setString('_token', responseData['data']['token'] ?? '');
          prefs.setBool(
            'isSubscribe',
            responseData['data']['isSubscribed'] ?? false,
          );
          print("User info stored: ${responseData['data']['token']}");
        } else {
          emit(AuthError('Invalid response format'));
          return;
        }
      } else {
        emit(AuthError('Registration failed: ${response.body}'));
        return;
      }
    } catch (e) {
      emit(AuthError('Registration failed: $e'));
      return;
    }
    // Simulate successful registration
  }

  Future<void> sendOtp(SendOtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final rawDigits = event.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final normalizedPhone = rawDigits.length > 10
          ? rawDigits.substring(rawDigits.length - 10)
          : rawDigits;

      if (normalizedPhone.length != 10) {
        emit(AuthError('Please enter a valid 10-digit mobile number'));
        return;
      }

      final response = await http.post(
        Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/auth/send-otp',
        ),
        body: {
          'mobile': normalizedPhone,
          'flow': event.flow,
          'type': event.flow,
        },
      );
      print('sendOtp flow=${event.flow} status=${response.statusCode}');
      print(response.body);

      Map<String, dynamic>? responseData;
      String backendMessage = '';
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map) {
          responseData = Map<String, dynamic>.from(decoded);
          backendMessage = (responseData['message'] ?? '').toString();
          if (backendMessage.isEmpty && responseData['error'] != null) {
            backendMessage = responseData['error'].toString();
          }
          if (backendMessage.isEmpty && responseData['data'] is Map) {
            final nestedData = Map<String, dynamic>.from(responseData['data']);
            backendMessage = (nestedData['message'] ?? '').toString();
          }
        }
      } catch (_) {}

      final lowerMessage = backendMessage.toLowerCase();
      final businessFailure =
          responseData != null && responseData['success'] == false;
      final indicatesAlreadyExists =
          lowerMessage.contains('already') ||
          lowerMessage.contains('exist') ||
          lowerMessage.contains('registered') ||
          lowerMessage.contains('duplicate');
      final indicatesNotFound =
          lowerMessage.contains('not found') ||
          lowerMessage.contains('not registered') ||
          lowerMessage.contains('does not exist') ||
          lowerMessage.contains('no account') ||
          lowerMessage.contains('no user');

      if (event.flow == 'signup' &&
          (response.statusCode == 409 || indicatesAlreadyExists)) {
        emit(
          AuthError(
            'This mobile number is already registered. Please login.',
          ),
        );
        return;
      }

      if (event.flow == 'login' && indicatesNotFound) {
        emit(
          AuthError(
            'This mobile number is not registered. Please sign up first.',
          ),
        );
        return;
      }

      if (response.statusCode == 200 && !businessFailure) {
        emit(AuthMessage(
          backendMessage.isNotEmpty ? backendMessage : "OTP sent successfully!",
        ));
      } else {
        emit(
          AuthError(
            backendMessage.isNotEmpty
                ? backendMessage
                : 'Failed to send OTP: ${response.body}',
          ),
        );
      }
    } catch (e) {
      emit(AuthError('Failed to send OTP: $e'));
    }
  }

  Future<void> mobileLogin(
    VerifyLoginMobile event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await http.post(
        Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/auth/mobile-login',
        ),
        body: {
          'phone': event.phone,
          'otp': event.otp,
          'mobile': event.phone,
          'name': event.name,
          'email': event.email,
          // 'password': event.password,
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLogin', true);

        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('data')) {
          prefs.setString('userInfo', json.encode(responseData['data']));
          prefs.setString('_token', responseData['data']['token'] ?? '');
          prefs.setBool(
            'isSubscribe',
            responseData['data']['isSubscribed'] ?? false,
          );
          emit(AuthAuthenticated("Mobile verification successful!"));
        } else {
          emit(AuthError('Invalid response format'));
        }
      } else {
        String backendMessage = response.body;
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            backendMessage = decoded['message'].toString();
          }
        } catch (_) {}
        emit(AuthError('Mobile verification failed: $backendMessage'));
      }
    } catch (e) {
      emit(AuthError('Mobile verification failed: $e'));
    }
  }

  Future<void> _googleLogin(
    GoogleLoginRequested googleLoginRequested,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await http.post(
        Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/auth/google-login',
        ),
        body: {
          'google_id': googleLoginRequested.googleToken,
          'email': googleLoginRequested.email,
          'name': googleLoginRequested.displayName,
          'uid': googleLoginRequested.uid,
          'image': googleLoginRequested.photoURL,
          'phone': googleLoginRequested.phoneNumber,
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLogin', true);

        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('data')) {
          prefs.setString('userInfo', json.encode(responseData['data']));
          prefs.setString('_token', responseData['data']['token'] ?? '');
          prefs.setBool(
            'isSubscribe',
            responseData['data']['isSubscribed'] ?? false,
          );
          emit(AuthAuthenticated("Google login successful!"));
        } else {
          emit(AuthError('Invalid response format'));
        }
      } else {
        emit(AuthError('Google login failed: ${response.body}'));
      }
    } catch (e) {
      emit(AuthError('Google login failed: $e'));
    }
  }

  Map<String, dynamic> validateRegistrationFields({
    required String name,
    String? email,
    required String password,
    required String confirmPassword,
    required String phone,
    // required String dateOfBirth,
    // required String gender,
    // required String address,
  }) {
    if (name.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        phone.isEmpty
    // dateOfBirth.isEmpty ||
    // gender.isEmpty ||
    // address.isEmpty
    ) {
      return {'isValid': false, 'message': 'All fields are required.'};
    }
    if (password != confirmPassword) {
      return {'isValid': false, 'message': 'Passwords do not match.'};
    }

    // Add more validation as needed (e.g., email format)
    return {'isValid': true, 'message': 'Validation successful.'};
  }

  Future<void> logout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      print("Logging out...");
      await http.post(
        Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/auth/logout',
        ),
        headers: {
          'Authorization':
              'Bearer ${((await SharedPreferences.getInstance()).getString('_token') ?? '')}',
        },
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLogin');
      await prefs.remove('userInfo');
      await prefs.remove('_token');
      await prefs.remove('isSubscribe');
      emit(AuthLogout());
    } catch (e) {
      emit(AuthError('Logout failed: $e'));
    }
  }

  Future<void> _updateProfile(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingProfile());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';

      final response = await http.post(
        Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/auth/update-profile',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'gender': event.gender,
          'date_of_birth': event.dateOfBirth?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Profile update response: $responseData');

        // Check if the response has a success field
        if (responseData is Map) {
          bool? success = responseData['success'];

          if (success == true) {
            // Get current user data
            final currentUserInfoString = prefs.getString('userInfo');
            Map<String, dynamic> updatedUserData = {};

            if (currentUserInfoString != null) {
              updatedUserData = Map<String, dynamic>.from(
                json.decode(currentUserInfoString),
              );
            }

            // Update with new gender and date of birth
            updatedUserData['gender'] = event.gender;
            updatedUserData['date_of_birth'] = event.dateOfBirth
                ?.toIso8601String();

            // Save updated user data
            prefs.setString('userInfo', json.encode(updatedUserData));

            print('Emitting AuthMessage: Profile updated successfully!');
            emit(AuthMessage('Profile updated successfully!'));
          } else {
            print('Emitting AuthError: Profile update failed');
            emit(
              AuthError(
                'Profile update failed: ${responseData['message'] ?? 'Unknown error'}',
              ),
            );
          }
          emit(AuthProfileLoaded());
        } else {
          emit(AuthError('Invalid response format'));
        }
      } else {
        emit(AuthError('Profile update failed: ${response.body}'));
      }
    } catch (e) {
      emit(AuthError('Profile update failed: $e'));
    }
  }

  Future<void> _acceptPolicy(
    AcceptPolicyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Call API to update policy acceptance
      final result = await ApiService.updatePolicyAcceptance(event.accepted);

      if (result['success'] == true) {
        // Update local user data
        final prefs = await SharedPreferences.getInstance();
        final userInfoString = prefs.getString('userInfo');
        if (userInfoString != null) {
          final userData = json.decode(userInfoString);
          userData['policy_accept'] = 1;
          prefs.setString('userInfo', json.encode(userData));
        }
        emit(PolicyAccepted('Policy acceptance updated successfully'));
      } else {
        emit(
          AuthError('Error updating policy acceptance: ${result['message']}'),
        );
      }
    } catch (e) {
      emit(AuthError('Error updating policy acceptance: $e'));
    }
  }
}
