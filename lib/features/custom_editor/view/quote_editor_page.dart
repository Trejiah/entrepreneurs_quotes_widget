import 'dart:io';

import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/custom_editor/model/quote_editor_models.dart';
import 'package:businessmindset/features/custom_editor/view_model/quote_editor_provider.dart';
import 'package:businessmindset/features/custom_editor/view_model/quote_editor_ui_state.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuoteEditorPage extends ConsumerWidget {
  const QuoteEditorPage({super.key});

  Decoration _buildBackground(QuoteEditorUiState s) {
    final path = s.backgroundImagePath;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return BoxDecoration(
          image: DecorationImage(
            image: FileImage(file),
            fit: BoxFit.cover,
            alignment: Alignment(s.imageOffsetX, s.imageOffsetY),
          ),
        );
      }
      return BoxDecoration(color: s.bgColor);
    }
    return BoxDecoration(color: s.bgColor);
  }

  Future<void> _pickColor(
    BuildContext context,
    WidgetRef ref, {
    required bool background,
  }) async {
    final vm = ref.read(quoteEditorViewModelProvider.notifier);
    final state = ref.read(quoteEditorViewModelProvider);
    final initial = background ? state.bgColor : state.citationColor;
    final picked = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FlexPickerSheet(initial: initial),
    );
    if (picked == null) return;
    if (background) {
      vm.setBackgroundFromColor(picked);
    } else {
      vm.setCitationColor(picked);
    }
  }

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(quoteEditorViewModelProvider.notifier)
          .pickBackgroundImageFromGallery();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible de charger l'image.")),
        );
      }
    }
  }

  Future<void> _onSavePressed(BuildContext context, WidgetRef ref) async {
    final name = await ref
        .read(quoteEditorViewModelProvider.notifier)
        .saveCustomTheme(ref);
    if (!context.mounted) return;
    if (name != null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final state = ref.watch(quoteEditorViewModelProvider);
    final vm = ref.read(quoteEditorViewModelProvider.notifier);
    final safe = MediaQuery.paddingOf(context);
    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;
    final hasBgFile = state.backgroundImagePath != null &&
        File(state.backgroundImagePath!).existsSync();

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {},
            child: Stack(
              children: [
                hasBgFile
                    ? GestureDetector(
                        onPanUpdate: (details) {
                          vm.applyImagePanDelta(
                            details.delta.dx,
                            details.delta.dy,
                          );
                        },
                        child: Container(decoration: _buildBackground(state)),
                      )
                    : Container(decoration: _buildBackground(state)),
                Positioned(
                  top: safe.top + 20 * yFact,
                  left: 20 * xFact,
                  right: 20 * xFact,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HeaderIcon(
                        icon: Icons.close,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      GestureDetector(
                        onTap: () => _onSavePressed(context, ref),
                        child: Container(
                          width: 35 * xFact,
                          height: 35 * xFact,
                          decoration: BoxDecoration(
                            color: appTheme.background,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.check,
                            color: appTheme.onBackground,
                            size: 30 * xFact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: IgnorePointer(
                    ignoring: true,
                    child: Text(
                      translate('thisishowitlooks', lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: state.fontFamily,
                        fontSize: vm.resolvedFontSize * xFact,
                        color: state.citationColor,
                        height: 1.2 * yFact,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20 * xFact,
            right: 20 * xFact,
            bottom: 20 * yFact,
            child: GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20 * xFact),
                child: Container(
                  decoration: BoxDecoration(color: appTheme.onBackgroundSub),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ControlBar(
                        title: 'Background',
                        actions: [
                          _MiniIconButton(
                            icon: 'photo.png',
                            onTap: () => _pickImage(context, ref),
                          ),
                          SizedBox(width: 30 * xFact),
                          _RoundSwatch(
                            color: state.bgColor,
                            onTap: () => _pickColor(context, ref,
                                background: true),
                          ),
                        ],
                      ),
                      SizedBox(height: 2 * yFact),
                      _ControlBar(
                        title: 'Text',
                        actions: [
                          _FontMenu(
                            onClic: () {},
                            fonts: kQuoteEditorFontFamilies,
                            selected: state.fontFamily,
                            onSelected: (f) =>
                                vm.setFontFamily(f),
                          ),
                          SizedBox(width: 30 * xFact),
                          _RoundSwatch(
                            color: state.citationColor,
                            onTap: () => _pickColor(context, ref,
                                background: false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 35 * xFact,
        height: 35 * yFact,
        decoration: BoxDecoration(
          color: appTheme.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20 * xFact),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 22 * xFact, color: Colors.white),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  _ControlBar({required this.title, required this.actions});

  final String title;
  final List<Widget> actions;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52 * xFact,
      decoration: BoxDecoration(
        color: appTheme.background,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12 * xFact),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'InterTight',
                fontSize: 18 * xFact,
                fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

class _RoundSwatch extends StatelessWidget {
  _RoundSwatch({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30 * xFact,
        height: 30 * yFact,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white,
              width: 1.5 * xFact),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  _MiniIconButton({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32 * xFact,
        height: 32 * yFact,
        alignment: Alignment.center,
        child: Image.asset('assets/images/$icon'),
      ),
    );
  }
}

class _FontMenu extends StatelessWidget {
  const _FontMenu({
    required this.fonts,
    required this.selected,
    required this.onClic,
    required this.onSelected,
  });

  final List<String> fonts;
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onClic;

  @override
  Widget build(BuildContext context) {
    final xFact = ScreenScale.x, yFact = ScreenScale.y;

    return PositionedMenuButton(
      items: fonts,
      onSelected: onSelected,
      onOpened: onClic,
      menuSize: Size(300 * xFact, 200 * yFact),
      child: SizedBox(
        width: 28 * xFact,
        height: 28 * yFact,
        child: Center(
          child: Text(
            'Aa',
            style: TextStyle(
              fontFamily: selected,
              fontSize: 22 * xFact,
              color: appTheme.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlexPickerSheet extends ConsumerStatefulWidget {
  const _FlexPickerSheet({required this.initial});
  final Color initial;

  @override
  ConsumerState<_FlexPickerSheet> createState() => _FlexPickerSheetState();
}

class _FlexPickerSheetState extends ConsumerState<_FlexPickerSheet> {
  late Color _current;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: appTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20 * yFact)),
        ),
        padding: EdgeInsets.all(16 * xFact),
        child: ListView(
          controller: scrollCtrl,
          children: [
            SizedBox(height: 12 * yFact),
            Text(translate('colorchoose', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22 * xFact,
                    fontFamily: 'YesevaOne',
                    color: appTheme.onBackground,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 12 * yFact),
            ColorPicker(
              color: _current,
              onColorChanged: (c) => setState(() => _current = c),
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.wheel: true,
                ColorPickerType.primary: false,
                ColorPickerType.accent: false,
                ColorPickerType.both: false,
                ColorPickerType.custom: false,
              },
              enableShadesSelection: false,
              enableOpacity: false,
              showColorCode: false,
              colorCodeReadOnly: false,
              colorCodeHasColor: true,
              wheelDiameter: 270 * xFact,
              wheelHasBorder: true,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 100 * yFact,
              decoration: BoxDecoration(
                color: _current,
                borderRadius: BorderRadius.circular(14 * xFact),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.15),
                  width: 1.2 * xFact,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8 * xFact,
                    offset: const Offset(0, 2),
                    color: const Color(0x33000000),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20 * yFact),
            Row(
              children: [
                Expanded(
                  child: TertiaryButton(
                    height: 40 * yFact,
                    text: translate('cancel', lang),
                    onTap: () => Navigator.pop(context),
                    textSize: 18,
                  ),
                ),
                SizedBox(width: 12 * xFact),
                Expanded(
                  child: SecondaryButton(
                    height: 40 * yFact,
                    text: translate('apply', lang),
                    onTap: () => Navigator.pop<Color>(context, _current),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PositionedMenuButton extends StatefulWidget {
  const PositionedMenuButton({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
    this.menuSize = const Size(300, 280),
    this.onOpened,
  });

  final Widget child;
  final List<String> items;
  final ValueChanged<String> onSelected;
  final Size menuSize;
  final VoidCallback? onOpened;

  @override
  State<PositionedMenuButton> createState() => _PositionedMenuButtonState();
}

class _PositionedMenuButtonState extends State<PositionedMenuButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  Offset _tapPos = Offset.zero;
  final ScrollController _scrollCtrl = ScrollController();
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 120),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuad);

    _scale = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  void _showMenuAt(Offset globalPos) {
    if (_entry != null) return;
    widget.onOpened?.call();

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hide,
              onPanStart: (_) => _hide(),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10 * yFact),
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    alignment: Alignment.bottomCenter,
                    child: Material(
                      elevation: 10,
                      color: appTheme.settingsButton,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * xFact),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: widget.menuSize.width,
                          maxWidth: widget.menuSize.width,
                          maxHeight: MediaQuery.of(context).size.height * 0.60,
                        ),
                        child: RawScrollbar(
                          controller: _scrollCtrl,
                          thumbVisibility: true,
                          trackVisibility: false,
                          thickness: 4 * xFact,
                          radius: Radius.circular(3 * xFact),
                          minThumbLength: 0,
                          mainAxisMargin: 0,
                          crossAxisMargin: 0,
                          child: ListView.separated(
                            controller: _scrollCtrl,
                            shrinkWrap: true,
                            primary: false,
                            padding: EdgeInsets.zero,
                            physics: const ClampingScrollPhysics(),
                            itemCount: widget.items.length,
                            separatorBuilder: (_, __) => Divider(
                                height: 1 * yFact,
                                thickness: 1 * xFact,
                                color: appTheme.background),
                            itemBuilder: (context, i) {
                              final f = widget.items[i];
                              return InkWell(
                                onTap: () {
                                  widget.onSelected(f);
                                  _hide();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14 * xFact,
                                      vertical: 10 * yFact),
                                  child: Center(
                                    child: Text(
                                      f,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18 * xFact,
                                        fontFamily: f,
                                        color: appTheme.onBackground,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ]);
      },
    );
    Overlay.of(context).insert(_entry!);
    _ctrl.forward();
  }

  Future<void> _hide() async {
    if (_entry == null) return;
    await _ctrl.reverse();
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    try {
      _entry?.remove();
      _entry = null;
    } catch (_) {}
    _scrollCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (d) {
        _tapPos = d.globalPosition;
      },
      onTap: () => _showMenuAt(_tapPos),
      child: widget.child,
    );
  }
}
