import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../helpers/app_logger.dart';
import '../helpers/local_storage.dart';
import 'net_exception.dart';
import 'net_result.dart';
import 'network_error_handler.dart';

enum NetMethod { GET, POST, DELETE, PUT, MULTIPART, DOWNLOAD }

class Net {
  final dio = Dio();
  final String url;
  final NetMethod method;
  dynamic body;
  Map<String, String>? queryParam;
  Map<String, String>? pathParam;
  Map<String, String>? fields;
  Map<String, String>? imagePathList;
  Map<String, String>? headers;
  bool excludeToken;
  final int _retryMaxCount = 3;
  int _retryCount = 0;
  bool isRetryEnable = false;
  ProgressCallback? onSendProgress;
  ProgressCallback? onReceiveProgress;
  String? _TOKEN;

  Net({
    required this.url,
    required this.method,
    this.queryParam,
    this.pathParam,
    this.fields,
    this.imagePathList,
    this.headers,
    this.excludeToken = false,
  });

  Future<Result> perform() async {
    Response response;
    switch (method) {
      case NetMethod.GET:
        response = await get();
        break;
      case NetMethod.POST:
        response = await post();
        break;
      case NetMethod.PUT:
        response = await put();
        break;
      case NetMethod.DELETE:
        response = await delete();
        break;
      case NetMethod.MULTIPART:
        response = await multiPart();
        break;
      case NetMethod.DOWNLOAD:
        response = await download();
        break;
    }

    return await isOk(response);
  }

  Future<Response> get() async {
    Log.debug("request - GET | url - $url | ");
    String url_ = getPathParameters(url);
    var headers = await getHeadersForRequest();
    Log.debug("request - GET | url - $url_ | headers - ${headers.toString()}");
    final response = await dio.get(url_,
        queryParameters: queryParam, options: Options(headers: headers));

    Log.debug(
        "response - GET | url - $url_ | body - ${response.data}| headers - ${response.headers.toString()}");
    return response;
  }

  Future<Response> post() async {
    String url_ = getPathParameters(url);

    var headers = await getHeadersForRequest();
    Log.debug("request - POST | url - $url_ | headers - $headers");

    final response = await dio.post(
      url_,
      queryParameters: queryParam,
      options: Options(headers: headers),
      data: body == null ? null : jsonEncode(body),
    );

    Log.debug(
        "response - POST | url - $url_ | body - ${response.data}| headers - ${response.headers}");

    return response;
  }

  Future<Response> put() async {
    String url_ = getPathParameters(url);
    var headers = await getHeadersForRequest();

    Log.debug("request - PUT | url - $url_ | headers - ${headers.toString()}");
    final response = await dio.put(
      url_,
      queryParameters: queryParam,
      options: Options(headers: headers),
      data: body == null ? null : jsonEncode(body),
    );
    Log.debug(
        "response - PUT | url - $url_ | body - ${response.data}| headers - ${response.headers}");
    return response;
  }

  Future<Response> delete() async {
    String url_ = "${getPathParameters(url)}}";
    var headers = await getHeadersForRequest();

    Log.debug(
        "request - DELETE | url - $url_ | headers - ${headers.toString()}");

    final response = await dio.delete(
      url_,
      queryParameters: queryParam,
      options: Options(headers: headers),
      data: body == null ? null : jsonEncode(body),
    );

    Log.debug(
        "response - DELETE | url - $url_ | body - ${response.data}| headers - ${response.headers}");
    return response;
  }

  Future<Response> multiPart() async {
    String url_ = getPathParameters(url);
    var headers = await getHeadersForRequest();
    final formData = FormData.fromMap({});

    Log.debug(
        "request - MULTIPART | url - $url_ | headers - ${headers.toString()}");

    if (fields != null) {
      formData.fields.addAll(fields!.entries);
    }

    if (imagePathList != null) {
      for (final imagePath in imagePathList!.entries) {
        MultipartFile multipartFile =
            await MultipartFile.fromFile(imagePath.value);
        formData.files.addAll({imagePath.key: multipartFile}.entries);
      }
    }

    final response = await dio.post(url_,
        queryParameters: queryParam,
        options: Options(headers: headers),
        data: formData,
        onSendProgress: onSendProgress);
    Log.debug(
        "response - POST | url - $url_ | body - ${response.data}| headers - ${response.headers}");

    return response;
  }

  Future<Response> download() async {
    String url_ = getPathParameters(url);
    var headers = await getHeadersForRequest();

    Log.debug(
        "request - DOWNLOAD | url - $url_ | headers - ${headers.toString()}");

    final response = await dio.download(
      url_,
      'path',
      queryParameters: queryParam,
      onReceiveProgress: onReceiveProgress,
      options: Options(headers: headers),
    );
    Log.debug(
        "response - DOWNLOAD | url - $url_ | body - ${response.data}| headers - ${response.headers}");

    return response;
  }

  Future<Map<String, String>> getHeadersForRequest() async {
    headers ??= {};
    if (_TOKEN != null || _TOKEN != "") {
      Log.debug("token get from local");
      _TOKEN = await LocalStorage().getUserToken();
    }
    if (_TOKEN != null &&
        !headers!.containsKey(HttpHeaders.authorizationHeader) &&
        !excludeToken) {
      Log.debug("token set to headers");
      headers!.putIfAbsent(HttpHeaders.authorizationHeader, () => _TOKEN ?? '');
    }
    headers!.putIfAbsent("Content-Type", () => "application/json");
    headers!.putIfAbsent("Accept", () => "application/json");
    return headers!;
  }

  String getPathParameters(String netUrl) {
    String url = netUrl;
    pathParam ??= {};
    if (pathParam!.isNotEmpty) {
      pathParam!.forEach((key, value) {
        url = url.replaceFirst(key, value);
        Log.debug("$key path param replaced");
      });
    }
    return url;
  }

  Future<Result> isOk(Response response) async {
    Result result = Result();
    result.statusCode = response.statusCode;
    result.net = this;
    result.token = "${response.headers['authorization']}";

    NetException? netException = NetworkErrorHandler.handleError(response);
    if (netException != null) {
      Log.err("error found");
      if (!isRetryEnable) {
        try {
          Log.err("network error ${response.statusCode} recorded in firebase!");
        } catch (err) {}
        Log.debug("retry disabled!");
        result.exception = netException;
        return result;
      }
      if (_retryCount >= _retryMaxCount) {
        try {
          Log.err("network error ${netException.code} recorded in firebase!");
        } catch (err) {}
        Log.err("retry failed!");
        result.exception = netException;
        return result;
      }

      _retryCount++;
      Log.debug("retry again.. $_retryCount time");
      return await result.net!.perform();
    }

    result.result = response.data;
    return result;
  }

  Future<String> processUrl() async {
    return "${getPathParameters(url)}?${Uri(queryParameters: queryParam).query}";
  }

  // recordError(http.Response response, Result result) async {
  //   if (result.net != null) {
  //     await FirebaseCrashlytics.instance
  //         .setCustomKey(result.net!.url, response.body);

  //     await FirebaseCrashlytics.instance
  //         .log("${result.net!.url} --- ${response.body}");

  //     await FirebaseCrashlytics.instance.recordError(
  //         "SERVER ERROR ${response.statusCode}",
  //         StackTrace.fromString(response.body));
  //   }
  // }
}
