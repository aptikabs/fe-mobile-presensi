import 'package:epresensi_mobile/features/attendance/presentation/bloc/attendance_cubit.dart';
import 'package:epresensi_mobile/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:epresensi_mobile/features/attendance/domain/usecases/submit_attendance.dart';
import 'package:epresensi_mobile/core/services/gps_snapshot_service.dart';
import 'package:epresensi_mobile/core/services/face_recognition_service.dart';
import 'package:epresensi_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:epresensi_mobile/features/auth/domain/entities/employee_detail.dart';
import 'package:epresensi_mobile/features/auth/domain/entities/login_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSubmitAttendance extends Mock implements SubmitAttendance {}

class MockGPSSnapshotService extends Mock implements GPSSnapshotService {}

class MockFaceRecognitionService extends Mock
    implements FaceRecognitionService {}

class MockGeolocatorPlatform extends Mock 
    with MockPlatformInterfaceMixin 
    implements GeolocatorPlatform {}

void main() {
  late AttendanceCubit attendanceCubit;
  late MockSubmitAttendance mockSubmitAttendance;
  late MockGPSSnapshotService mockGpsSnapshotService;
  late MockFaceRecognitionService mockFaceRecognitionService;
  late MockGeolocatorPlatform mockGeolocatorPlatform;

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

  setUp(() {
    mockSubmitAttendance = MockSubmitAttendance();
    mockGpsSnapshotService = MockGPSSnapshotService();
    mockFaceRecognitionService = MockFaceRecognitionService();
    mockGeolocatorPlatform = MockGeolocatorPlatform();
    
    // Inject Mock Geolocator Platform
    GeolocatorPlatform.instance = mockGeolocatorPlatform;

    attendanceCubit = AttendanceCubit(
      user: tUserEntity,
      submitAttendanceUseCase: mockSubmitAttendance,
      gpsSnapshotService: mockGpsSnapshotService,
      faceRecognitionService: mockFaceRecognitionService,
    );
  });

  tearDown(() {
    attendanceCubit.close();
  });

  group('AttendanceCubit initialize', () {
    test('initial state is AttendanceInitial', () {
      expect(attendanceCubit.state, isA<AttendanceInitial>());
    });

    blocTest<AttendanceCubit, AttendanceState>(
      'emits [AttendanceLoading, AttendanceError] when location service is disabled',
      build: () {
        when(() => mockFaceRecognitionService.loadModel())
            .thenAnswer((_) async {});
        when(() => mockGeolocatorPlatform.isLocationServiceEnabled())
            .thenAnswer((_) async => false);
        return attendanceCubit;
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [
        isA<AttendanceLoading>(),
        const AttendanceError('Layanan lokasi tidak aktif. Mohon aktifkan GPS Anda.'),
      ],
    );

    blocTest<AttendanceCubit, AttendanceState>(
      'emits [AttendanceLoading, AttendancePermissionRequired] when location permission denied',
      build: () {
        when(() => mockFaceRecognitionService.loadModel())
            .thenAnswer((_) async {});
        when(() => mockGeolocatorPlatform.isLocationServiceEnabled())
            .thenAnswer((_) async => true);
        when(() => mockGeolocatorPlatform.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        return attendanceCubit;
      },
      act: (cubit) => cubit.initialize(),
      expect: () => [
        isA<AttendanceLoading>(),
        isA<AttendancePermissionRequired>(),
      ],
    );
  });
}
