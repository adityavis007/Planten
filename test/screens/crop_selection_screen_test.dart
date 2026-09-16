import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/core/router/app_router.dart';
import 'package:planten/core/theme/app_theme.dart';
import 'package:planten/l10n/app_localizations.dart';
import 'package:planten/providers/crop_provider.dart';
import 'package:planten/providers/locale_provider.dart';
import 'package:planten/screens/home/crop_selection_screen.dart';
import 'package:planten/services/local_storage_service.dart';
import 'package:planten/widgets/crop_tile_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocaleProvider localeProvider;
  late CropProvider cropProvider;
  late LocalStorageService localStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    localStorage = LocalStorageService(prefs: prefs);
    localeProvider = LocaleProvider(prefs: prefs);
    cropProvider = CropProvider(localStorageService: localStorage);
  });

  tearDown(() {
    cropProvider.dispose();
  });

  Widget buildTestableCropSelectionScreen({
    CropProvider? customCrop,
    ValueChanged<Crop>? onCropSelected,
    bool isModal = false,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<CropProvider>.value(
            value: customCrop ?? cropProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: CropSelectionScreen(
          cropProvider: customCrop ?? cropProvider,
          onCropSelected: onCropSelected,
          isModal: isModal,
        ),
      ),
    );
  }

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('CropSelectionScreen (Task 33)', () {
    testWidgets('renders all 5 V1 crop cards in 2-column grid with title and guidance',
        (tester) async {
      setPhoneViewport(tester);
      await tester.pumpWidget(buildTestableCropSelectionScreen());
      await tester.pump();

      // Screen Title & Guidance
      expect(find.text('Select Crop'), findsOneWidget);
      expect(
        find.text('Tap a crop below to set it as your active crop for diagnosis.'),
        findsOneWidget,
      );

      // All 5 V1 Crop Cards
      expect(find.byKey(const ValueKey('crop_tile_tomato')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_tile_potato')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_tile_wheat')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_tile_chili')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop_tile_cotton')), findsOneWidget);

      // Verify Tomato is initially selected
      final tomatoCardFinder = find.byKey(const ValueKey('crop_tile_tomato'));
      final CropTileCard tomatoCard = tester.widget<CropTileCard>(tomatoCardFinder);
      expect(tomatoCard.isSelected, isTrue);

      // Verify Potato is not selected
      final potatoCardFinder = find.byKey(const ValueKey('crop_tile_potato'));
      final CropTileCard potatoCard = tester.widget<CropTileCard>(potatoCardFinder);
      expect(potatoCard.isSelected, isFalse);

      // Done Button
      expect(
        find.byKey(const ValueKey('confirm_crop_selection_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping an unselected crop card updates active crop in CropProvider',
        (tester) async {
      setPhoneViewport(tester);
      await tester.pumpWidget(buildTestableCropSelectionScreen());
      await tester.pump();

      expect(cropProvider.selectedCropId, 'tomato');

      // Tap Wheat
      final wheatFinder = find.byKey(const ValueKey('crop_tile_wheat'));
      await tester.tap(wheatFinder);
      await tester.pump();

      expect(cropProvider.selectedCropId, 'wheat');
      expect(localStorage.getSelectedCrop(), 'wheat');

      // Now Wheat card is selected
      final CropTileCard wheatCard = tester.widget<CropTileCard>(wheatFinder);
      expect(wheatCard.isSelected, isTrue);
    });

    testWidgets('invokes onCropSelected callback when a crop is selected',
        (tester) async {
      setPhoneViewport(tester);
      Crop? chosenCrop;

      await tester.pumpWidget(
        buildTestableCropSelectionScreen(
          onCropSelected: (crop) {
            chosenCrop = crop;
          },
        ),
      );
      await tester.pump();

      // Tap Chili
      final chiliFinder = find.byKey(const ValueKey('crop_tile_chili'));
      await tester.tap(chiliFinder);
      await tester.pump();

      expect(chosenCrop, isNotNull);
      expect(chosenCrop!.id, 'chili');
    });

    testWidgets('pops navigation when a crop card is tapped in a pushed route',
        (tester) async {
      setPhoneViewport(tester);
      final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<CropProvider>.value(value: cropProvider),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CropSelectionScreen(
                          cropProvider: cropProvider,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open Picker
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.byType(CropSelectionScreen), findsOneWidget);

      // Tap Cotton
      final cottonFinder = find.byKey(const ValueKey('crop_tile_cotton'));
      await tester.tap(cottonFinder);
      await tester.pumpAndSettle();

      // Picker popped back to home scaffold
      expect(find.byType(CropSelectionScreen), findsNothing);
      expect(find.text('Open Picker'), findsOneWidget);
      expect(cropProvider.selectedCropId, 'cotton');
    });

    testWidgets('tapping Done button pops navigation', (tester) async {
      final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<CropProvider>.value(value: cropProvider),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CropSelectionScreen(
                          cropProvider: cropProvider,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final doneBtn = find.byKey(const ValueKey('confirm_crop_selection_button'));
      await tester.ensureVisible(doneBtn);
      await tester.tap(doneBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CropSelectionScreen), findsNothing);
    });

    testWidgets('renders close button in modal mode and dismisses on close tap',
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<CropProvider>.value(value: cropProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => CropSelectionScreen.showAsModal(
                    context,
                    cropProvider: cropProvider,
                  ),
                  child: const Text('Show Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Modal open with close button
      final closeBtn = find.byKey(const ValueKey('close_crop_selection_button'));
      expect(closeBtn, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Modal closed
      expect(find.byKey(const ValueKey('close_crop_selection_button')), findsNothing);
    });

    testWidgets('navigates via GoRouter at AppRoutes.cropSelection',
        (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.cropSelection,
        routes: [
          GoRoute(
            path: AppRoutes.cropSelection,
            builder: (context, state) => CropSelectionScreen(
              cropProvider: cropProvider,
            ),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) =>
                const Scaffold(body: Text('Home Dashboard Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
            ChangeNotifierProvider<CropProvider>.value(value: cropProvider),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CropSelectionScreen), findsOneWidget);
    });
  });
}
