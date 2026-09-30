import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

import 'app_coordinator.dart';
import 'demo_widgets.dart';

/// Base route target for the cupping studio.
abstract class AppRoute extends RouteTarget with RouteUnique {}

/// Shell layout holding the persistent bottom tabs.
class StudioLayoutRoute extends AppRoute with RouteLayout<AppRoute> {
  @override
  StackPath<AppRoute> resolvePath(covariant AppCoordinator coordinator) =>
      coordinator.tabs;

  @override
  Uri toUri() => Uri(path: '/');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => FeatureTabs(
    coordinator: coordinator,
    path: coordinator.tabs,
    labels: const ["Today's Lots", 'Cupping Log'],
  );
}

/// The daily tasting table listing green and roasted samples.
class ShelfRoute extends AppRoute {
  @override
  Type get layout => StudioLayoutRoute;

  @override
  Uri toUri() => Uri(path: '/shelf');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      const ShelfScreen();
}

class ShelfScreen extends StatefulWidget {
  const ShelfScreen({super.key});

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  String? _lastScore;
  String? _lastScoredLot;

  @override
  Widget build(BuildContext context) {
    final coordinator = CoordinatorScope.of<AppRoute>(context);
    return StudioPage(
      title: 'Cupping Table',
      eyebrow: "Today's Selection",
      children: [
        if (_lastScore != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              color: cardColor,
              borderRadius: 14,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.star_fill, color: roastAmber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evaluated: $_lastScoredLot',
                          style: const TextStyle(
                            color: ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Score awarded: $_lastScore pts',
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const StudioCard(
            title: 'Morning Tasting Session',
            subtitle:
                'Select a coffee lot to evaluate aroma, flavor, and acidity, or view pour-over parameters.',
            children: [
              Text(
                'Three single-origin arrivals are ready for cupping on the table today.',
                style: TextStyle(color: muted, fontSize: 14),
              ),
            ],
          ),
        for (final lot in coffeeLots) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final score = await coordinator.push<String>(LotRoute(lot.id));
                if (mounted && score != null) {
                  setState(() {
                    _lastScore = score;
                    _lastScoredLot = lot.name;
                  });
                }
              },
              child: Card(
                color: cardColor,
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: coffee,
                          child: Center(
                            child: Text(
                              lot.origin.substring(0, 1),
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lot.name,
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${lot.origin} · ${lot.process} · ${lot.elevation}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(CupertinoIcons.chevron_right, color: muted),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lot.flavorNotes,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    action('Taste & Evaluate', () async {
                      final score = await coordinator.push<String>(
                        LotRoute(lot.id),
                      );
                      if (mounted && score != null) {
                        setState(() {
                          _lastScore = score;
                          _lastScoredLot = lot.name;
                        });
                      }
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Detailed overview for a single coffee lot.
class LotRoute extends AppRoute {
  LotRoute(this.id);

  final String id;

  CoffeeLot get lot => lotById(id);

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri(pathSegments: ['lot', id]);

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      StudioPage(
        title: lot.name,
        eyebrow: '${lot.origin} · ${lot.process}',
        children: [
          StudioCard(
            title: 'Origin & Terroir',
            subtitle: 'Elevation: ${lot.elevation} · Variety: ${lot.variety}',
            children: [
              Text(
                lot.roasterNotes,
                style: const TextStyle(color: ink, height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: paper,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.flame_fill, color: roastAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Key notes: ${lot.flavorNotes}',
                        style: const TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          StudioCard(
            title: 'Cupping & Service',
            subtitle: 'Evaluate lot quality or inspect the bar recipe.',
            children: [
              action('Evaluate & Score Lot', () async {
                final score = await coordinator.push<String>(
                  CuppingRoute(lotId: id),
                );
                if (score != null) {
                  coordinator.pop(score);
                }
              }),
              const SizedBox(height: 6),
              action(
                'View Pour-over Recipe',
                () => unawaited(coordinator.push(BrewGuideRoute(lotId: id))),
                secondary: true,
              ),
            ],
          ),
        ],
      );
}

/// Scenario 1: Modal Dialog route powered by [ExperimentalDialogPresentation].
class ConfirmDiscardDialogRoute extends AppRoute {
  ConfirmDiscardDialogRoute({this.lotName});

  final String? lotName;

  @override
  List<Object?> get props => [lotName];

  @override
  Presentation get presentation =>
      const ExperimentalDialogPresentation(cornerRadius: 18, dimOpacity: 0.35);

  @override
  Uri toUri() => Uri(path: '/dialog/confirm-discard');

  @override
  Widget build(
    Coordinator<AppRoute> coordinator,
    BuildContext context,
  ) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discard ${lotName ?? 'Lot'} Score?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your sensory evaluation has not been saved. Discard and return to lot details?',
            style: TextStyle(color: muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: action(
                  'Keep Editing',
                  () => coordinator.pop(false),
                  secondary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: action('Discard', () => coordinator.pop(true))),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Guarded cupping form. Demonstrates both confirmation scenarios on Back:
/// 1. Route Dialog (ExperimentalDialogPresentation)
/// 2. Native Alert (showAlert)
class CuppingRoute extends AppRoute with RouteGuard {
  CuppingRoute({this.lotId});

  final String? lotId;
  final _committed = ValueNotifier<bool>(false);
  final _score = ValueNotifier<double>(86.5);
  int confirmStyle = 0; // 0: Route Dialog, 1: Native Alert
  BuildContext? mountedContext;

  CoffeeLot get lot => lotById(lotId ?? 'yirga');

  @override
  List<Object?> get props => [lotId];

  @override
  Uri toUri() => Uri(
    path: '/cupping',
    queryParameters: {?lotId == null ? null : 'lot': lotId},
  );

  @override
  bool get canPop => _committed.value;

  @override
  ListenableMixin get canPopListenable => _committed.toListenableMixin();

  @override
  Future<bool> popGuardWith(covariant CoordinatorCore coordinator) async {
    if (_committed.value) return true;

    bool allowLeave = false;
    if (confirmStyle == 0 && coordinator is Coordinator<AppRoute>) {
      // Scenario 1: Router-managed modal Dialog route
      final discard = await coordinator.push<bool>(
        ConfirmDiscardDialogRoute(lotName: lot.name),
      );
      allowLeave = discard == true;
    } else if (mountedContext != null) {
      // Scenario 2: Native platform popup dialog (UIAlertController / AlertDialog)
      final choice = await showAlert(
        context: mountedContext!,
        title: 'Discard ${lot.name} Score?',
        message:
            'Your sensory score has not been saved yet. Discard evaluation and return?',
        actions: const ['Keep Editing', 'Discard'],
      );
      allowLeave = choice == 1;
    }

    if (allowLeave) {
      _committed.value = true;
      return true;
    }
    return false;
  }

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      CuppingScreen(route: this);
}

class CuppingScreen extends StatefulWidget {
  const CuppingScreen({super.key, required this.route});

  final CuppingRoute route;

  @override
  State<CuppingScreen> createState() => _CuppingScreenState();
}

class _CuppingScreenState extends State<CuppingScreen> {
  @override
  Widget build(BuildContext context) {
    widget.route.mountedContext = context;
    final coffee = widget.route.lot;
    final coordinator = CoordinatorScope.of<AppRoute>(context);

    return StudioPage(
      title: 'Cupping Scorecard',
      eyebrow: coffee.name,
      children: [
        StudioCard(
          title: 'Sensory Score',
          subtitle:
              'Adjust score with the slider. Changes are protected until committed.',
          children: [
            Center(
              child: ValueListenableBuilder<double>(
                valueListenable: widget.route._score,
                builder: (_, value, _) => Column(
                  children: [
                    Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    Text(
                      value >= 85.0
                          ? 'Specialty Grade · Excellent'
                          : 'Specialty Grade · Very Good',
                      style: const TextStyle(
                        color: scoreGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: widget.route._score.value,
              min: 75,
              max: 95,
              divisions: 40,
              onChanged: (value) =>
                  setState(() => widget.route._score.value = value),
            ),
          ],
        ),
        StudioCard(
          title: 'Back Confirmation Dialog',
          subtitle:
              'Choose which dialog appears when pressing Back before saving:',
          children: [
            SegmentedControl(
              segments: const ['Dialog Route', 'Native Alert'],
              selectedIndex: widget.route.confirmStyle,
              onValueChanged: (index) {
                setState(() => widget.route.confirmStyle = index);
              },
            ),
            const SizedBox(height: 10),
            Text(
              widget.route.confirmStyle == 0
                  ? '• Scenario 1: Router-managed modal Dialog route using ExperimentalDialogPresentation.'
                  : '• Scenario 2: Native platform popup dialog using showAlert() (UIAlertController on iOS).',
              style: const TextStyle(color: muted, fontSize: 13, height: 1.3),
            ),
          ],
        ),
        action('Save & Record Score', () {
          widget.route._committed.value = true;
          coordinator.pop(widget.route._score.value.toStringAsFixed(1));
        }),
        action('Discard Evaluation', () {
          coordinator.pop();
        }, secondary: true),
      ],
    );
  }
}

/// Modal bottom sheet presenting a pour-over brew guide.
class BrewGuideRoute extends AppRoute {
  BrewGuideRoute({required this.lotId});

  final String lotId;

  @override
  List<Object?> get props => [lotId];

  @override
  Presentation get presentation =>
      const ExperimentalModalSheetPresentation(detent: SheetDetent.medium);

  @override
  Uri toUri() => Uri(path: '/brew', queryParameters: {'lot': lotId});

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) {
    final lot = lotById(lotId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${lot.name} · Pour-over Guide',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dose: ${lot.dose} · Water: ${lot.water} · Ratio: ${lot.ratio}',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Grind: ${lot.grind}',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pour sequence:',
            style: TextStyle(fontWeight: FontWeight.w700, color: ink),
          ),
          const SizedBox(height: 6),
          for (final step in lot.brewSteps)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $step',
                style: const TextStyle(color: ink, fontSize: 13),
              ),
            ),
          const SizedBox(height: 18),
          action('Done', coordinator.pop),
        ],
      ),
    );
  }
}

/// History logbook of verified cupping scores.
class LogbookRoute extends AppRoute {
  @override
  Type get layout => StudioLayoutRoute;

  @override
  Uri toUri() => Uri(path: '/logbook');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      StudioPage(
        title: 'Cupping Logbook',
        eyebrow: 'Verified Tastings',
        children: [
          for (final entry in logbookRecords) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                color: cardColor,
                borderRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: scoreGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.name} · ${entry.score} pts',
                            style: const TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.origin} · ${entry.notes}',
                            style: const TextStyle(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          StudioCard(
            title: 'Barista Dispatch',
            subtitle: 'Calibrations and water chemistry from the brew bar.',
            children: [
              action(
                'Open Barista Desk',
                () => unawaited(coordinator.navigateUri(Uri.parse('/barista'))),
                secondary: true,
              ),
            ],
          ),
        ],
      );
}

/// Submodule screen resolved by [BaristaCoordinator].
class BaristaRoute extends AppRoute {
  @override
  Uri toUri() => Uri(path: '/barista');

  @override
  Widget build(
    Coordinator<AppRoute> coordinator,
    BuildContext context,
  ) => StudioPage(
    title: 'Barista Desk',
    eyebrow: 'Brew Station',
    children: [
      const StudioCard(
        title: 'Dial-in & Calibration',
        subtitle: 'Morning grinder alignment and water profile.',
        children: [
          Text(
            'EK43S set at notch 7.2 for washed Ethiopian lots. Water TDS adjusted to 110 ppm with 65 ppm calcium hardness.',
            style: TextStyle(color: ink, height: 1.4),
          ),
          SizedBox(height: 10),
          Text(
            'Recommended target: 2:15 total drawdown with gentle agitation.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
        ],
      ),
      action('Return to Cupping Table', () {
        unawaited(coordinator.recoverUri(Uri.parse('/shelf')));
      }),
    ],
  );
}

/// Feature coordinator as a RouteModule for bar operations.
class BaristaCoordinator extends Coordinator<AppRoute> {
  BaristaCoordinator(this.coordinator);

  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  AppRoute? parseRouteFromUri(Uri uri) =>
      uri.path == '/barista' ? BaristaRoute() : null;
}

/// Fallback screen for unavailable sample codes.
class NotFoundRoute extends AppRoute with RouteNotFound {
  NotFoundRoute(this.uri);

  final Uri uri;

  @override
  Uri toUri() => uri;

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      StudioPage(
        title: 'Sample Not Found',
        eyebrow: 'Menu Archive',
        children: [
          StudioCard(
            title: 'Lot unavailable',
            subtitle: 'Code: ${uri.path}',
            children: [
              const Text(
                'This coffee lot is not currently on the cupping table.',
                style: TextStyle(color: ink),
              ),
              const SizedBox(height: 14),
              action('Back to Cupping Table', () {
                unawaited(coordinator.recoverUri(Uri.parse('/shelf')));
              }),
            ],
          ),
        ],
      );
}

class CoffeeLot {
  const CoffeeLot({
    required this.id,
    required this.name,
    required this.origin,
    required this.process,
    required this.variety,
    required this.elevation,
    required this.flavorNotes,
    required this.roasterNotes,
    required this.dose,
    required this.water,
    required this.ratio,
    required this.grind,
    required this.brewSteps,
  });

  final String id;
  final String name;
  final String origin;
  final String process;
  final String variety;
  final String elevation;
  final String flavorNotes;
  final String roasterNotes;
  final String dose;
  final String water;
  final String ratio;
  final String grind;
  final List<String> brewSteps;
}

class LogbookEntry {
  const LogbookEntry({
    required this.name,
    required this.score,
    required this.origin,
    required this.notes,
  });

  final String name;
  final String score;
  final String origin;
  final String notes;
}

const coffeeLots = [
  CoffeeLot(
    id: 'yirga',
    name: 'Yirgacheffe Kochere',
    origin: 'Ethiopia',
    process: 'Washed',
    variety: 'Heirloom',
    elevation: '2,100 m',
    flavorNotes: 'Jasmine, bergamot, candied peach',
    roasterNotes:
        'Sourced from smallholder farmers in Kochere. Washed and dried on raised African beds.',
    dose: '16.0 g',
    water: '250 g (93°C)',
    ratio: '1:15.6',
    grind: 'Medium-fine (EK43 #7.5)',
    brewSteps: [
      '0:00 – 50 g Bloom (gentle swirl, 40s wait)',
      '0:40 – Pour to 150 g in concentric spirals',
      '1:20 – Final pour to 250 g, gentle drawdown by 2:15',
    ],
  ),
  CoffeeLot(
    id: 'huehue',
    name: 'Huehuetenango El Injerto',
    origin: 'Guatemala',
    process: 'Yellow Honey',
    variety: 'Bourbon & Caturra',
    elevation: '1,750 m',
    flavorNotes: 'Red apple, milk chocolate, hazelnut',
    roasterNotes:
        'Grown in high-altitude volcanic soil in western Guatemala. Pulped with mucilage intact for rounded body.',
    dose: '18.0 g',
    water: '270 g (94°C)',
    ratio: '1:15.0',
    grind: 'Medium (EK43 #8.0)',
    brewSteps: [
      '0:00 – 60 g Bloom (45s wait)',
      '0:45 – Continuous pour to 180 g',
      '1:30 – Finish pour to 270 g, total time 2:30',
    ],
  ),
  CoffeeLot(
    id: 'huila',
    name: 'Huila San Agustin',
    origin: 'Colombia',
    process: 'Double Anaerobic',
    variety: 'Pink Bourbon',
    elevation: '1,900 m',
    flavorNotes: 'Blood orange, panela, rosehip',
    roasterNotes:
        'Experimental lot from southern Huila. Sealed anaerobic maceration for 72 hours yields vibrant acidity and floral aromatics.',
    dose: '15.5 g',
    water: '250 g (92°C)',
    ratio: '1:16.1',
    grind: 'Medium-fine (EK43 #7.0)',
    brewSteps: [
      '0:00 – 45 g Bloom (35s wait)',
      '0:35 – Center pour to 140 g',
      '1:15 – Spiral pour to 250 g, finish at 2:10',
    ],
  ),
];

const logbookRecords = [
  LogbookEntry(
    name: 'Nyeri Hill AB',
    score: '89.0',
    origin: 'Kenya · Washed',
    notes: 'Blackcurrant, red grapefruit, cane sugar',
  ),
  LogbookEntry(
    name: 'Guji Gigesa',
    score: '88.5',
    origin: 'Ethiopia · Natural',
    notes: 'Dried strawberry, cacao nibs, lavender',
  ),
  LogbookEntry(
    name: 'Tarrazú La Minita',
    score: '86.0',
    origin: 'Costa Rica · White Honey',
    notes: 'Golden raisin, toffee, crisp apple',
  ),
];

CoffeeLot lotById(String id) => coffeeLots.firstWhere(
  (lot) => lot.id == id,
  orElse: () => coffeeLots.first,
);
