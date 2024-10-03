import 'dart:convert';

import 'package:alice_manager/core/alice_adapter.dart';
import 'package:alice_manager/model/alice_form_data_file.dart';
import 'package:alice_manager/model/alice_from_data_field.dart';
import 'package:alice_manager/model/alice_http_call.dart';
import 'package:alice_manager/model/alice_http_error.dart';
import 'package:alice_manager/model/alice_http_request.dart';
import 'package:alice_manager/model/alice_http_response.dart';
import 'package:dio/dio.dart';

class DioInterceptor extends InterceptorsWrapper with AliceAdapter {
  /// Handles dio request and creates alice http call based on it
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final AliceHttpCall call = AliceHttpCall(options.hashCode);

    final Uri uri = options.uri;
    call.method = options.method;
    var path = options.uri.path;
    if (path.isEmpty) {
      path = "/";
    }
    call.endpoint = path;
    call.server = uri.host;
    call.client = "Dio";
    call.uri = options.uri.toString();

    if (uri.scheme == "https") {
      call.secure = true;
    }

    final AliceHttpRequest request = AliceHttpRequest();

    final dynamic data = options.data;
    if (data == null) {
      request.size = 0;
      request.body = "";
    } else {
      if (data is FormData) {
        request.body += "Form data";

        if (data.fields.isNotEmpty == true) {
          final List<AliceFormDataField> fields = [];
          for (var entry in data.fields) {
            fields.add(AliceFormDataField(entry.key, entry.value));
          }
          request.formDataFields = fields;
        }
        if (data.files.isNotEmpty == true) {
          final List<AliceFormDataFile> files = [];
          for (var entry in data.files) {
            files.add(
              AliceFormDataFile(
                entry.value.filename,
                entry.value.contentType.toString(),
                entry.value.length,
              ),
            );
          }

          request.formDataFiles = files;
        }
      } else {
        request.size = utf8.encode(data.toString()).length;
        request.body = data;
      }
    }

    request.time = DateTime.now();
    request.headers =
        options.headers.map((key, value) => MapEntry(key, value.toString()));
    request.contentType = options.contentType.toString();
    request.queryParameters = options.queryParameters;

    call.request = request;
    call.response = AliceHttpResponse();

    aliceCore.addCall(call);
    handler.next(options);
  }

  /// Handles dio response and adds data to alice http call
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final httpResponse = AliceHttpResponse();
    httpResponse.status = response.statusCode;

    if (response.data == null) {
      httpResponse.body = "";
      httpResponse.size = 0;
    } else {
      httpResponse.body = response.data;
      httpResponse.size = utf8.encode(response.data.toString()).length;
    }

    httpResponse.time = DateTime.now();
    final Map<String, String> headers = {};
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    aliceCore.addResponse(httpResponse, response.requestOptions.hashCode);
    handler.next(response);
  }

  /// Handles error and adds data to alice http call
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final httpError = AliceHttpError();
    httpError.error = error.toString();
    if (error is Error) {
      final basicError = error as Error;
      httpError.stackTrace = basicError.stackTrace;
    }

    aliceCore.addError(httpError, error.requestOptions.hashCode);
    final httpResponse = AliceHttpResponse();
    httpResponse.time = DateTime.now();
    if (error.response == null) {
      httpResponse.status = -1;
      aliceCore.addResponse(httpResponse, error.requestOptions.hashCode);
    } else {
      httpResponse.status = error.response!.statusCode;

      if (error.response!.data == null) {
        httpResponse.body = "";
        httpResponse.size = 0;
      } else {
        httpResponse.body = error.response!.data;
        httpResponse.size = utf8.encode(error.response!.data.toString()).length;
      }
      final Map<String, String> headers = {};
      error.response!.headers.forEach((header, values) {
        headers[header] = values.toString();
      });
      httpResponse.headers = headers;
      aliceCore.addResponse(
        httpResponse,
        error.response!.requestOptions.hashCode,
      );
    }
    handler.next(error);
  }
}
