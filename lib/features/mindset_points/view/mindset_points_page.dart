import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/mindset_points/view_model/mindset_points_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/widgets/common/diagram_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MindSetPoints extends ConsumerStatefulWidget {
  const MindSetPoints({
    super.key,
    this.fromOnboarding = false,
    this.onFinalMaskTap,
  });

  final bool fromOnboarding;
  final VoidCallback? onFinalMaskTap;

  @override
  ConsumerState<MindSetPoints> createState() => _MindSetPointsState();
}

class _MindSetPointsState extends ConsumerState<MindSetPoints>
    with TickerProviderStateMixin {
  late final AnimationController _statsC;
  late final Animation<double> _statsCurve;
  AnimationController? _swipeAnimCtrl;

  @override
  void initState() {
    super.initState();
    _statsC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _statsCurve = CurvedAnimation(parent: _statsC, curve: Curves.easeInOutCubic);

    Future.microtask(() async {
      final lang = ref.read(languageProvider);
      await ref
          .read(mindsetPointsViewModelProvider.notifier)
          .loadPrefs(lang: lang);
      if (mounted) {
        _statsC.forward();
      }
    });
  }

  @override
  void dispose() {
    _statsC.dispose();
    _swipeAnimCtrl?.dispose();
    super.dispose();
  }

  bool _handleSystemBack() => true;

  bool _handleBackNavigation() => true;

  void _onPeriodUpdated() {
    _statsC.reset();
    _statsC.forward();
  }

  @override
  Widget build(BuildContext context) {
    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;
    final lang = ref.watch(languageProvider);
    final state = ref.watch(mindsetPointsViewModelProvider);
    final vm = ref.read(mindsetPointsViewModelProvider.notifier);
    final period = state.period;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _handleSystemBack()) {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Material(
        child: Scaffold(
          body: Container(
            height: double.maxFinite,
            width: double.maxFinite,
            color: appTheme.background,
            child: Builder(
              builder: (context) {
                final textScale = MediaQuery.of(context).textScaler.scale(1.0);
                final shouldEnableScroll = textScale > 1.2;

                final content = ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (widget.fromOnboarding && !state.showFinalMask) {
                        final shouldTrack = vm.showFinalMaskAndTrack();
                        _swipeAnimCtrl?.stop();
                        if (shouldTrack) {
                          MixpanelService.instance.track('[onboarding4] vue page 4e.');
                        }
                      }
                    },
                    onHorizontalDragStart: (_) => vm.onHorizontalDragStart(),
                    onHorizontalDragUpdate: (details) {
                      vm.onHorizontalDragUpdate(
                        primaryDelta: details.primaryDelta ?? 0.0,
                        fromOnboarding: widget.fromOnboarding,
                      );
                    },
                    onHorizontalDragEnd: (details) {
                      final shouldTrack = vm.onHorizontalDragEnd(
                        velocityX: details.velocity.pixelsPerSecond.dx,
                        screenWidth: MediaQuery.of(context).size.width,
                        fromOnboarding: widget.fromOnboarding,
                      );
                      _swipeAnimCtrl?.stop();
                      if (shouldTrack) {
                        MixpanelService.instance.track('[onboarding4] vue page 4e.');
                      }
                      _onPeriodUpdated();
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(color: appTheme.background),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 20 * xFact,
                              right: 20 * xFact,
                              top: 5 * yFact,
                              bottom: 15 * yFact,
                            ),
                            child: Stack(
                              children: [
                                if (!state.showFinalMask)
                                  Padding(
                                    padding: EdgeInsets.only(top: 55 * yFact),
                                    child: SizedBox(
                                      height: 210 * xFact,
                                      child: Image.asset(
                                        'assets/images/flamy/flamy_glasses.png',
                                      ),
                                    ),
                                  ),
                                Column(
                                  children: [
                                    FittedBox(
                                      child: Row(
                                        children: [
                                          if (!widget.fromOnboarding)
                                            GestureDetector(
                                              onTap: () {
                                                if (_handleBackNavigation()) {
                                                  Navigator.pop(context);
                                                }
                                              },
                                              child: Icon(
                                                Icons.close,
                                                color: appTheme.onBackground,
                                                size: 40 * xFact,
                                              ),
                                            ),
                                          if (!widget.fromOnboarding)
                                            SizedBox(width: 10 * xFact),
                                          if (!widget.fromOnboarding)
                                            Text(
                                              translate('Mindset Points', lang),
                                              style: TextStyle(
                                                fontFamily: 'YesevaOne',
                                                color: appTheme.onBackground,
                                                fontSize: 35 * xFact,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    !widget.fromOnboarding
                                        ? SizedBox(height: 22 * yFact)
                                        : SizedBox(height: 70 * yFact),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Column(
                                          children: [
                                            SizedBox(height: 15 * yFact),
                                            AnimatedBuilder(
                                              animation: _statsCurve,
                                              builder: (_, __) {
                                                final tot = (_statsCurve.value *
                                                        state.totList[period])
                                                    .round();
                                                return Text(
                                                  '$tot',
                                                  style: TextStyle(
                                                    fontFamily: 'YesevaOne',
                                                    color: appTheme.onBackground,
                                                    fontSize: 50 * ScreenScale.x,
                                                  ),
                                                );
                                              },
                                            ),
                                            Text(
                                              translate('Mindset Points', lang),
                                              style: TextStyle(
                                                fontFamily: 'YesevaOne',
                                                color: appTheme.onBackground,
                                                fontSize: 30 * xFact,
                                              ),
                                            ),
                                            SizedBox(height: 10 * yFact),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: translate(
                                                      'Mindset Days',
                                                      lang,
                                                    ),
                                                    style: TextStyle(
                                                      fontFamily: 'YesevaOne',
                                                      color: appTheme.onBackground,
                                                      fontSize: 22 * xFact,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '${state.totDays} ',
                                                    style: TextStyle(
                                                      fontFamily: 'YesevaOne',
                                                      color: appTheme.onPrimButtonGold,
                                                      fontSize: 22 * xFact,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 40 * yFact),
                                    ThreeTabSelector(
                                      labels: textScale >= 1.4
                                          ? [
                                              translate('Today', lang),
                                              translate('week', lang),
                                              translate('All time', lang),
                                            ]
                                          : [
                                              translate('Today', lang),
                                              translate('This week', lang),
                                              translate('All time', lang),
                                            ],
                                      index: period,
                                      enabled: !widget.fromOnboarding,
                                      onChanged: (i) {
                                        final changed = vm.setPeriod(
                                          i,
                                          fromOnboarding: widget.fromOnboarding,
                                        );
                                        if (changed) {
                                          _onPeriodUpdated();
                                        }
                                      },
                                    ),
                                    SizedBox(height: 30 * yFact),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: 18 * xFact,
                                        right: 18 * xFact,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 35 * xFact,
                                                child: Image.asset(
                                                  'assets/images/book.png',
                                                ),
                                              ),
                                              SizedBox(width: 20 * xFact),
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          '${state.quoteList[period]} ',
                                                      style: TextStyle(
                                                        fontFamily: 'InterTight',
                                                        color:
                                                            appTheme.onBackground,
                                                        fontSize: 22 * xFact,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: translate(
                                                        state.quoteList[period] ==
                                                                1
                                                            ? 'quote'
                                                            : 'quotes',
                                                        lang,
                                                      ),
                                                      style: TextStyle(
                                                        fontFamily: 'InterTight',
                                                        color:
                                                            appTheme.onBackground,
                                                        fontSize: 22 * xFact,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 25 * xFact,
                                          ),
                                          child: AnimatedWeeklyStats(
                                            values: state.valueList[period],
                                            nbrLabels: state.labels.length,
                                            onBoarding: false,
                                            controller: _statsC,
                                          ),
                                        ),
                                        Container(height: 2 * yFact),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 25 * xFact,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 25 * xFact,
                                                height: 10 * yFact,
                                              ),
                                              SizedBox(
                                                width: 250 * xFact,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: List.generate(
                                                    state.labels.length,
                                                    (i) {
                                                      final label =
                                                          state.labels[i];
                                                      return Column(
                                                        children: [
                                                          Text(
                                                            translate(
                                                              label
                                                                  .translationKey,
                                                              lang,
                                                            ),
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'InterTight',
                                                              fontSize:
                                                                  18 * xFact,
                                                              color: appTheme
                                                                  .onBackgroundSub,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: 3 * yFact,
                                                          ),
                                                          SizedBox(
                                                            width: 18 * xFact,
                                                            height: 18 * yFact,
                                                            child: Image.asset(
                                                              'assets/images/${label.imageName}',
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 30 * yFact),
                                    Text(
                                      translate(state.motivList[period], lang),
                                      style: TextStyle(
                                        fontFamily: 'InterTight',
                                        fontSize: 18 * xFact,
                                        fontStyle: FontStyle.italic,
                                        color: appTheme.onBackgroundSub,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (state.showFinalMask)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () {
                                if (widget.onFinalMaskTap != null) {
                                  widget.onFinalMaskTap!();
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  SafeArea(
                                    bottom: false,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 20 * xFact,
                                          top: 55 * yFact,
                                          child: SizedBox(
                                            height: 240 * xFact,
                                            child: Image.asset(
                                              'assets/images/flamy/flamy_glasses_thumb.png',
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: 40 * xFact,
                                            right: 40 * xFact,
                                            top: 300 * yFact,
                                          ),
                                          child: Text(
                                            translate(
                                              'mindset_points_final_text',
                                              lang,
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'YesevaOne',
                                              fontSize: 22 * xFact,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );

                if (shouldEnableScroll) {
                  return SingleChildScrollView(child: content);
                }
                return content;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ThreeTabSelector extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const ThreeTabSelector({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.enabled = true,
  }) : assert(labels.length == 3, 'Provide exactly 3 labels');

  @override
  Widget build(BuildContext context) {
    final Color active = appTheme.onBackground;
    final Color inactive = appTheme.onBackgroundSub;

    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double segmentW = constraints.maxWidth / 3;

        return SizedBox(
          height: 36 * yFact,
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Row(
                children: List.generate(3, (i) {
                  final bool selected = i == index;
                  return Expanded(
                    child: IgnorePointer(
                      ignoring: !enabled,
                      child: Opacity(
                        opacity: enabled ? 1.0 : 0.5,
                        child: InkWell(
                          onTap: enabled ? () => onChanged(i) : null,
                          borderRadius: BorderRadius.circular(6 * xFact),
                          child: Center(
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18 * xFact,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'InterTight',
                                color: selected ? active : inactive,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(
                width: segmentW * 3,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: appTheme.onBackgroundSub,
                      borderRadius: BorderRadius.circular(2 * xFact),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: index * segmentW,
                bottom: 0,
                child: SizedBox(
                  width: segmentW,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: appTheme.onBackground,
                        borderRadius: BorderRadius.circular(2 * xFact),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
