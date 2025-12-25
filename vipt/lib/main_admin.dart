import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vipt/app/core/theme/app_theme.dart';
import 'package:vipt/app/core/controllers/theme_controller.dart';
import 'package:vipt/app/data/services/app_start_service.dart';
import 'app/routes/pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool envLoaded = false;
  
  // Chỉ load từ rootBundle khi không phải web (tránh lỗi 404 trên web)
  if (!kIsWeb) {
    try {
      try {
        final ByteData data = await rootBundle.load('.env');
        final String contents = String.fromCharCodes(data.buffer.asUint8List());

        final envMap = <String, String>{};
        for (var line in contents.split('\n')) {
          line = line.trim();
          if (line.isNotEmpty && !line.startsWith('#')) {
            final parts = line.split('=');
            if (parts.length == 2) {
              final key = parts[0].trim();
              final value = parts[1].trim();
              envMap[key] = value;
            }
          }
        }

        if (envMap.isNotEmpty) {
          await dotenv.load(mergeWith: envMap);
          if (dotenv.isInitialized && dotenv.env['GEMINI_API_KEY'] != null) {
            envLoaded = true;
          }
        }
      } catch (e) {
        try {
          await dotenv.load(fileName: ".env");
          if (dotenv.isInitialized && dotenv.env['GEMINI_API_KEY'] != null) {
            envLoaded = true;
          }
        } catch (e2) {
          // Ignore
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  // Cách 2: Nếu chưa load được, thử load từ file system
  if (!envLoaded && !kIsWeb) {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      List<String> possiblePaths = [
        '.env',
        'vipt/.env',
        '${Directory.current.path}/.env',
        '${Directory.current.path}/vipt/.env',
        '${appDocDir.path}/.env',
        '${appSupportDir.path}/.env',
        r'C:\Code\ViPT\ViPT\vipt\.env',
      ];

      if (Directory.current.path.contains('ViPT')) {
        final parts = Directory.current.path.split(Platform.pathSeparator);
        final viptIndex = parts.indexWhere((p) => p == 'ViPT');
        if (viptIndex != -1) {
          final basePath =
              parts.sublist(0, viptIndex + 1).join(Platform.pathSeparator);
          possiblePaths.add(
              '$basePath${Platform.pathSeparator}ViPT${Platform.pathSeparator}vipt${Platform.pathSeparator}.env');
        }
      }

      File? envFile;
      for (String path in possiblePaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            envFile = file;
            break;
          }
        } catch (e) {
          // Ignore
        }
      }

      if (envFile != null) {
        final contents = await envFile.readAsString();
        final envMap = <String, String>{};
        for (var line in contents.split('\n')) {
          line = line.trim();
          if (line.isNotEmpty && !line.startsWith('#')) {
            final parts = line.split('=');
            if (parts.length == 2) {
              final key = parts[0].trim();
              final value = parts[1].trim();
              envMap[key] = value;
            }
          }
        }

        await dotenv.load(mergeWith: envMap);
        if (dotenv.env['GEMINI_API_KEY'] != null) {
          envLoaded = true;
        }
      }
    } catch (e) {
      // Ignore
    }
  }
  if (!envLoaded && !kIsWeb) {
    try {
      final tempEnvContent =
          'GEMINI_API_KEY=AIzaSyApoPbjG5AkQmdUdod8KtAOAjovfiMInOQ\n';
      final tempFile = File('${Directory.systemTemp.path}/vipt_temp.env');
      await tempFile.writeAsString(tempEnvContent, encoding: utf8);
      await dotenv.load(fileName: tempFile.path);
      await tempFile.delete();
      envLoaded = true;
    } catch (e) {
      // Ignore
    }
  }

  await AppStartService.instance.initService();
  Get.put(ThemeController());
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    // Use Obx with minimal rebuild - only themeMode changes
    return Obx(() {
      final currentThemeMode = themeController.themeMode;

      return GetMaterialApp(
        title: 'ViPT Admin',
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
        themeMode: currentThemeMode,
        debugShowCheckedModeBanner: false,
        initialRoute: Routes.admin,
        getPages: AppPages.pages,
        defaultTransition: Transition.fadeIn,
      );
    });
  }
}
