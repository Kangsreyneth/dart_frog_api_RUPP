import 'package:dotenv/dotenv.dart';

class Env {
  Env._();

  static final DotEnv _env = DotEnv(includePlatformEnvironment: true)..load();

  static String get mongoUri =>
      _env['MONGO_URI'] ?? 'mongodb://localhost:27017/phsardrop';
  static String get jwtSecret =>
      _env['JWT_SECRET'] ?? 'change-me-in-production';
  static String get anthropicKey => _env['ANTHROPIC_API_KEY'] ?? '';
  static String get chatbotModel =>
      _env['CHATBOT_MODEL'] ?? 'claude-haiku-4-5-20251001';
}
