import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  String? _spotId;
  bool _alerts = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(AppState state) {
    if (_page < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    state.completeOnboarding(
      waterType: _waterType,
      homeSpotId: _spotId ?? state.spots.first.id,
      alertIntent: _alerts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _spotId ??= state.spots.first.id;
    final buttonText = _page == 3 ? 'Show my window' : 'Continue';

    return Scaffold(
      body: SafeArea(
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
                    title: 'Know your best two hours before you load the car.',
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
                      4,
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
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: FishColors.inkSoft,
        indicatorColor: FishColors.sea.withValues(alpha: 0.22),
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Week',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            label: 'Spots',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
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

    final score = state.todayFor(spot);
    final verdict = verdictFor(score.dayScore);
    final bestHour = score.hourScores.firstWhere(
      (h) => h.sample.hour == score.bestWindow.startHour,
      orElse: () => score.hourScores.first,
    );

    return _PageFrame(
      title: 'FishSignal',
      subtitle: '${spot.name} - ${spot.area}',
      trailing: const _MockChip(text: 'mock forecast'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          _ScoreHero(score: score, verdict: verdict),
          const SizedBox(height: 16),
          _Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  label: 'Best window',
                  action: score.bestWindow.rangeLabel,
                ),
                const SizedBox(height: 12),
                Text(
                  verdict.advice,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bestHour.contributions
                      .map((c) => _DriverPill(contribution: c))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WindowDetailScreen(
                                spot: spot,
                                dayScore: score,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open window'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Toggle alert facade',
                      onPressed: () => state.toggleAlert(spot.id),
                      icon: Icon(
                        spot.alertEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Timeline(hourScores: score.hourScores, window: score.bestWindow),
          const SizedBox(height: 16),
          const _Surface(
            child: Text(
              'All weather, pressure, tide and solunar values are local fixtures. No live forecast or marine-safety data is connected yet.',
              style: TextStyle(color: FishColors.mistDim, height: 1.35),
            ),
          ),
        ],
      ),
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
    final hour = dayScore.hourScores.firstWhere(
      (h) => h.sample.hour == dayScore.bestWindow.startHour,
      orElse: () => dayScore.hourScores.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Window detail'),
        backgroundColor: FishColors.ink,
      ),
      body: ListView(
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
                        'Share facade only. Production would render this as an image card.',
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
                        onPressed: () => _showFacade(context, 'Share card'),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => state.toggleAlert(spot.id),
                        icon: Icon(
                          spot.alertEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_outlined,
                        ),
                        label: Text(
                          spot.alertEnabled ? 'Alert on' : 'Alert me',
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

    return _PageFrame(
      title: '7-day planner',
      subtitle: 'Best-to-worst windows for ${spot.name}',
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        itemBuilder: (context, index) =>
            _WeekCard(rank: index + 1, score: ranked[index], spot: spot),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: ranked.length,
      ),
    );
  }
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
                              ],
                            ),
                          ),
                          if (active) const _StatusPill(text: 'active'),
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
    return _PageFrame(
      title: 'More',
      subtitle: 'Trust, support and prototype boundaries',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
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
        backgroundColor: FishColors.ink,
      ),
      body: ListView(
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
              const _Gauge(score: 72, size: 118),
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

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.score, required this.verdict});

  final DayScore score;
  final BiteVerdict verdict;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _Gauge(score: score.rounded, size: 132),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusPill(
                  text: verdict.headline,
                  color: FishColors.forVerdict(verdict),
                ),
                const SizedBox(height: 12),
                Text(
                  score.bestWindow.rangeLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${score.forecast.weekdayLabel} ${score.forecast.dateLabel} - best 2-hour window',
                  style: const TextStyle(color: FishColors.mistDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.hourScores, required this.window});

  final List<HourScore> hourScores;
  final BiteWindow window;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(label: '24-hour activity'),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: hourScores.map((h) {
                final inWindow =
                    h.sample.hour >= window.startHour &&
                    h.sample.hour < window.endHour;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Tooltip(
                      message: '${h.sample.clockLabel}: ${h.rounded}',
                      child: FractionallySizedBox(
                        heightFactor: math.max(0.12, h.score / 100),
                        alignment: Alignment.bottomCenter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: inWindow
                                ? FishColors.amber
                                : FishColors.sea.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Bars show computed hourly signal from mocked drivers.',
            style: TextStyle(color: FishColors.mistDim),
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
  });

  final int rank;
  final DayScore score;
  final Spot spot;

  @override
  Widget build(BuildContext context) {
    final verdict = verdictFor(score.dayScore);
    return _Surface(
      child: Row(
        children: [
          _RankBadge(rank: rank),
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
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.score, required this.size});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              color: FishColors.amber,
              backgroundColor: FishColors.inkLine,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: FishColors.amber,
                ),
              ),
              const Text(
                'signal',
                style: TextStyle(color: FishColors.mistDim, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: FishColors.inkSoft,
        border: Border.all(color: FishColors.inkLine),
        borderRadius: BorderRadius.circular(14),
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

class _DriverPill extends StatelessWidget {
  const _DriverPill({required this.contribution});

  final DriverContribution contribution;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: FishColors.ink,
        border: Border.all(color: FishColors.inkLine),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${contribution.label} +${contribution.points.round()}',
        style: const TextStyle(fontSize: 12, color: FishColors.mist),
      ),
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
  const _StatusPill({required this.text, this.color = FishColors.seaBright});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color),
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
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FishColors.ink,
        border: Border.all(color: FishColors.inkLine),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: const TextStyle(
          color: FishColors.amber,
          fontWeight: FontWeight.w900,
        ),
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
