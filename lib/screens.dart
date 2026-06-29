import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'models.dart';
import 'score_engine.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  WaterType _waterType = WaterType.saltShore;
  TripRhythm _tripRhythm = TripRhythm.dawn;
  String? _spotId;
  bool _alerts = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(AppState state) {
    if (_page < 4) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    state.completeOnboarding(
      waterType: _waterType,
      homeSpotId: _spotId ?? state.spots.first.id,
      tripRhythm: _tripRhythm,
      alertIntent: _alerts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _spotId ??= state.spots.first.id;
    final buttonText = _page == 4 ? 'Show my window' : 'Continue';

    return Scaffold(
      body: _AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: const [
                    _BrandLockup(),
                    Spacer(),
                    _MockChip(text: 'prototype data'),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _OnboardingPanel(
                      eyebrow: 'Fishing window forecast',
                      title:
                          'Know your best two hours before you load the car.',
                      body:
                          'FishSignal combines pressure trend, tide movement, wind and solunar periods into one go / wait call for your mark.',
                      child: const _InstrumentPreview(),
                    ),
                    _OnboardingPanel(
                      eyebrow: 'Water type',
                      title: 'Tune the score to how you fish.',
                      body:
                          'Tidal marks lean harder on moving water. Inland marks keep pressure and solunar drivers in front.',
                      child: Column(
                        children: WaterType.values.map((type) {
                          return _ChoiceTile(
                            title: type.label,
                            subtitle: type.blurb,
                            selected: _waterType == type,
                            onTap: () => setState(() => _waterType = type),
                          );
                        }).toList(),
                      ),
                    ),
                    _OnboardingPanel(
                      eyebrow: 'Trip rhythm',
                      title: 'When can you actually get on the water?',
                      body:
                          'FishSignal still shows the best window, but it also calls out the strongest slot inside your real free time.',
                      child: Column(
                        children: TripRhythm.values.map((rhythm) {
                          return _ChoiceTile(
                            title: rhythm.label,
                            subtitle: '${rhythm.blurb} · ${rhythm.windowLabel}',
                            selected: _tripRhythm == rhythm,
                            onTap: () => setState(() => _tripRhythm = rhythm),
                          );
                        }).toList(),
                      ),
                    ),
                    _OnboardingPanel(
                      eyebrow: 'Home mark',
                      title: 'Pick the spot you actually plan around.',
                      body:
                          'The prototype starts with local sample marks so Today, Week and Spots are inspectable immediately.',
                      child: Column(
                        children: state.spots.map((spot) {
                          return _ChoiceTile(
                            title: spot.name,
                            subtitle: '${spot.area} - ${spot.waterType.label}',
                            selected: _spotId == spot.id,
                            onTap: () => setState(() => _spotId = spot.id),
                          );
                        }).toList(),
                      ),
                    ),
                    _OnboardingPanel(
                      eyebrow: 'Window alert',
                      title: 'Decide before the tide is already gone.',
                      body:
                          'Alerts are a facade in this prototype. The product intent is a one-hour nudge before the best window opens.',
                      child: _Surface(
                        child: SwitchListTile(
                          value: _alerts,
                          onChanged: (value) => setState(() => _alerts = value),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Alert me one hour before'),
                          subtitle: const Text(
                            'Prototype only - no real notification is scheduled.',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => _PageDot(active: i == _page),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _next(state),
                        child: Text(buttonText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TodayScreen(),
      const WeekPlannerScreen(),
      const SpotsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: _AppBackground(
        child: SafeArea(bottom: false, child: pages[_index]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: FishColors.ink.withValues(alpha: 0.86),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: FishColors.seaBright.withValues(alpha: 0.20),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FishColors.mist,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            height: 66,
            elevation: 0,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.speed_outlined, color: FishColors.seaBright),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.calendar_today_outlined,
                  color: FishColors.mistDim,
                ),
                selectedIcon: Icon(
                  Icons.calendar_today,
                  color: FishColors.seaBright,
                ),
                label: 'Week',
              ),
              NavigationDestination(
                icon: Icon(Icons.place_outlined, color: FishColors.mistDim),
                selectedIcon: Icon(Icons.place, color: FishColors.seaBright),
                label: 'Spots',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune, color: FishColors.mistDim),
                selectedIcon: Icon(Icons.tune, color: FishColors.seaBright),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final spot = state.activeSpot;
    if (spot == null) {
      return _PageFrame(
        title: 'FishSignal',
        subtitle: 'No saved marks',
        child: _EmptySpots(onAdd: state.addSampleSpot),
      );
    }

    final recommendation = state.recommendationFor(spot);
    final score = recommendation.day;
    final verdict = verdictFor(score.dayScore);
    final savedAlert = state.alertFor(spot.id, score);
    final bestHour = score.hourScores.firstWhere(
      (h) => h.sample.hour == score.bestWindow.startHour,
      orElse: () => score.hourScores.first,
    );

    void openWindow() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WindowDetailScreen(spot: spot, dayScore: score),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      children: [
        _TodayHeader(spot: spot, rhythm: state.tripRhythm),
        const SizedBox(height: 18),
        _BiteHero(
          score: score,
          verdict: verdict,
          recommendation: recommendation,
          alertOn: savedAlert != null,
          onOpen: openWindow,
          onAlert: () {
            final saved = state.toggleWindowAlert(spot, score);
            _showFacade(
              context,
              saved
                  ? 'Saved ${score.bestWindow.rangeLabel} alert locally'
                  : 'Removed local alert for ${score.bestWindow.rangeLabel}',
            );
          },
        ),
        const SizedBox(height: 18),
        _TripPlanCard(
          spot: spot,
          recommendation: recommendation,
          checklist: state.sessionChecklist(spot, score),
          savedAlert: savedAlert,
        ),
        const SizedBox(height: 18),
        _SoftLabel(text: "What's driving it"),
        const SizedBox(height: 10),
        _DriverGrid(contributions: bestHour.contributions),
        const SizedBox(height: 18),
        _SoftLabel(text: 'How today unfolds'),
        const SizedBox(height: 10),
        _BiteCurveCard(hourScores: score.hourScores, window: score.bestWindow),
        const SizedBox(height: 18),
        const _DisclosureNote(),
      ],
    );
  }
}

class WindowDetailScreen extends StatelessWidget {
  const WindowDetailScreen({
    super.key,
    required this.spot,
    required this.dayScore,
  });

  final Spot spot;
  final DayScore dayScore;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final verdict = verdictFor(dayScore.dayScore);
    final savedAlert = state.alertFor(spot.id, dayScore);
    final checklist = state.sessionChecklist(spot, dayScore);
    final hour = dayScore.hourScores.firstWhere(
      (h) => h.sample.hour == dayScore.bestWindow.startHour,
      orElse: () => dayScore.hourScores.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Window detail'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: false,
      body: _AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          children: [
            _ScoreHero(score: dayScore, verdict: verdict),
            const SizedBox(height: 16),
            _Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    label: spot.name,
                    action: dayScore.bestWindow.rangeLabel,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This is a planning signal, not a catch guarantee. The score is highest where pressure, tide run, solunar period and wind line up.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: FishColors.mistDim,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...hour.contributions.map((c) => _ContributionRow(c: c)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(label: 'Session plan'),
                  const SizedBox(height: 12),
                  _SignalLine(label: 'Arrive', value: _arrivalLabel(dayScore)),
                  _SignalLine(label: 'Target', value: spot.target),
                  _SignalLine(label: 'Mark note', value: spot.accessNote),
                  const SizedBox(height: 12),
                  ...checklist.map((item) => _PlanBullet(text: item)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(label: 'Session card'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: FishColors.inkLine),
                      color: FishColors.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${dayScore.bestWindow.rangeLabel} - ${dayScore.rounded}/100 bite signal',
                          style: const TextStyle(color: FishColors.amber),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Preview and copy a local share card. Production would render this as an image.',
                          style: TextStyle(color: FishColors.mistDim),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showShareCard(
                            context,
                            state.shareCardFor(spot, dayScore),
                          ),
                          icon: const Icon(Icons.ios_share),
                          label: const Text('Share'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            final saved = state.toggleWindowAlert(
                              spot,
                              dayScore,
                            );
                            _showFacade(
                              context,
                              saved
                                  ? 'Saved ${dayScore.bestWindow.rangeLabel} alert locally'
                                  : 'Removed local window alert',
                            );
                          },
                          icon: Icon(
                            savedAlert != null
                                ? Icons.notifications_active
                                : Icons.notifications_outlined,
                          ),
                          label: Text(
                            savedAlert != null ? 'Alert saved' : 'Alert me',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _SafetyNotice(),
          ],
        ),
      ),
    );
  }
}

class WeekPlannerScreen extends StatelessWidget {
  const WeekPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final spot = state.activeSpot;
    if (spot == null) {
      return _PageFrame(
        title: '7-day planner',
        subtitle: 'No saved marks',
        child: _EmptySpots(onAdd: state.addSampleSpot),
      );
    }
    final ranked = [...state.weekFor(spot)]
      ..sort((a, b) => b.dayScore.compareTo(a.dayScore));
    final goDays = ranked
        .where((d) => verdictFor(d.dayScore) == BiteVerdict.go)
        .length;
    final fishableDays = ranked
        .where((d) => verdictFor(d.dayScore) != BiteVerdict.wait)
        .length;
    final subtitle = goDays > 0
        ? '$goDays strong ${goDays == 1 ? 'day' : 'days'} · $fishableDays fishable for ${spot.name}'
        : fishableDays > 0
        ? '$fishableDays fishable ${fishableDays == 1 ? 'day' : 'days'} · pick your window for ${spot.name}'
        : 'A quiet week at ${spot.name} · wait it out';

    return _PageFrame(
      title: '7-day planner',
      subtitle: subtitle,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        itemBuilder: (context, index) => _WeekCard(
          rank: index + 1,
          score: ranked[index],
          spot: spot,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  WindowDetailScreen(spot: spot, dayScore: ranked[index]),
            ),
          ),
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: ranked.length,
      ),
    );
  }
}

String _arrivalLabel(DayScore score) {
  final hour = score.bestWindow.startHour <= 0
      ? score.bestWindow.startHour + 23
      : score.bestWindow.startHour - 1;
  final h = hour % 12 == 0 ? 12 : hour % 12;
  final suffix = hour < 12 ? 'AM' : 'PM';
  return '$h $suffix';
}

class SpotsScreen extends StatelessWidget {
  const SpotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return _PageFrame(
      title: 'Spots',
      subtitle: 'Saved marks and local state',
      trailing: IconButton.filledTonal(
        tooltip: 'Add sample mark',
        onPressed: () {
          state.addSampleSpot();
          _showFacade(context, 'Added a local sample mark');
        },
        icon: const Icon(Icons.add_location_alt_outlined),
      ),
      child: state.spots.isEmpty
          ? _EmptySpots(onAdd: state.addSampleSpot)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              itemBuilder: (context, index) {
                final spot = state.spots[index];
                final active = state.activeSpot?.id == spot.id;
                final today = state.todayFor(spot);
                final verdict = verdictFor(today.dayScore);
                final savedCount = state.savedAlerts
                    .where((alert) => alert.spotId == spot.id)
                    .length;
                return _Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  spot.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${spot.area} - ${spot.waterType.label}',
                                  style: const TextStyle(
                                    color: FishColors.mistDim,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${spot.target} · ${spot.accessNote}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: FishColors.mistDim,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (active) const _StatusPill(text: 'active'),
                        ],
                      ),
                      if (savedCount > 0) ...[
                        const SizedBox(height: 12),
                        _StatusPill(
                          text:
                              '$savedCount saved ${savedCount == 1 ? 'window' : 'windows'}',
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _SignalPill(
                            text: verdict.headline,
                            color: FishColors.forVerdict(verdict),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Today ${today.rounded}/100 · best ${today.bestWindow.rangeLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FishColors.mistDim,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            label: Text(
                              active ? 'Using this mark' : 'Use mark',
                            ),
                            avatar: const Icon(Icons.my_location, size: 18),
                            onPressed: () => state.setActiveSpot(spot.id),
                          ),
                          ActionChip(
                            label: Text(
                              spot.isHomeMark ? 'Home mark' : 'Make home',
                            ),
                            avatar: const Icon(Icons.home_outlined, size: 18),
                            onPressed: () => state.makeHomeMark(spot.id),
                          ),
                          ActionChip(
                            label: Text(
                              spot.alertEnabled ? 'Alert on' : 'Alert off',
                            ),
                            avatar: Icon(
                              spot.alertEnabled
                                  ? Icons.notifications_active
                                  : Icons.notifications_outlined,
                              size: 18,
                            ),
                            onPressed: () => state.toggleAlert(spot.id),
                          ),
                          ActionChip(
                            label: const Text('Delete'),
                            avatar: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => state.deleteSpot(spot.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: state.spots.length,
            ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return _PageFrame(
      title: 'More',
      subtitle: 'Trust, support and prototype boundaries',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          _Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(label: 'Local profile'),
                const SizedBox(height: 12),
                _SignalLine(
                  label: 'Trip rhythm',
                  value: state.tripRhythm.label,
                ),
                _SignalLine(
                  label: 'Saved alerts',
                  value: '${state.savedAlerts.length}',
                ),
                if (state.savedAlerts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...state.savedAlerts
                      .take(3)
                      .map(
                        (alert) => _PlanBullet(
                          text:
                              '${alert.spotName}: ${alert.dateLabel}, ${alert.rangeLabel} (${alert.leadLabel})',
                        ),
                      ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Surface(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.workspace_premium_outlined,
                  title: 'FishSignal Pro',
                  subtitle: 'Annual-led paywall facade',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  ),
                ),
                const _Rule(),
                _SettingsRow(
                  icon: Icons.support_agent,
                  title: 'Support',
                  subtitle: 'Prototype support surface',
                  onTap: () => _showFacade(context, 'Support would open here'),
                ),
                const _Rule(),
                _SettingsRow(
                  icon: Icons.dataset_outlined,
                  title: 'Data sources',
                  subtitle: 'Fixtures today; Open-Meteo/tide source later',
                  onTap: () =>
                      _showFacade(context, 'Data-source explainer facade'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SafetyNotice(),
          const SizedBox(height: 16),
          const _Surface(
            child: Text(
              'No account, payment, location, notification, analytics or provider service is connected. The prototype is deliberately local-only.',
              style: TextStyle(color: FishColors.mistDim, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FishSignal Pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              'Plan the week before the tide chooses for you.',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Prototype facade only - no RevenueCat, App Store or Play billing is connected.',
              style: TextStyle(color: FishColors.mistDim, height: 1.35),
            ),
            const SizedBox(height: 18),
            const _PlanTile(
              title: 'Annual',
              price: 'GBP 24.99 / year',
              note: '7-day trial direction',
              featured: true,
            ),
            const SizedBox(height: 10),
            const _PlanTile(
              title: 'Monthly',
              price: 'GBP 4.99 / month',
              note: 'Fallback option',
            ),
            const SizedBox(height: 10),
            const _PlanTile(
              title: 'Weekly',
              price: 'GBP 1.99 / week',
              note: 'Short trip planning',
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => _showFacade(context, 'Purchase facade only'),
              child: const Text('Continue'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  _showFacade(context, 'Terms and Privacy placeholders'),
              child: const Text('Terms and Privacy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: FishColors.mistDim),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: FishColors.amber,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: FishColors.mistDim,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

class _InstrumentPreview extends StatelessWidget {
  const _InstrumentPreview();

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(label: 'Today at Chesil Cove', action: '6-8 AM'),
          const SizedBox(height: 16),
          Row(
            children: [
              const _BiteDial(
                score: 72,
                size: 118,
                arcColor: FishColors.amber,
                trackColor: FishColors.inkLine,
                textColor: FishColors.amber,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SignalLine(label: 'Pressure', value: 'falling'),
                    _SignalLine(label: 'Tide', value: 'mid-flood'),
                    _SignalLine(label: 'Wind', value: 'fishable'),
                    _SignalLine(label: 'Solunar', value: 'major'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reusable gradient hero panel: the verdict gradient is the background, with a
/// tonal bite dial and the best-window time. Used on the window-detail screen.
class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.score, required this.verdict});

  final DayScore score;
  final BiteVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final fg = FishColors.onHero(verdict);
    return _HeroSurface(
      verdict: verdict,
      child: Row(
        children: [
          _BiteDial(
            score: score.rounded,
            size: 116,
            arcColor: fg,
            trackColor: fg.withValues(alpha: 0.22),
            textColor: fg,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroChip(text: verdict.headline, fg: fg),
                const SizedBox(height: 12),
                Text(
                  score.bestWindow.rangeLabel,
                  style: TextStyle(
                    color: fg,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${score.forecast.weekdayLabel} ${score.forecast.dateLabel} · best 2-hour window',
                  style: TextStyle(color: fg.withValues(alpha: 0.78)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's full-bleed hero: the loudest moment in the app. Friendly read,
/// big tonal dial, the best window, and the primary "Open window" action all
/// sitting on the verdict gradient.
class _BiteHero extends StatelessWidget {
  const _BiteHero({
    required this.score,
    required this.verdict,
    required this.recommendation,
    required this.alertOn,
    required this.onOpen,
    required this.onAlert,
  });

  final DayScore score;
  final BiteVerdict verdict;
  final TripRecommendation recommendation;
  final bool alertOn;
  final VoidCallback onOpen;
  final VoidCallback onAlert;

  String get _greeting {
    switch (verdict) {
      case BiteVerdict.go:
        return 'The window is on — go fish it.';
      case BiteVerdict.maybe:
        return 'Fishable, if you time it right.';
      case BiteVerdict.wait:
        return 'Slow today — a better window is coming.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = FishColors.onHero(verdict);
    final dim = fg.withValues(alpha: 0.78);
    return _HeroSurface(
      verdict: verdict,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeroChip(text: verdict.headline.toUpperCase(), fg: fg),
              const Spacer(),
              Text(
                '${score.forecast.weekdayLabel} ${score.forecast.dateLabel}',
                style: TextStyle(color: dim, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BiteDial(
                score: score.rounded,
                size: 132,
                arcColor: fg,
                trackColor: fg.withValues(alpha: 0.20),
                textColor: fg,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best window',
                      style: TextStyle(
                        color: dim,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score.bestWindow.rangeLabel,
                      style: TextStyle(
                        color: fg,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _greeting,
                      style: TextStyle(
                        color: dim,
                        fontSize: 14.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recommendation.rhythmLine,
                      style: TextStyle(
                        color: dim,
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: fg,
                    foregroundColor: verdict == BiteVerdict.go
                        ? Colors.white
                        : _heroBase(verdict),
                  ),
                  icon: const Icon(Icons.north_east, size: 20),
                  label: const Text('Open window'),
                ),
              ),
              const SizedBox(width: 12),
              _HeroIconButton(active: alertOn, fg: fg, onTap: onAlert),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripPlanCard extends StatelessWidget {
  const _TripPlanCard({
    required this.spot,
    required this.recommendation,
    required this.checklist,
    required this.savedAlert,
  });

  final Spot spot;
  final TripRecommendation recommendation;
  final List<String> checklist;
  final SavedWindowAlert? savedAlert;

  @override
  Widget build(BuildContext context) {
    final score = recommendation.day;
    final rhythmWindow = recommendation.rhythmWindow;
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle(label: 'Trip plan')),
              if (savedAlert != null)
                _StatusPill(text: 'alert ${savedAlert!.leadLabel}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniPlanStat(
                  label: 'Arrive',
                  value: _hourBefore(score.bestWindow.startHour),
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniPlanStat(
                  label: 'Target',
                  value: spot.target.split(',').first,
                  icon: Icons.anchor,
                ),
              ),
            ],
          ),
          if (!recommendation.bestFitsRhythm) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FishColors.amber.withValues(alpha: 0.10),
                border: Border.all(
                  color: FishColors.amber.withValues(alpha: 0.26),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_filled,
                    size: 18,
                    color: FishColors.amber,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'If you can only do ${recommendation.rhythm.label.toLowerCase()}, use ${rhythmWindow.rangeLabel} (${rhythmWindow.rounded}/100).',
                      style: const TextStyle(
                        color: FishColors.mist,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          ...checklist.take(3).map((item) => _PlanBullet(text: item)),
        ],
      ),
    );
  }

  static String _hourBefore(int hour) {
    final wrapped = hour <= 0 ? hour + 23 : hour - 1;
    final h = wrapped % 12 == 0 ? 12 : wrapped % 12;
    final suffix = wrapped < 12 ? 'AM' : 'PM';
    return '$h $suffix';
  }
}

class _MiniPlanStat extends StatelessWidget {
  const _MiniPlanStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FishColors.ink.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: FishColors.seaBright),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: FishColors.mistDim,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FishColors.mist,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBullet extends StatelessWidget {
  const _PlanBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: FishColors.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: FishColors.mistDim, height: 1.32),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deep base colour pulled from the verdict gradient, used as button label
/// colour so text reads against the bright foreground fill.
Color _heroBase(BiteVerdict v) => FishColors.heroGradient(v).last;

/// The gradient surface shared by both heroes.
class _HeroSurface extends StatelessWidget {
  const _HeroSurface({
    required this.verdict,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final BiteVerdict verdict;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = FishColors.heroGradient(verdict);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.text, required this.fg});

  final String text;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.active,
    required this.fg,
    required this.onTap,
  });

  final bool active;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fg.withValues(alpha: active ? 0.22 : 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(
            active ? Icons.notifications_active : Icons.notifications_outlined,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Gradient twilight backdrop the whole app floats on.
class _AppBackground extends StatelessWidget {
  const _AppBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: FishColors.bgGradient,
        ),
      ),
      child: child,
    );
  }
}

/// Friendly Today header: greeting, the active mark, and the honesty chip.
class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.spot, required this.rhythm});

  final Spot spot;
  final TripRhythm rhythm;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.place,
                    size: 16,
                    color: FishColors.seaBright,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      spot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FishColors.seaBright,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your fishing window',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${rhythm.label} · ${spot.target}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FishColors.mistDim,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: _MockChip(text: 'mock forecast'),
        ),
      ],
    );
  }
}

/// Quiet section label, lowercase-feel, used between cards.
class _SoftLabel extends StatelessWidget {
  const _SoftLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: FishColors.mist,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// 2×2 grid of the four bite drivers, each a soft tile with an icon, the
/// plain-language read, and a tonal strength bar from the score engine.
class _DriverGrid extends StatelessWidget {
  const _DriverGrid({required this.contributions});

  final List<DriverContribution> contributions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: contributions
              .map(
                (c) => SizedBox(
                  width: tileWidth,
                  child: _DriverTile(contribution: c),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.contribution});

  final DriverContribution contribution;

  IconData get _icon {
    switch (contribution.label) {
      case 'Pressure':
        return Icons.compress;
      case 'Tide':
        return Icons.waves;
      case 'Wind':
        return Icons.air;
      case 'Solunar':
        return Icons.nightlight_round;
      default:
        return Icons.tune;
    }
  }

  Color get _accent {
    final s = contribution.score01;
    if (s >= 0.66) return FishColors.go;
    if (s >= 0.4) return FishColors.amber;
    return FishColors.wait;
  }

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, size: 19, color: _accent),
              ),
              const Spacer(),
              Text(
                '${contribution.score01 >= 0.999 ? 100 : (contribution.score01 * 100).round()}',
                style: TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            contribution.label,
            style: const TextStyle(
              color: FishColors.mist,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: contribution.score01.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: _accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            contribution.detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FishColors.mistDim,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// A smooth filled area chart of the day's hourly bite score, with the best
/// window highlighted and its peak marked. This is the product mechanic made
/// visible: you can *see* the day rise into its window and fall away.
class _BiteCurveCard extends StatelessWidget {
  const _BiteCurveCard({required this.hourScores, required this.window});

  final List<HourScore> hourScores;
  final BiteWindow window;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Bite curve',
                style: TextStyle(
                  color: FishColors.mist,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                window.rangeLabel,
                style: const TextStyle(
                  color: FishColors.amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            width: double.infinity,
            child: CustomPaint(
              painter: _BiteCurvePainter(
                hourScores: hourScores,
                window: window,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _AxisLabel('12a'),
              _AxisLabel('6a'),
              _AxisLabel('12p'),
              _AxisLabel('6p'),
              _AxisLabel('12a'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Computed hour by hour from pressure, tide, wind and solunar — the gold band is your best two hours.',
            style: TextStyle(
              color: FishColors.mistDim.withValues(alpha: 0.95),
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: FishColors.mistDim, fontSize: 11),
    );
  }
}

class _BiteCurvePainter extends CustomPainter {
  _BiteCurvePainter({required this.hourScores, required this.window});

  final List<HourScore> hourScores;
  final BiteWindow window;

  @override
  void paint(Canvas canvas, Size size) {
    if (hourScores.isEmpty) return;
    final n = hourScores.length;
    double x(int i) => n == 1 ? 0.0 : size.width * i / (n - 1);
    double y(double score) => size.height * (1 - (score / 100).clamp(0.0, 1.0));

    // Smooth path through the points using simple Catmull-Rom-ish midpoints.
    final pts = <Offset>[
      for (var i = 0; i < n; i++) Offset(x(i), y(hourScores[i].score)),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      line.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    line.lineTo(pts.last.dx, pts.last.dy);

    // Filled area under the curve.
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            FishColors.seaBright.withValues(alpha: 0.40),
            FishColors.seaBright.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    // Highlight band for the best window.
    final startI = hourScores.indexWhere(
      (h) => h.sample.hour == window.startHour,
    );
    if (startI >= 0) {
      final endI = math.min(
        n - 1,
        startI + (window.endHour - window.startHour),
      );
      final bandRect = Rect.fromLTRB(x(startI), 0, x(endI), size.height);
      canvas.drawRect(
        bandRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              FishColors.amber.withValues(alpha: 0.28),
              FishColors.amber.withValues(alpha: 0.04),
            ],
          ).createShader(bandRect),
      );

      // Peak dot at the window start (the headline hour).
      final peak = Offset(x(startI), y(hourScores[startI].score));
      canvas.drawCircle(peak, 6, Paint()..color = FishColors.amber);
      canvas.drawCircle(
        peak,
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    // The curve stroke on top.
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = FishColors.seaBright,
    );
  }

  @override
  bool shouldRepaint(_BiteCurvePainter old) =>
      old.hourScores != hourScores || old.window != window;
}

/// Honest disclosure that the forecast is mocked.
class _DisclosureNote extends StatelessWidget {
  const _DisclosureNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: FishColors.mistDim.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'All pressure, tide, wind and solunar values are local sample data. No live forecast or marine-safety service is connected yet.',
              style: TextStyle(
                color: FishColors.mistDim,
                height: 1.35,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.rank,
    required this.score,
    required this.spot,
    required this.onTap,
  });

  final int rank;
  final DayScore score;
  final Spot spot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final verdict = verdictFor(score.dayScore);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: _Surface(
        child: Row(
          children: [
            _RankBadge(rank: rank, verdict: verdict),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${score.forecast.weekdayLabel} ${score.forecast.dateLabel}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${score.bestWindow.rangeLabel} at ${spot.name}',
                    style: const TextStyle(color: FishColors.mistDim),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Open session plan',
                    style: TextStyle(
                      color: FishColors.seaBright,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score.rounded}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: FishColors.forVerdict(verdict),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  verdict.headline,
                  style: const TextStyle(color: FishColors.mistDim),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft 270° dial showing the 0–100 bite score. Tonal by design so it sits
/// elegantly on top of either the verdict gradient (hero) or a dark surface.
class _BiteDial extends StatelessWidget {
  const _BiteDial({
    required this.score,
    required this.size,
    required this.arcColor,
    required this.trackColor,
    required this.textColor,
  });

  final int score;
  final double size;
  final Color arcColor;
  final Color trackColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BiteDialPainter(
          progress: (score / 100).clamp(0.0, 1.0),
          arcColor: arcColor,
          trackColor: trackColor,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.34,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'BITE SCORE',
                style: TextStyle(
                  fontSize: size * 0.085,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BiteDialPainter extends CustomPainter {
  _BiteDialPainter({
    required this.progress,
    required this.arcColor,
    required this.trackColor,
  });

  final double progress;
  final Color arcColor;
  final Color trackColor;

  static const double _start = math.pi * 0.75; // 135°
  static const double _sweep = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, _start, _sweep, false, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = arcColor;
    canvas.drawArc(rect, _start, _sweep * progress, false, arc);
  }

  @override
  bool shouldRepaint(_BiteDialPainter old) =>
      old.progress != progress ||
      old.arcColor != arcColor ||
      old.trackColor != trackColor;
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.c});

  final DriverContribution c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '${c.points.round()}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FishColors.amber,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  c.detail,
                  style: const TextStyle(
                    color: FishColors.mistDim,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? FishColors.sea.withValues(alpha: 0.24)
                : FishColors.inkSoft,
            border: Border.all(
              color: selected ? FishColors.seaBright : FishColors.inkLine,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: FishColors.mistDim),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? FishColors.seaBright : FishColors.mistDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft frosted card. The whole app is built from these — big radius, a faint
/// top-light gradient, hairline of white instead of a hard border, and a low
/// soft shadow so cards float over the twilight background.
class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.025),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: FishColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, this.action});

  final String label;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: FishColors.mistDim,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: FishColors.amber,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _MockChip extends StatelessWidget {
  const _MockChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FishColors.amber.withValues(alpha: 0.13),
        border: Border.all(color: FishColors.amberDim),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: FishColors.amber, fontSize: 12),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FishColors.seaBright.withValues(alpha: 0.16),
        border: Border.all(color: FishColors.seaBright),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: FishColors.seaBright,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.70)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.verdict});

  final int rank;
  final BiteVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final color = FishColors.forVerdict(verdict);
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.70)),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: FishColors.seaBright),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.price,
    required this.note,
    this.featured = false,
  });

  final String title;
  final String price;
  final String note;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Row(
        children: [
          Icon(
            featured ? Icons.star : Icons.radio_button_unchecked,
            color: featured ? FishColors.amber : FishColors.mistDim,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(note, style: const TextStyle(color: FishColors.mistDim)),
              ],
            ),
          ),
          Text(
            price,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return const _Surface(
      child: Text(
        'Planning aid only. FishSignal does not guarantee catches and is not a marine safety, navigation or tide-warning system.',
        style: TextStyle(color: FishColors.mistDim, height: 1.35),
      ),
    );
  }
}

class _EmptySpots extends StatelessWidget {
  const _EmptySpots({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _Surface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No marks saved',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a local sample mark to keep exploring the prototype.',
              style: TextStyle(color: FishColors.mistDim),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add sample mark'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: FishColors.sea.withValues(alpha: 0.28),
            border: Border.all(color: FishColors.seaBright),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.waves, size: 19, color: FishColors.seaBright),
        ),
        const SizedBox(width: 10),
        Text(
          'FishSignal',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _SignalLine extends StatelessWidget {
  const _SignalLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: FishColors.mistDim),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? FishColors.amber : FishColors.inkLine,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1);
  }
}

void _showFacade(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$message - prototype only.')));
}

void _showShareCard(BuildContext context, String card) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: FishColors.ink,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share card preview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _Surface(
                child: Text(
                  card,
                  style: const TextStyle(
                    color: FishColors.mist,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: card));
                  Navigator.of(context).pop();
                  _showFacade(context, 'Copied share card text locally');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy text'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
