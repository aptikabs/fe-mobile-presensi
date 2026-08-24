import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../../api/urls.dart';
import '../../../../../core/error/exceptions.dart';
import '../models/notification_config_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationConfigModel>> getNotificationConfigs();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final http.Client client;
  static const _timeout = Duration(seconds: 30);

  NotificationRemoteDataSourceImpl({required this.client});

  @override
  Future<List<NotificationConfigModel>> getNotificationConfigs() async {
    try {
      final response = await client
          .get(
            Uri.parse(Urls.notification),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        if (jsonMap['success'] == true) {
          final List<dynamic> data = jsonMap['data'];
          return data
              .map((e) => NotificationConfigModel.fromJson(e))
              .toList();
        } else {
          throw ServerException();
        }
      } else {
        throw ServerException();
      }
    } on SocketException {
      throw NetworkException(type: NetworkErrorType.noConnection);
    } on TimeoutException {
      throw NetworkException(type: NetworkErrorType.timeout);
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        type: NetworkErrorType.unknown,
        message: e.toString(),
      );
    }
  }
}
