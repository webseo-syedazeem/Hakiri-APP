/// Hakkiri backend on Vercel. Secrets like GEMINI_API_KEY stay on the server.
class ApiConfig {
  static const String baseUrl = 'https://backend-deploy-seven-mauve.vercel.app';
  static const String apiPrefix = '/api';

  static Uri api(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$apiPrefix$normalized');
  }
}
