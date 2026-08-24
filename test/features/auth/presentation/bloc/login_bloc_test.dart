import 'package:bloc_test/bloc_test.dart';
import 'package:epresensi_mobile/features/auth/presentation/bloc/login_bloc.dart';
import 'package:epresensi_mobile/features/auth/presentation/bloc/login_event.dart';
import 'package:epresensi_mobile/features/auth/presentation/bloc/login_state.dart';
import 'package:epresensi_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:epresensi_mobile/core/services/security_service.dart';
import 'package:epresensi_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:epresensi_mobile/features/auth/domain/entities/employee_detail.dart';
import 'package:epresensi_mobile/features/auth/domain/entities/login_result.dart';
import 'package:epresensi_mobile/core/error/auth_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockSecurityService extends Mock implements SecurityService {}

void main() {
  late LoginBloc loginBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockSecurityService mockSecurityService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockLoginUseCase = MockLoginUseCase();
    mockSecurityService = MockSecurityService();
    loginBloc = LoginBloc(
      loginUseCase: mockLoginUseCase,
      securityService: mockSecurityService,
    );
  });

  tearDown(() {
    loginBloc.close();
  });

  group('LoginBloc Tests', () {
    test('initial state is LoginState()', () {
      expect(loginBloc.state, const LoginState());
    });

    blocTest<LoginBloc, LoginState>(
      'emits [passwordVisibility changed] when LoginPasswordVisibilityChanged is added',
      build: () => loginBloc,
      act: (bloc) => bloc.add(const LoginPasswordVisibilityChanged(true)),
      expect: () => [const LoginState(isPasswordVisible: true)],
    );

    blocTest<LoginBloc, LoginState>(
      'emits failure status when username or password is empty',
      build: () => loginBloc,
      act: (bloc) => bloc.add(
        const LoginSubmitted(username: '', password: '', deviceId: ''),
      ),
      expect: () => [
        const LoginState(
          status: LoginStatus.failure,
          errorMessage: 'Username atau password tidak boleh kosong',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [success] when LoginSubmitted succeeds',
      build: () {
        const tEmployeeDetail = EmployeeDetail(
          id: '1',
          nip: 'test_nip',
          nama: 'John Doe',
          email: 'john@example.com',
          jenisKelamin: 'L',
          jabatanNama: 'Staff',
          unorNama: 'IT',
          unorIndukNama: 'Pusat',
          unorId: '123',
        );

        const tLoginResult = LoginResult(
          nama: 'John Doe',
          username: 'test_user',
          nip: 'test_nip',
          unorId: '123',
          idMesin: 1,
          tipeAbsensi: 'A',
        );

        const tUserEntity = UserEntity(
          detailPegawai: tEmployeeDetail,
          kode: 200,
          daftarKordinat: [],
          result: tLoginResult,
          kodeUnik: 'dummy_device_id',
          wfaStatus: 0,
        );

        when(
          () => mockLoginUseCase(
            username: 'test_user',
            password: 'password123',
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((_) async => tUserEntity);

        when(
          () => mockLoginUseCase.checkUserBlock('test_nip'),
        ).thenAnswer((_) async => {});

        return loginBloc;
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(
          username: 'test_user',
          password: 'password123',
          deviceId: 'dummy_device_id',
        ),
      ),
      expect: () => [
        const LoginState(
          status: LoginStatus.loading,
          username: 'test_user',
          password: 'password123',
        ),
        const LoginState(
          status: LoginStatus.success,
          username: 'test_user',
          password: 'password123',
          response: UserEntity(
            detailPegawai: EmployeeDetail(
              id: '1',
              nip: 'test_nip',
              nama: 'John Doe',
              email: 'john@example.com',
              jenisKelamin: 'L',
              jabatanNama: 'Staff',
              unorNama: 'IT',
              unorIndukNama: 'Pusat',
              unorId: '123',
            ),
            kode: 200,
            daftarKordinat: [],
            result: LoginResult(
              nama: 'John Doe',
              username: 'test_user',
              nip: 'test_nip',
              unorId: '123',
              idMesin: 1,
              tipeAbsensi: 'A',
            ),
            kodeUnik: 'dummy_device_id',
            wfaStatus: 0,
          ),
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [failure] when LoginSubmitted throws AuthException',
      build: () {
        when(
          () => mockLoginUseCase(
            username: 'test_user',
            password: 'wrong_password',
            deviceId: any(named: 'deviceId'),
          ),
        ).thenThrow(AuthException('Username atau password salah'));

        return loginBloc;
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(
          username: 'test_user',
          password: 'wrong_password',
          deviceId: 'dummy_device_id',
        ),
      ),
      expect: () => [
        const LoginState(
          status: LoginStatus.loading,
          username: 'test_user',
          password: 'wrong_password',
        ),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Username atau password salah')
            .having((s) => s.error, 'error', isA<AuthException>()),
      ],
    );
  });
}
