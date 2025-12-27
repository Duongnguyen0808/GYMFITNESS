import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vipt/app/core/theme/app_theme.dart';
import 'package:vipt/app/data/services/app_start_service.dart';
import 'app/routes/pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file từ assets (đã thêm vào pubspec.yaml)
  try {
    await dotenv.load(fileName: ".env");
    if (kDebugMode) {
      print('✅ Đã load .env thành công');
      print(
          '📌 GEMINI_API_KEY: ${dotenv.env['GEMINI_API_KEY'] != null ? 'Có' : 'Không có'}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Không thể load .env: $e');
      print('📌 Vui lòng tạo file .env với GEMINI_API_KEY');
    }
  }

  await AppStartService.instance.initService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: Routes.splash,
      debugShowCheckedModeBanner: false,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
    );
  }
}
