import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../network/network_info.dart';

/// Possible connectivity states.
enum ConnectivityStatus { connected, disconnected }

/// Cubit that monitors real-time network connectivity status.
///
/// Listens to [NetworkInfo.onConnectivityChanged] and emits
/// [ConnectivityStatus.connected] or [ConnectivityStatus.disconnected].
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  final NetworkInfo _networkInfo;
  StreamSubscription<bool>? _subscription;

  ConnectivityCubit({required NetworkInfo networkInfo})
    : _networkInfo = networkInfo,
      super(ConnectivityStatus.connected) {
    _init();
  }

  Future<void> _init() async {
    // Check initial status
    final isConnected = await _networkInfo.isConnected;
    emit(
      isConnected
          ? ConnectivityStatus.connected
          : ConnectivityStatus.disconnected,
    );

    // Listen for changes
    _subscription = _networkInfo.onConnectivityChanged.listen((isConnected) {
      emit(
        isConnected
            ? ConnectivityStatus.connected
            : ConnectivityStatus.disconnected,
      );
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
