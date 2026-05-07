import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';


import 'package:flutter/foundation.dart';

class sf extends StatefulWidget {
  const sf({super.key});

  @override
  State<sf> createState() => _sfState();
}

class _sfState extends State<sf> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}


class _AppBaseButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final bool center;

  // Couleurs/gradient + texte
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Color textColor;

  // Optional icon (right-aligned)
  final IconData? icon;
  final Color? iconColor;
  final double iconSize;
  final int textSize;
  final double iconRightPadding;

  final Widget? trailing;
  final Widget? leading;
  final double gap;
  final bool? checked;
  final bool? isChecked;

  const _AppBaseButton({
    required this.text,
    required this.onTap,
    required this.height,
    required this.borderRadius,
    required this.textColor,
    this.leading,
    this.backgroundColor,
    this.backgroundGradient,
    this.borderColor,
    this.borderWidth = 0,
    required this.center,
    this.icon,
    this.iconColor,
    this.textSize = 18,
    this.iconSize = 22,
    this.iconRightPadding = 16,
    this.trailing,
    this.gap = 8,
    this.checked = false,
    this.isChecked = false,
  });

@override
State<_AppBaseButton> createState() => _AppBaseButtonState();
}

class _AppBaseButtonState extends State<_AppBaseButton> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    isChecked = widget.isChecked!;
  }

  @override
  void didUpdateWidget(covariant _AppBaseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    isChecked = widget.isChecked!;
  }

  @override
  Widget build(BuildContext context) {
    final childText = Text(
      widget.text,
      style: TextStyle(
        color: isChecked ? appTheme.onSecButton : widget.textColor,
        fontFamily: 'InterTight',
        fontWeight: FontWeight.w400,
        fontSize: widget.textSize*xFact,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    Widget content;
    if (widget.leading != null || widget.trailing != null) {
      content = Row(
        mainAxisAlignment:
        widget.center ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (widget.leading != null) widget.leading!,
          if (widget.leading != null) SizedBox(width: widget.gap*xFact),
          Flexible(child: childText),
          if (widget.trailing != null) ...[
            SizedBox(width: widget.gap*xFact),
            widget.trailing!,
          ],
        ],
      );
    } else {
      content = childText;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius*xFact),
        onTap: (){
          if(widget.checked == true) {
            setState(() {
              isChecked = true;
              debugPrint("isChecked : $isChecked");
            });
          }
          widget.onTap?.call();
        },
        child: Ink(
          height: widget.height*yFact,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isChecked ? appTheme.lowButtonGold : widget.backgroundColor,
            gradient: widget.backgroundGradient,
            borderRadius: BorderRadius.circular(widget.borderRadius*xFact),
            border: (widget.borderColor != null && widget.borderWidth*xFact > 0)
                ? Border.all(color: widget.borderColor!, width: widget.borderWidth*xFact)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered OR left-aligned text: for the tertiary
              if (widget.center)
                Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isChecked ? appTheme.onSecButton : widget.textColor,
                    fontFamily: 'InterTight',
                    fontWeight: FontWeight.w600,
                    fontSize: widget.textSize*xFact,
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 15*xFact,right: 15),
                    child: content,
                  ),
                ),

              // Icon on the right, if provided
              if (widget.icon != null)
                Positioned(
                  right: widget.iconRightPadding*xFact,
                  child: Icon(
                    widget.icon,
                    size: widget.iconSize*xFact,
                    color: widget.iconColor ?? widget.textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final bool center;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  // Optional icon
  final IconData? icon;
  final Color? iconColor;
  final double iconSize;
  final double iconRightPadding;

  PrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.center = true,
    this.height = 50,
    this.borderRadius = 20,
    this.icon,
    this.iconColor,
    this.iconSize = 22,
    this.iconRightPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return _AppBaseButton(
      text: text,
      onTap: onTap,
      height: height,
      borderRadius: borderRadius,
      textColor: appTheme.onPrimButton,
      backgroundColor: appTheme.primButtonGradient.color,
      backgroundGradient: appTheme.primButtonGradient.gradient,
      center: center,
      icon: icon,
      iconColor: iconColor ?? appTheme.onPrimButton,
      iconSize: iconSize,
      iconRightPadding: iconRightPadding,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final bool center;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  SecondaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.height = 50,
    this.borderRadius = 20,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    return _AppBaseButton(
      text: text,
      onTap: onTap,
      height: height,
      borderRadius: borderRadius,
      textColor: appTheme.onSecButton,
      backgroundColor: appTheme.secButtonGradient.color,
      backgroundGradient: appTheme.secButtonGradient.gradient,
      center: center,
    );
  }
}


class TertiaryButton2 extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final double borderWidth;
  final bool center;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  TertiaryButton2({
    super.key,
    required this.text,
    required this.onTap,
    this.height = 50,
    this.borderRadius = 20,
    this.borderWidth = 1.5,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    return _AppBaseButton(
      text: text,
      onTap: onTap,
      height: height,
      borderRadius: borderRadius,
      textColor: appTheme.onTertButton,
      backgroundColor: appTheme.tertButtonGradient.color,
      backgroundGradient: appTheme.tertButtonGradient.gradient,
      borderColor: appTheme.containerTertButton,
      borderWidth: borderWidth,
      center: center,
    );
  }
}


class TertiaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final double borderWidth;
  final bool center;
  final bool checked;
  final bool isChecked;
  final Color? textColor;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Color? borderColor;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final int? textSize;

  TertiaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.height = 48,
    this.checked = false,
    this.isChecked = false,
    this.borderRadius = 20,
    this.borderWidth = 1.5,
    this.center = true,
    this.textColor,
    this.backgroundColor,
    this.backgroundGradient,
    this.borderColor,
    this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    return _AppBaseButton(
      checked: checked,
      isChecked: isChecked,
      text: text,
      onTap: onTap,
      height: height,
      borderRadius: borderRadius,
      textColor: textColor ?? appTheme.onTertButton,
      backgroundColor: backgroundColor ?? appTheme.tertButtonGradient.color,
      backgroundGradient: backgroundGradient ?? appTheme.tertButtonGradient.gradient,
      borderColor: borderColor ?? appTheme.containerTertButton,
      borderWidth: borderWidth,
      center: center,
      textSize: textSize ?? 22,
    );
  }
}

