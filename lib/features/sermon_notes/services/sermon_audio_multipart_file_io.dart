import 'package:http/http.dart' as http;

Future<http.MultipartFile> sermonAudioMultipartFile(String audioPath) {
  return http.MultipartFile.fromPath('file', audioPath);
}
