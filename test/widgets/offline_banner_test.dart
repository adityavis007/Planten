import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/services/network_monitor_service.dart';
import 'package:planten/widgets/offline_banner.dart';

class MockConnectivity implements Connectivity {
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast(sync: true);
  List<ConnectivityResult> currentResults = [ConnectivityResult.wifi];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => currentResults;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void emit(List<ConnectivityResult> results) {
    currentResults = results;
    _controller.add(results);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;
  late MockConnectivity mockConnectivity;
  late NetworkMonitorService networkMonitorService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localeProvider = LocaleProvider(prefs: prefs);
    mockConnectivity = MockConnectivity();
    networkMonitorService =
        NetworkMonitorService(connectivity: mockConnectivity);
    await networkMonitorService.initialize();
  });

  tearDown(() {
    networkMonitorService.dispose();
    mockConnectivity.dispose();
  });

  Widget buildTestableOfflineBanner({
    NetworkMonitorService? service,
    bool? isOnlineOverride,
    bool isPill = true,
    String? customMessage,
    Locale locale = const Locale('en'),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: Column(
            children: [
              OfflineBanner(
                networkMonitorService: service,
                isOnlineOverride: isOnlineOverride,
                isPill: isPill,
                customMessage: customMessage,
                animationDuration: Duration.zero,
              ),
              const Expanded(child: Center(child: Text('Main Content'))),
            ],
          ),
        ),
      ),
    );
  }

  group('OfflineBanner (Task 54) Unit & Widget Tests', () {
    testWidgets('remains hidden when isOnline is true', (tester) async {
      await tester.pumpWidget(
        buildTestableOfflineBanner(isOnlineOverride: true),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('offline_banner_container')), findsNothing);
      expect(find.text(OfflineBanner.defaultMessageEn), findsNothing);
    });

    testWidgets('renders compact amber pill and default English message when offline',
        (tester) async {
      await tester.pumpWidget(
        buildTestableOfflineBanner(isOnlineOverride: false, isPill: true),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('offline_banner_container')), findsOneWidget);
      expect(find.byKey(const Key('offline_banner_pill')), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text(OfflineBanner.defaultMessageEn), findsOneWidget);
    });

    testWidgets('renders Vernacular Hindi message when locale is Hindi',
        (tester) async {
      await localeProvider.setLocale(const Locale('hi'));
      await tester.pumpWidget(
        buildTestableOfflineBanner(
          isOnlineOverride: false,
          locale: const Locale('hi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('offline_banner_container')), findsOneWidget);
      expect(find.text(OfflineBanner.defaultMessageHi), findsOneWidget);
    });

    testWidgets('renders full-width strip variant when isPill is false',
        (tester) async {
      await tester.pumpWidget(
        buildTestableOfflineBanner(isOnlineOverride: false, isPill: false),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('offline_banner_container')), findsOneWidget);
      expect(find.byKey(const Key('offline_banner_strip')), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text(OfflineBanner.defaultMessageEn), findsOneWidget);
    });

    testWidgets('renders custom message if provided', (tester) async {
      const customText = 'Custom Network Alert';
      await tester.pumpWidget(
        buildTestableOfflineBanner(
          isOnlineOverride: false,
          customMessage: customText,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(customText), findsOneWidget);
    });

    testWidgets('reactively appears when disconnected and disappears when restored via NetworkMonitorService',
        (tester) async {
      // Initially online
      expect(networkMonitorService.isOnline, isTrue);

      await tester.pumpWidget(
        buildTestableOfflineBanner(service: networkMonitorService),
      );
      await tester.pumpAndSettle();

      // Banner should be hidden
      expect(find.byKey(const Key('offline_banner_container')), findsNothing);

      // Transition to offline (None)
      await tester.runAsync(() async {
        mockConnectivity.emit([ConnectivityResult.none]);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(networkMonitorService.isOnline, isFalse);
      expect(find.byKey(const Key('offline_banner_container')), findsOneWidget);
      expect(find.text(OfflineBanner.defaultMessageEn), findsOneWidget);

      // Reconnect to WiFi
      await tester.runAsync(() async {
        mockConnectivity.emit([ConnectivityResult.wifi]);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(networkMonitorService.isOnline, isTrue);
      expect(find.byKey(const Key('offline_banner_container')), findsNothing);
    });
  });
}
