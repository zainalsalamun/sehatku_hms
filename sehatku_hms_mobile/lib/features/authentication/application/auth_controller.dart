import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';

class AuthState {
  const AuthState({
    this.role = UserRole.patient,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.token,
    this.userId,
    this.userFullName,
    this.email,
    this.avatarUrl,
    this.doctorId,
    this.doctorSpecialist,
    this.doctorDepartment,
    this.doctorLicenseNumber,
    this.doctorPracticeStatus = 'Aktif Melayani',
    this.doctorAvailableToday = true,
    this.patientId,
    this.patientMrn,
    this.errorMessage,
  });

  final UserRole role;
  final bool isLoading;
  final bool isLoggedIn;
  final String? token;
  final String? userId;
  final String? userFullName;
  final String? email;
  final String? avatarUrl;
  final String? doctorId;
  final String? doctorSpecialist;
  final String? doctorDepartment;
  final String? doctorLicenseNumber;
  final String? doctorPracticeStatus;
  final bool? doctorAvailableToday;
  final String? patientId;
  final String? patientMrn;
  final String? errorMessage;

  bool get isAuthenticated => isLoggedIn || (token != null && token!.isNotEmpty);

  AuthState copyWith({
    UserRole? role,
    bool? isLoading,
    bool? isLoggedIn,
    String? token,
    String? userId,
    String? userFullName,
    String? email,
    String? avatarUrl,
    String? doctorId,
    String? doctorSpecialist,
    String? doctorDepartment,
    String? doctorLicenseNumber,
    String? doctorPracticeStatus,
    bool? doctorAvailableToday,
    String? patientId,
    String? patientMrn,
    String? errorMessage,
  }) =>
      AuthState(
        role: role ?? this.role,
        isLoading: isLoading ?? this.isLoading,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        token: token ?? this.token,
        userId: userId ?? this.userId,
        userFullName: userFullName ?? this.userFullName,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        doctorId: doctorId ?? this.doctorId,
        doctorSpecialist: doctorSpecialist ?? this.doctorSpecialist,
        doctorDepartment: doctorDepartment ?? this.doctorDepartment,
        doctorLicenseNumber: doctorLicenseNumber ?? this.doctorLicenseNumber,
        doctorPracticeStatus: doctorPracticeStatus ?? this.doctorPracticeStatus,
        doctorAvailableToday: doctorAvailableToday ?? this.doctorAvailableToday,
        patientId: patientId ?? this.patientId,
        patientMrn: patientMrn ?? this.patientMrn,
        errorMessage: errorMessage,
      );
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be initialized in main()');
});

class AuthController extends Notifier<AuthState> {
  static const _kIsLoggedInKey = 'auth_is_logged_in';
  static const _kRoleKey = 'auth_role';
  static const _kTokenKey = 'auth_token';
  static const _kUserIdKey = 'auth_user_id';
  static const _kUserFullNameKey = 'auth_user_fullname';
  static const _kEmailKey = 'auth_email';
  static const _kAvatarUrlKey = 'auth_avatar_url';
  static const _kDoctorIdKey = 'auth_doctor_id';
  static const _kDoctorSpecialistKey = 'auth_doctor_specialist';
  static const _kDoctorDepartmentKey = 'auth_doctor_dept';
  static const _kDoctorLicenseKey = 'auth_doctor_license';
  static const _kDoctorPracticeStatusKey = 'auth_doctor_practice_status';
  static const _kDoctorAvailableTodayKey = 'auth_doctor_avail_today';
  static const _kPatientIdKey = 'auth_patient_id';
  static const _kPatientMrnKey = 'auth_patient_mrn';

  @override
  AuthState build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final isLoggedIn = prefs.getBool(_kIsLoggedInKey) ?? false;
      if (!isLoggedIn) {
        return const AuthState();
      }

