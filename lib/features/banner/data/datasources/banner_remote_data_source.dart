import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../../../api/urls.dart';
import '../../../../../core/error/exceptions.dart';
import '../models/banner_model.dart';

abstract class BannerRemoteDataSource {
  Future<List<BannerModel>> getBanners();
}

class BannerRemoteDataSourceImpl implements BannerRemoteDataSource {
  final http.Client client;
  static const _timeout = Duration(seconds: 30);

  BannerRemoteDataSourceImpl({required this.client});

  @override
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await client
          .get(
            Uri.parse(Urls.banner),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => BannerModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch banners: ${response.reasonPhrase}',
        );
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
