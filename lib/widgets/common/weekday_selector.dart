import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/habits_provider.dart';
import '../../core/global_scaler.dart';

class WeekdaySelector extends ConsumerStatefulWidget {
  const WeekdaySelector({
    super.key,
    required this.onChanged,
    this.enabled = true,
  });
  final ValueChanged<List<bool>>? onChanged;
  final bool enabled;

  @override
  ConsumerState<WeekdaySelector> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends ConsumerState<WeekdaySelector> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  List<bool> daySelected = List.filled(7, true);
  @override
  void initState() {
    super.initState();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 1) Determine the local order (without modifying the provider yet)
    final locale = Localizations.localeOf(context);
    final startsOnSunday = locale.countryCode == 'US';

    // 2) Defer the provider update AFTER the current build
    Future.microtask(() {
      if (!mounted) return;
      ref.read(startsOnSundayProvider.notifier).state = startsOnSunday;
    });

    // 3) Load the **localized** day names once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final localized = ref.read(daySelectedLocalizedProvider);
      setState(() => daySelected = localized);
    });
  }

  void callDays(List<bool> localizedDays) {
    if(kDebugMode){
      debugPrint("daySelected in callDays: $daySelected");
    }
    widget.onChanged?.call(localizedDays);
  }


  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final startsOnSunday = locale.countryCode == 'US';

    // Labels in display order
    List<String> days = startsOnSunday
        ? ['S', 'M', 'T', 'W', 'T', 'F', 'S']   // US: Sun-first
        : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];  // Others: Mon-first
    if (locale.languageCode == 'fr') {
      // (Option: use 'L','Ma','Me','J','V','S','D' if you want distinct letters)
      days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(days.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: widget.enabled ? () {
              setState(() {
                daySelected[index] = !daySelected[index];
              });
              callDays(List<bool>.from(daySelected));
            } : null,
            child: Opacity(
              opacity: widget.enabled ? (daySelected[index] ? 1.0 : 0.55) : 0.3,
              child: CircleAvatar(
                radius: 18*xFact,
                backgroundColor: appTheme.secButton,
                child: Text(
                  days[index],
                  style: TextStyle(
                    color: appTheme.onSecButton,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}