      final roleStr = prefs.getString(_kRoleKey);
      final role = UserRole.values.where((r) => r.name == roleStr).firstOrNull ?? UserRole.patient;
      final token = prefs.getString(_kTokenKey);
      final userId = prefs.getString(_kUserIdKey);
      final fullName = prefs.getString(_kUserFullNameKey);
      final email = prefs.getString(_kEmailKey);
      final avatarUrl = prefs.getString(_kAvatarUrlKey);
      final doctorId = prefs.getString(_kDoctorIdKey);
      final doctorSpecialist = prefs.getString(_kDoctorSpecialistKey);
      final doctorDepartment = prefs.getString(_kDoctorDepartmentKey);
      final doctorLicenseNumber = prefs.getString(_kDoctorLicenseKey);
      final doctorPracticeStatus = prefs.getString(_kDoctorPracticeStatusKey) ?? 'Aktif Melayani';
      final doctorAvailableToday = prefs.getBool(_kDoctorAvailableTodayKey) ?? true;
      final patientId = prefs.getString(_kPatientIdKey);
      final patientMrn = prefs.getString(_kPatientMrnKey);

      if (token != null && token.isNotEmpty) {
        DioClient.instance.setAuthToken(token);
      }

      return AuthState(
        isLoggedIn: true,
        role: role,
        token: token,
        userId: userId,
        userFullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        doctorId: doctorId,
        doctorSpecialist: doctorSpecialist,
        doctorDepartment: doctorDepartment,
        doctorLicenseNumber: doctorLicenseNumber,
        doctorPracticeStatus: doctorPracticeStatus,
        doctorAvailableToday: doctorAvailableToday,
        patientId: patientId,
        patientMrn: patientMrn,
      );
    } catch (e) {
      debugPrint('[AuthController] Sync session restore error: $e');
      return const AuthState();
    }
  }

  Future<bool> loadSavedSession() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final isLoggedIn = prefs.getBool(_kIsLoggedInKey) ?? false;
      if (!isLoggedIn) return false;

      final roleStr = prefs.getString(_kRoleKey);
      final role = UserRole.values.where((r) => r.name == roleStr).firstOrNull ?? UserRole.patient;
      final token = prefs.getString(_kTokenKey);
      final userId = prefs.getString(_kUserIdKey);
      final fullName = prefs.getString(_kUserFullNameKey);
      final email = prefs.getString(_kEmailKey);
      final avatarUrl = prefs.getString(_kAvatarUrlKey);
      final doctorId = prefs.getString(_kDoctorIdKey);
      final doctorSpecialist = prefs.getString(_kDoctorSpecialistKey);
      final doctorDepartment = prefs.getString(_kDoctorDepartmentKey);
      final doctorLicenseNumber = prefs.getString(_kDoctorLicenseKey);
      final doctorPracticeStatus = prefs.getString(_kDoctorPracticeStatusKey) ?? 'Aktif Melayani';
      final doctorAvailableToday = prefs.getBool(_kDoctorAvailableTodayKey) ?? true;
      final patientId = prefs.getString(_kPatientIdKey);
      final patientMrn = prefs.getString(_kPatientMrnKey);

      if (token != null && token.isNotEmpty) {
        DioClient.instance.setAuthToken(token);
      }

      state = AuthState(
        isLoggedIn: true,
        role: role,
        token: token,
        userId: userId,
        userFullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        doctorId: doctorId,
        doctorSpecialist: doctorSpecialist,
        doctorDepartment: doctorDepartment,
        doctorLicenseNumber: doctorLicenseNumber,
        doctorPracticeStatus: doctorPracticeStatus,
        doctorAvailableToday: doctorAvailableToday,
        patientId: patientId,
        patientMrn: patientMrn,
      );
      return true;
    } catch (e) {
      debugPrint('[AuthController] Error loading saved session: $e');
      return false;
    }
  }

  void selectRole(UserRole role) => state = state.copyWith(role: role);

  Future<bool> signInWithCredentials(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.login(email: email, password: password);
      if (res != null) {
        final user = res['user'] as Map<String, dynamic>?;
        final roles = (user?['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final doc = user?['doctor'] as Map<String, dynamic>?;
        final pat = user?['patient'] as Map<String, dynamic>?;

        UserRole detectedRole = UserRole.patient;
        if (roles.contains('hospital_admin') || roles.contains('super_admin') || email.contains('admin')) {
          detectedRole = UserRole.admin;
        } else if (roles.contains('doctor') || email.contains('doctor') || email.contains('dr.')) {
          detectedRole = UserRole.doctor;
        }

        final token = res['accessToken']?.toString();
        final userId = user?['id']?.toString() ?? 'usr-${DateTime.now().millisecondsSinceEpoch}';
        final userFullName = user?['fullName']?.toString() ??
            user?['name']?.toString() ??
            doc?['name']?.toString() ??
            pat?['name']?.toString() ??
            (detectedRole == UserRole.doctor ? 'Dokter' : (detectedRole == UserRole.admin ? 'Administrator RS' : email.split('@').first));
        final userEmail = user?['email']?.toString() ?? email;
        final avatarUrl = doc?['avatarUrl']?.toString() ??
            doc?['photoUrl']?.toString() ??
            user?['avatarUrl']?.toString() ??
            user?['photoUrl']?.toString();
        final doctorId = doc?['id']?.toString();
        final doctorSpecialist = doc?['specialist']?.toString();
        final doctorDepartment = doc?['departmentName']?.toString();
        final doctorLicenseNumber = doc?['licenseNumber']?.toString();
        final doctorAvailableToday = (doc?['availableToday'] as bool?) ?? true;
        final doctorPracticeStatus = !doctorAvailableToday
            ? 'Selesai Praktek'
            : (doc?['status'] == 'inactive' ? 'Istirahat / Break' : 'Aktif Melayani');
        final patientId = pat?['id']?.toString();
        final patientMrn = pat?['medicalRecordNumber']?.toString();

        if (token != null && token.isNotEmpty) {
          DioClient.instance.setAuthToken(token);
        }

        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          token: token,
          userId: userId,
          userFullName: userFullName,
          email: userEmail,
          avatarUrl: avatarUrl,
          role: detectedRole,
          doctorId: doctorId,
          doctorSpecialist: doctorSpecialist,
          doctorDepartment: doctorDepartment,
          doctorLicenseNumber: doctorLicenseNumber,
          doctorPracticeStatus: doctorPracticeStatus,
          doctorAvailableToday: doctorAvailableToday,
          patientId: patientId,
          patientMrn: patientMrn,
        );

        await _saveSessionToPrefs(
          isLoggedIn: true,
          role: detectedRole,
          token: token,
          userId: userId,
          userFullName: userFullName,
          email: userEmail,
          avatarUrl: avatarUrl,
          doctorId: doctorId,
          doctorSpecialist: doctorSpecialist,
          doctorDepartment: doctorDepartment,
          doctorLicenseNumber: doctorLicenseNumber,
          doctorPracticeStatus: doctorPracticeStatus,
          doctorAvailableToday: doctorAvailableToday,
          patientId: patientId,
          patientMrn: patientMrn,
        );

        return true;
      }
    } catch (e) {
      debugPrint('[AuthController] API login failed: $e');
    }

    // Fallback: Support offline demo accounts and persist session
    if (password.isNotEmpty && (email.contains('@') || email.isNotEmpty)) {
      UserRole demoRole = state.role;
      if (email.contains('doctor') || email.contains('dr.')) {
        demoRole = UserRole.doctor;
      } else if (email.contains('admin')) {
        demoRole = UserRole.admin;
      } else if (email.contains('patient') || email.contains('nadia')) {
        demoRole = UserRole.patient;
      }

      String demoName = switch (demoRole) {
        UserRole.doctor => 'dr. Maya Pratama, Sp.JP',
        UserRole.admin => 'Administrator RS (Live)',
        UserRole.patient => 'Nadia Putri',
      };
      String? demoDocId = demoRole == UserRole.doctor ? '30000000-0000-4000-8000-000000000001' : null;
      String? demoDocDept = demoRole == UserRole.doctor ? 'Kardiologi & Vaskular' : null;
      String? demoDocSpecialist = demoRole == UserRole.doctor ? 'Kardiologi & Vaskular' : null;
      String? demoDocLicense = demoRole == UserRole.doctor ? 'SIP.449.1/023/2021' : null;
      String? demoDocAvatar = demoRole == UserRole.doctor ? '/public/doctors/dr_maya_pratama.jpg' : null;

      if (demoRole == UserRole.doctor) {
        if (email.contains('rafi') || email.contains('gigi')) {
          demoName = 'drg. Rafi Akbar, Sp.KG';
          demoDocId = '30000000-0000-4000-8000-000000000002';
          demoDocDept = 'Kesehatan Gigi & Mulut';
          demoDocSpecialist = 'Kesehatan Gigi & Mulut';
          demoDocLicense = 'SIP.449.1/045/2020';
          demoDocAvatar = '/public/doctors/drg_rafi_akbar.jpg';
        } else if (email.contains('hendra') || email.contains('interna')) {
          demoName = 'dr. Hendra Wijaya, Sp.PD';
          demoDocId = '30000000-0000-4000-8000-000000000005';
          demoDocDept = 'Penyakit Dalam';
          demoDocSpecialist = 'Penyakit Dalam';
          demoDocLicense = 'SIP.449.1/077/2019';
          demoDocAvatar = '/public/doctors/dr_hendra_wijaya.jpg';
        }
      }

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        role: demoRole,
        email: email,
        userFullName: demoName,
        avatarUrl: demoDocAvatar,
        doctorId: demoDocId,
        doctorSpecialist: demoDocSpecialist,
        doctorDepartment: demoDocDept,
        doctorLicenseNumber: demoDocLicense,
        doctorPracticeStatus: 'Aktif Melayani',
        doctorAvailableToday: true,
        patientId: demoRole == UserRole.patient ? '40000000-0000-4000-8000-000000000001' : null,
        patientMrn: demoRole == UserRole.patient ? 'MRN-2026-001' : null,
      );

      await _saveSessionToPrefs(
        isLoggedIn: true,
        role: demoRole,
        userFullName: demoName,
        email: email,
        avatarUrl: demoDocAvatar,
        doctorId: demoDocId,
        doctorSpecialist: demoDocSpecialist,
        doctorDepartment: demoDocDept,
        doctorLicenseNumber: demoDocLicense,
        doctorPracticeStatus: 'Aktif Melayani',
        doctorAvailableToday: true,
        patientId: demoRole == UserRole.patient ? '40000000-0000-4000-8000-000000000001' : null,
        patientMrn: demoRole == UserRole.patient ? 'MRN-2026-001' : null,
      );

      return true;
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Email atau password tidak sesuai dengan database.',
    );
    return false;
  }

  Future<void> updateDoctorPracticeStatus(String newStatus) async {
    final isAvailable = newStatus == 'Aktif Melayani';
    state = state.copyWith(
      doctorPracticeStatus: newStatus,
      doctorAvailableToday: isAvailable,
    );
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_kDoctorPracticeStatusKey, newStatus);
      await prefs.setBool(_kDoctorAvailableTodayKey, isAvailable);
    } catch (e) {
      debugPrint('[AuthController] Error saving doctor practice status: $e');
    }

    if (state.doctorId != null && state.doctorId!.isNotEmpty) {
      try {
        final client = ref.read(apiClientProvider);
        await client.updateDoctorAvailability(state.doctorId!, availableToday: isAvailable);
      } catch (e) {
        debugPrint('[AuthController] Failed to sync doctor availability to backend: $e');
      }
    }
  }

  Future<void> _saveSessionToPrefs({
    required bool isLoggedIn,
    required UserRole role,
    String? token,
    String? userId,
    required String userFullName,
    required String email,
    String? avatarUrl,
    String? doctorId,
    String? doctorSpecialist,
    String? doctorDepartment,
    String? doctorLicenseNumber,
    String? doctorPracticeStatus,
    bool? doctorAvailableToday,
    String? patientId,
    String? patientMrn,
  }) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(_kIsLoggedInKey, isLoggedIn);
      await prefs.setString(_kRoleKey, role.name);
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_kTokenKey, token);
      } else {
        await prefs.remove(_kTokenKey);
      }
      if (userId != null) await prefs.setString(_kUserIdKey, userId);
      await prefs.setString(_kUserFullNameKey, userFullName);
      await prefs.setString(_kEmailKey, email);
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await prefs.setString(_kAvatarUrlKey, avatarUrl);
      } else {
        await prefs.remove(_kAvatarUrlKey);
      }
      if (doctorId != null) {
        await prefs.setString(_kDoctorIdKey, doctorId);
      } else {
        await prefs.remove(_kDoctorIdKey);
      }
      if (doctorSpecialist != null) {
        await prefs.setString(_kDoctorSpecialistKey, doctorSpecialist);
      } else {
        await prefs.remove(_kDoctorSpecialistKey);
      }
      if (doctorDepartment != null) {
        await prefs.setString(_kDoctorDepartmentKey, doctorDepartment);
      } else {
        await prefs.remove(_kDoctorDepartmentKey);
      }
      if (doctorLicenseNumber != null) {
        await prefs.setString(_kDoctorLicenseKey, doctorLicenseNumber);
      } else {
        await prefs.remove(_kDoctorLicenseKey);
      }
      if (doctorPracticeStatus != null) {
        await prefs.setString(_kDoctorPracticeStatusKey, doctorPracticeStatus);
      } else {
        await prefs.remove(_kDoctorPracticeStatusKey);
      }
      if (doctorAvailableToday != null) {
        await prefs.setBool(_kDoctorAvailableTodayKey, doctorAvailableToday);
      } else {
        await prefs.remove(_kDoctorAvailableTodayKey);
      }
      if (patientId != null) {
        await prefs.setString(_kPatientIdKey, patientId);
      } else {
        await prefs.remove(_kPatientIdKey);
      }
      if (patientMrn != null) {
        await prefs.setString(_kPatientMrnKey, patientMrn);
      } else {
        await prefs.remove(_kPatientMrnKey);
      }
    } catch (e) {
      debugPrint('[AuthController] Error saving session to prefs: $e');
    }
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, isLoggedIn: true);
    final demoName = switch (state.role) {
      UserRole.doctor => 'dr. Maya Pratama, Sp.JP',
      UserRole.admin => 'Administrator RS (Live)',
      UserRole.patient => 'Nadia Putri',
    };
    final isDoctor = state.role == UserRole.doctor;
    await _saveSessionToPrefs(
      isLoggedIn: true,
      role: state.role,
      userFullName: state.userFullName ?? demoName,
      email: state.email ?? '${state.role.name}@sehatku.id',
      avatarUrl: isDoctor ? '/public/doctors/dr_maya_pratama.jpg' : null,
      doctorId: isDoctor ? '30000000-0000-4000-8000-000000000001' : null,
      doctorSpecialist: isDoctor ? 'Kardiologi & Vaskular' : null,
      doctorDepartment: isDoctor ? 'Kardiologi & Vaskular' : null,
      doctorLicenseNumber: isDoctor ? 'SIP.449.1/023/2021' : null,
      doctorPracticeStatus: isDoctor ? 'Aktif Melayani' : null,
      doctorAvailableToday: isDoctor ? true : null,
      patientId: state.role == UserRole.patient ? '40000000-0000-4000-8000-000000000001' : null,
      patientMrn: state.role == UserRole.patient ? 'MRN-2026-001' : null,
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    state = state.copyWith(
      isLoading: false,
      userFullName: state.userFullName ?? demoName,
      avatarUrl: isDoctor ? '/public/doctors/dr_maya_pratama.jpg' : null,
      doctorId: isDoctor ? '30000000-0000-4000-8000-000000000001' : null,
      doctorSpecialist: isDoctor ? 'Kardiologi & Vaskular' : null,
      doctorDepartment: isDoctor ? 'Kardiologi & Vaskular' : null,
      doctorLicenseNumber: isDoctor ? 'SIP.449.1/023/2021' : null,
      doctorPracticeStatus: isDoctor ? 'Aktif Melayani' : null,
      doctorAvailableToday: isDoctor ? true : null,
    );
  }

  Future<void> signOut() async {
    DioClient.instance.setAuthToken(null);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.clear();
    } catch (e) {
      debugPrint('[AuthController] Error clearing session prefs: $e');
    }
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
