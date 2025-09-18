import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

http.Client buildHttpClient() {
  final client = BrowserClient()..withCredentials = true;
  return client;
}