class TertiaryCheckButton extends StatelessWidget {
  final String text;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap; // si tu veux une action en plus du toggle
  final double height;
  final double borderRadius;
  final double borderWidth;
  final bool center;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  TertiaryCheckButton({
    super.key,
    required this.text,
    required this.checked,
    required this.onChanged,
    this.onTap,
    this.height = 50,
    this.borderRadius = 20,
    this.borderWidth = 1.5,
    this.center = false, // on laisse la place au trailing
  });

  @override
  Widget build(BuildContext context) {
    return _AppBaseButton(
      text: text,
      onTap: () {
        onChanged(!checked);      // toggle au tap
        onTap?.call();
      },
      height: height,
      borderRadius: borderRadius,
      textColor: appTheme.onTertButton,
      backgroundColor: appTheme.tertButtonGradient.color,
      backgroundGradient: appTheme.tertButtonGradient.gradient,
      borderColor: appTheme.containerTertButton,
      borderWidth: borderWidth,
      center: center,
      trailing: RoundCheck(
        checked: checked,
        // you can also do onTap here if you want only the dot to toggle
        // onTap: () => onChanged(!checked),
      ),
      gap: 10,
    );
  }
}

/// Round badge styled as a "checkbox"
class RoundCheck extends StatelessWidget {
  final bool checked;
  final VoidCallback? onTap;
  RoundCheck({super.key, required this.checked, this.onTap});
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  Widget build(BuildContext context) {
    final bg = checked ? Colors.transparent : Colors.transparent;
    final fg = checked ? appTheme.onTertButton : appTheme.onTertButton; //Modifier la couleur quand check ?

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 27*xFact,
        height: 27*xFact,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: appTheme.onTertButton, width: 1),
        ),
        child: checked
            ? Icon(Icons.check, size: 16*xFact, color: fg)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class LoupeTextField extends StatefulWidget  {
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String? fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final String? hintText;
  final String? inputStyle;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const LoupeTextField({
    super.key,
    this.width = double.maxFinite,
    this.height = 50,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.textColor = Colors.black,
    this.fontFamily,
    this.inputStyle,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.hintText,
    this.maxLength,
    required this.onChanged,
  });

  @override
  State<LoupeTextField> createState() => _LoupeTextFieldState();
}

