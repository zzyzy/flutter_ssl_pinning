import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ssl_pinning/custom_http_client_adapter.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TestPageState();
}

class TestPageState extends State<TestPage> {
  late Dio dio;

  @override
  void initState() {
    super.initState();
    dio = Dio();
    dio.httpClientAdapter = CustomHttpClientAdapter();
  }

  Future testHttp() async {
    try {
      var response = await dio.get('https://www.google.com');
      // var response = await Dio().get('https://sg.yahoo.com/?p=us');
      debugPrint(response.statusCode.toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: testHttp,
            child: const Text('Test'),
          ),
        ],
      ),
    );
  }
}
