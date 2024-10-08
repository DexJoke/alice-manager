library alice_get_connect;

import 'dart:async';
import 'dart:convert';

import 'package:alice_manager/core/alice_adapter.dart';
import 'package:alice_manager/model/alice_form_data_file.dart';
import 'package:alice_manager/model/alice_from_data_field.dart';
import 'package:alice_manager/model/alice_http_call.dart';
import 'package:alice_manager/model/alice_http_error.dart';
import 'package:alice_manager/model/alice_http_request.dart';
import 'package:alice_manager/model/alice_http_response.dart';
import 'package:collection/collection.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:get/get_connect/http/src/response/response.dart';

class GetConnectInterceptor with AliceAdapter {
  final Duration timeout = const Duration(seconds: 30);

  FutureOr<Request> requestInterceptor(Request request) async {
    request.headers['date'] = DateTime.now().toString();
    final AliceHttpCall call = AliceHttpCall(request.hashCode);
    call.method = request.method;
    call.endpoint = request.url.path;
    call.server = request.url.host;
    call.client = "Get Connect";
    if (request.url.scheme.contains("https")) {
      call.secure = true;
    }
    final AliceHttpRequest aliceHttpRequest = AliceHttpRequest();

    aliceHttpRequest.size = request.contentLength ?? 0;
    aliceHttpRequest.body = await request.getBody();
    if (aliceHttpRequest.body == 'Form Data') {
      final listFormData = await request.toListFormData();
      aliceHttpRequest.formDataFields =
          listFormData.whereType<AliceFormDataField>().toList();
      aliceHttpRequest.formDataFiles =
          listFormData.whereType<AliceFormDataFile>().toList();
    }

    aliceHttpRequest.time = DateTime.now();
    aliceHttpRequest.headers = request.headers;

    String? contentType = "unknown";
    if (request.headers.containsKey("Content-Type")) {
      contentType = request.headers["Content-Type"];
    }
    aliceHttpRequest.contentType = contentType;
    aliceHttpRequest.queryParameters = request.url.queryParameters;

    call.request = aliceHttpRequest;
    call.response = AliceHttpResponse();

    aliceCore.addCall(call);

    // HANDLE REQUEST TIMEOUT
    Future.delayed(timeout).then((value) {
      final callSelected = _selectCall(request.id);
      //WHEN STILL WAITING FOR REQUEST
      if (callSelected != null && callSelected.loading) {
        aliceCore.addResponse(AliceHttpResponse(), request.id);
        aliceCore.addError(
          AliceHttpError()..error = 'Connection Timeout!',
          request.id,
        );
      }
    });

    return request;
  }

  FutureOr responseInterceptor(Request request, Response response) {
    final httpResponse = AliceHttpResponse();
    httpResponse.status = response.statusCode ?? 0;
    if (response.body == null) {
      httpResponse.body = "";
      httpResponse.size = 0;
    } else {
      httpResponse.body = response.body;
      httpResponse.size = utf8.encode(response.body.toString()).length;
    }
    httpResponse.time = DateTime.now();
    final Map<String, String> headers = {};
    response.headers?.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    aliceCore.addResponse(httpResponse, request.hashCode);

    return response;
  }

  AliceHttpCall? _selectCall(int requestId) {
    return aliceCore.getCalls().firstWhereOrNull((call) {
      return call.id == requestId;
    });
  }
}

extension GetConnectRequestX on Request {
  Future<String?> getBody() async {
    if (method.toLowerCase() == 'post') {
      if (contentType.contains('multipart/form-data')) {
        return 'Form Data';
      } else {
        return utf8.decode(await bodyBytes.toBytes());
      }
    }
    return '';
  }

  String get contentType {
    return headers['content-type'] ?? '';
  }

  String get boundary {
    final List<String> parts = contentType.split(";");
    for (final String part in parts) {
      if (part.trim().startsWith("boundary=")) {
        final String boundary =
            part.trim().substring("boundary=".length).trim();
        return boundary;
      }
    }

    return "";
  }

  int get id {
    int hashCodeSum = 0;
    hashCodeSum += url.hashCode;
    hashCodeSum += method.hashCode;
    if (headers.isNotEmpty) {
      headers.forEach((key, value) {
        hashCodeSum += key.hashCode;
        hashCodeSum += value.hashCode;
      });
    }
    if (contentLength != null) {
      hashCodeSum += contentLength.hashCode;
    }

    return hashCodeSum.hashCode;
  }

  Future<List<dynamic>> toListFormData() async {
    final List<dynamic> formDataList = [];
    if (boundary.isNotEmpty) {
      final separator = '--$boundary\r\n';
      final close = '--$boundary--\r\n';
      final data = utf8.decode(await bodyBytes.toBytes(), allowMalformed: true);
      final clearData = data.replaceAll(close, '');
      final inputList = clearData.split(separator).toList();

      for (final String inputString in inputList) {
        if (inputString.contains('content-disposition: form-data')) {
          if (inputString.contains('filename')) {
            final List<String> parts =
                inputString.split('\r\n').where((e) => e.isNotEmpty).toList();
            if (parts.length >= 2) {
              final String stringContainFileName = parts[0];
              final String stringContainContentType = parts[1];
              final String content = parts[2];
              String fileName = '';
              String contentType = '';

              final RegExp regexFn = RegExp('filename="([^"]+)"');
              final Match? matchFn = regexFn.firstMatch(stringContainFileName);
              if (matchFn != null) {
                fileName = matchFn.group(1)!;
              }

              final RegExp regexCt = RegExp('content-type: ([^ ]+)');
              final Match? matchCt =
                  regexCt.firstMatch(stringContainContentType);
              if (matchCt != null) {
                contentType = matchCt.group(1)!;
              }

              if (fileName.isNotEmpty && contentType.isNotEmpty) {
                formDataList.add(
                  AliceFormDataFile(fileName, contentType, content.length),
                );
              }
            }
          } else if (inputString.contains('name')) {
            final List<String> parts =
                inputString.split('\r\n').where((e) => e.isNotEmpty).toList();
            if (parts.length >= 2) {
              final String stringContainName = parts[0];
              final String value = parts[1];
              String name = '';

              final RegExp regex = RegExp('name="([^"]+)"');
              final Match? match = regex.firstMatch(stringContainName);
              if (match != null) {
                name = match.group(1)!;
              }

              if (name.isNotEmpty && value.isNotEmpty) {
                formDataList.add(AliceFormDataField(name, value));
              }
            }
          }
        }
      }
    }
    return formDataList;
  }
}