class _LoupeTextFieldState extends State<LoupeTextField> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final txt = _controller.text;
      widget.onChanged?.call(txt); // ✅ remonte le texte à chaque caractère
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      //inputFormatters: [
      //         if(widget.inputStyle == "input1") FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\- ]')),
      //         if (widget.maxLength != null)
      //           LengthLimitingTextInputFormatter(widget.maxLength),
      //       ],
      textInputAction: TextInputAction.done,
      onEditingComplete: () => FocusScope.of(context).unfocus(),
      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
      controller: _controller,
      keyboardType: TextInputType.multiline,   // ✅ permet les retours à la ligne
      textAlignVertical: TextAlignVertical.top,
      //maxLines: 5, // nombre de lignes visibles max
      //minLines: 1,
      maxLines:null,
      expands: true,

      style: TextStyle(
        color: appTheme.onTextField,
        fontFamily: widget.fontFamily,
        fontSize: widget.fontSize*xFact,
        fontWeight: widget.fontWeight,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: appTheme.onTextField,
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize * 0.95*yFact,
        ),
        filled: true,
        fillColor: appTheme.settingsButton,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12 * xFact,
          vertical: 14 * yFact,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10*xFact),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10*xFact),
        ),
      ),
    );
    // Ajustement largeur/hauteur
    return SizedBox(
      width: widget.width! * xFact,
      height: widget.height! * yFact,
      child: Stack(
        children: [
          field,
        ],
      ),
    );
  }
}


class CustomTextField extends StatefulWidget  {
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String? fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final String? hintText;
  final String? inputStyle;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;
  final TextInputAction? textInputAction;
  final int? minLines;
  final int? maxLines;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    this.width = double.maxFinite,
    this.height = 50,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.textColor = Colors.black,
    this.fontFamily,
    this.inputStyle,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.hintText,
    this.maxLength,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.textInputAction,
    this.minLines,
    this.maxLines,
    this.onTap,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  late final TextEditingController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    // Use the provided controller or create a new one
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isInternalController = true;
    }
    _controller.addListener(() {
      final txt = _controller.text;
      widget.onChanged?.call(txt); // ✅ remonte le texte à chaque caractère
    });
  }

  @override
  void dispose() {
    // Only dispose if it's an internal controller
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Compute the base font size
    final baseFontSize = widget.fontSize * xFact;
    
    // The field is always multiline to allow automatic line wrapping
    // Use maxLines: null to allow unlimited automatic expansion
    final field = TextFormField(
      onTap: widget.onTap,
      focusNode: widget.focusNode,
      inputFormatters: [
        if(widget.inputStyle == "input1") FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\- ]')),
        if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      textInputAction: widget.textInputAction ?? TextInputAction.newline,
      onEditingComplete: () {
        widget.onSubmitted?.call();
        if (widget.focusNode != null) {
          widget.focusNode!.unfocus();
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      onFieldSubmitted: (_) {
        widget.onSubmitted?.call();
        if (widget.focusNode != null) {
          widget.focusNode!.unfocus();
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      controller: _controller,
      keyboardType: TextInputType.multiline, // Toujours multiline pour permettre le retour à la ligne
      textAlign: TextAlign.left,
      textAlignVertical: TextAlignVertical.top, // Toujours top pour multiline
      maxLines: widget.maxLines ?? null, // Utiliser maxLines si fourni, sinon null pour expansion illimitée
      minLines: widget.minLines ?? 1, // Utiliser le minLines fourni ou 1 par défaut
      expands: false, // Ne pas utiliser expands pour permettre l'expansion progressive

      style: TextStyle(
        color: appTheme.onBackground,
        fontFamily: widget.fontFamily,
        fontSize: baseFontSize,
        fontWeight: widget.fontWeight,
        overflow: TextOverflow.visible, // Permettre l'overflow pour voir toutes les lignes
        height: 1.2, // Hauteur de ligne
      ),
      decoration: InputDecoration(
        isCollapsed: false, // Ne pas utiliser isCollapsed pour permettre l'expansion
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: appTheme.onTextField,
          fontFamily: widget.fontFamily,
          fontSize: (baseFontSize * 0.95).clamp(8.0, widget.fontSize * 0.95 * xFact),
        ),
        filled: true,
        fillColor: appTheme.textField,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12 * xFact,
          vertical: 14 * yFact,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF504b41).withAlpha(90), width: 1),
          borderRadius: BorderRadius.circular(20*xFact),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF504b41).withAlpha(90), width: 1),
          borderRadius: BorderRadius.circular(20*xFact),
        ),
      ),
    );
    
    // Return the field without fixed height - it will adapt automatically
    return SizedBox(
      width: widget.width! * xFact,
      child: field,
    );
  }
}

class SettingsButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final double iconSize;
  final double spacing;
  final String fontFamily;
  final double fontSize;
  final bool isLocked;

  const SettingsButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.iconSize = 30,
    this.spacing = 15,
    this.fontFamily = "InterTight",
    this.fontSize = 18,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? appTheme.onBackground;
    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: appTheme.settingsButton,
            ),
            child: Opacity(
              opacity: isLocked ? 0.5 : 1.0,
              child: Padding(
                padding: EdgeInsets.only(top: 12*yFact,bottom: 12*yFact,left: 20*xFact),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1.0,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: iconSize*xFact,
                          child: Image.asset("assets/images/$icon"),
                        ),
                        SizedBox(width: spacing*xFact),
                        Text(
                          label,
                          style: TextStyle(
                            color: isLocked
                                ? textColor.withOpacity(0.5)
                                : textColor,
                            fontFamily: fontFamily,
                            fontSize: fontSize*xFact,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Lock icon positioned in the top-right corner
          if (isLocked)
            Positioned(
              top: 8 * yFact,
              right: 8 * xFact,
              child: Opacity(
                opacity: 0.5,
                child: SizedBox(
                  width: 20 * xFact,
                  height: 20 * yFact,
                  child: Image.asset("assets/images/cadenas.png"),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  final String leftIcon;
  final String rightIcon;
  final String label;
  final VoidCallback onQuoteTap;
  final VoidCallback onTap;
  final Color? color;
  final double iconSize;
  final double spacing;
  final String fontFamily;
  final double fontSize;

  const FavoriteButton({
    super.key,
    required this.leftIcon,
    required this.rightIcon,
    required this.label,
    required this.onQuoteTap,
    required this.onTap,
    this.color,
    this.iconSize = 30,
    this.spacing = 15,
    this.fontFamily = "InterTight",
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? appTheme.onBackground;
    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;

    return Container(
      height: 100*yFact,
      width: double.maxFinite,
      decoration: BoxDecoration(
          color: appTheme.settingsButton,
          borderRadius: BorderRadius.circular(10*xFact)
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 12*yFact,bottom: 12*yFact,left: 20*xFact,right: 20*xFact),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onTap,
              child: SizedBox(
                width: iconSize*xFact,
                child: Image.asset("assets/images/$leftIcon"),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontFamily: fontFamily,
                fontSize: fontSize*xFact,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: onQuoteTap,
              child: rightIcon.isEmpty
                  ? SizedBox(width: iconSize * xFact) // espace vide
                  : SizedBox(
                width: iconSize * xFact,
                child: Image.asset("assets/images/$rightIcon"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteButton2 extends StatelessWidget {
  final String leftIcon;   // ex: "heart_filled.png"
  final String rightIcon;  // ex: "send.png"
  final String label;      // texte de la citation
  final String dateLabel;  // ex: "30 octobre 2025"
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;
  final Color? color;
  final double iconSize;
  final String fontFamily;
  final double fontSize;

  const FavoriteButton2({
    super.key,
    required this.leftIcon,
    required this.rightIcon,
    required this.label,
    required this.dateLabel,
    required this.onLeftTap,
    required this.onRightTap,
    this.color,
    this.iconSize = 28,
    this.fontFamily = "InterTight",
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? appTheme.onBackground;
    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;

    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: appTheme.settingsButton,
        borderRadius: BorderRadius.circular(10 * xFact),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 15 * xFact,
          vertical: 10 * yFact,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Texte principal
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontFamily: fontFamily,
                fontSize: fontSize * xFact,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(
                height: 15 * yFact
            ),
            // Bottom row: date + icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: appTheme.onBackgroundSub,
                    fontFamily: fontFamily,
                    fontSize: (fontSize - 3) * xFact,
                  ),
                ),
                Row(
                  children: [
                    // Right arrow button (send)
                    GestureDetector(
                      onTap: onRightTap,
                      child: rightIcon.isEmpty
                          ? SizedBox(width: iconSize * xFact)
                          : Padding(
                        padding: EdgeInsets.only(right: 12 * xFact),
                        child: Image.asset(
                          "assets/images/$leftIcon",
                          width: iconSize * xFact,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10*xFact,
                    ),
                    // Bouton cœur gauche (like)
                    GestureDetector(
                      onTap: onLeftTap,
                      child: leftIcon.isEmpty
                          ? SizedBox(width: iconSize * xFact)
                          : Image.asset(
                        "assets/images/$rightIcon",
                        width: iconSize * xFact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
