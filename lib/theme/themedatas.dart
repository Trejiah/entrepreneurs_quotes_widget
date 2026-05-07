import 'dart:convert';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/image_utils.dart';



final List<Map<String, dynamic>> allAppThemes = [
    blackTheme,//0
    greenTheme,
    lightPinkTheme,
    pinkTheme,
    lightYellowTheme,
    lightPurpleTheme,//5
    lightBlueTheme,
    skinTheme,
    littlePurpleTheme,
    littleSkinTheme,
    littleGreenTheme,//10
    blueGreenTheme,
    veryLightBlueTheme,
    greenBlueTheme,
    redBlueTheme,
    blueBlueBlueTheme,//15
    yellowBlueTheme,
    whitePurpleTheme,
    purplePinkTheme,
    skinGreenTheme,
    skinRedTheme,//20
    lightBlueWhiteTheme,
    pinkBlueTheme,
    blueRedTheme,
    skylineTheme,
    skyline2Theme,//25
    landscapeTheme,
    skymountainTheme,
    moonTheme,
    beachTheme,
    ferrariTheme,//30
    mountainTheme,
    snowmoutainTheme,
    landscape10Theme,
    eiffelTheme,
    dubaiTheme,//35
    forestTheme,
    lagoonTheme,
    beach15Theme,
    riceTheme,
    boatTheme,//40
    sandTheme,
    sky20Theme,
    seaTheme,
    birdsTheme,
    bridgeTheme,//45
    marbreTheme,
    blackmarbreTheme,
    city26Theme,
    lights27Theme,
    dunesTheme,//50
    redmoutainTheme,
    water30Theme,
    city31Theme,
    sky32Theme,
    lights33Theme,//55
    mongolfiereTheme,
    sky35Theme,
    planeTheme,
    cloudsTheme,
    flowersTheme,//60
    fungusTheme,
    water40Theme,
    forest41Theme,
    sky42Theme,
    sakuraTheme,//65
    milkywayTheme,
    auroreTheme,
  ];
///reference interTight font size: 22, corresponds to 52
///so if we're at 58, font = 58/52 * 22
///Color theme listing
final textSize1 = 22;
final textSize2 = 54/52 * textSize1;
final textSize3 = 56/52 * textSize1;
final textSize4 = 58/52 * textSize1;
final textSize5 = 60/52 * textSize1;
final textSize6 = 62/52 * textSize1;

/// Font size mapping by font family
/// Based on the analysis of all themes in allAppThemes
/// Each font has a fixed size to ensure consistency
final Map<String, double> fontFamilyToSize = {
  "InterTight": textSize3,
  "YesevaOne": textSize3,
  "DidactGothic": textSize3,
  "JosefinSlab": textSize5,
  "Raleway": textSize3,
  "AbhayaLibre": textSize5,
  "Allerta": textSize3,
  "BebasNeue": textSize4,
  "BodoniModa": textSize4,
  "CormorantGaramond": textSize6,
  "EBGaramond": textSize6,
  "JosefinSans": textSize4,
  "Lato": textSize3,
  "LibreBaskerville": textSize5,
  "Lustria": textSize3,
  "MontSerrat": textSize5,
  "Oranlenbaum": textSize4,
  "Oswald": textSize4,
  "Ovo": textSize4,
  "PlayfairDisplay": textSize4,
  "Quicksand": textSize3,
  "Sanchez": textSize3,
  "SourceSansPro": textSize6,
  "Volkorn": textSize3,
};

Map<String,dynamic> blackTheme =
{
  "color1" : 0xFF1f1f1f,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "JosefinSlab",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize5,
  "name" : "Black",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> greenTheme =
{
  "color1" : 0xFFa2f1a7,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "DidactGothic",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "Green",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> lightPinkTheme =
{
  "color1" : 0xFFf8d4c6,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "Raleway",
  "fontcolor" : 0xFF000000,
  "fontsize" : textSize3,
  "name" : "LightPink",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> pinkTheme =
{
  "color1" : 0xFFfd608e,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "InterTight",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "Pink",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> lightYellowTheme =
{
  "color1" : 0xFFfef6bb,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "InterTight",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "LightYellow",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> lightPurpleTheme =
{
  "color1" : 0xFFf6d8fc,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "Lustria",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "LightPurple",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> lightBlueTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "BebasNeue",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize4,
  "name" : "LightBlue",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> skinTheme =
{
  "color1" : 0xFFf9d1a5,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "Volkorn",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "Skin",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> littlePurpleTheme =
{
  "color1" : 0xFF4865fd,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "SourceSansPro",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize6,
  "name" : "LittlePurple",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> littleSkinTheme =
{
  "color1" : 0xFFfbf4ed,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "Sanchez",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "LittleSkin",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> littleGreenTheme =
{
  "color1" : 0xFF86f5cc,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "Lato",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "LittleGreen",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> blueGreenTheme =
{
  "color1" : 0xFFabbde0,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "EBGaramond",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize6,
  "name" : "BlueGreen",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> veryLightBlueTheme =
{
  "color1" : 0xFF10eaff,
  "color2" : 0xff29918a,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.0,
  "p3" : 0.0,
  "nbrcolor" : 1,
  "fontfamily" : "InterTight",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "VeryLightBlue",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> greenBlueTheme =
{
  "color1" : 0xFF72fa93,
  "color2" : 0xff9ac1f0,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.85,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "InterTight",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "GreenBlue",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> redBlueTheme =
{
  "color1" : 0xFFf9858b,
  "color2" : 0xff9ac1f0,
  "color3" : 0xffe09571,
  "p1" : 0.0,
  "p2" : 0.74,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "InterTight",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "RedBlue",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> blueBlueBlueTheme =
{
  "color1" : 0xFFb5e5e7,
  "color2" : 0xff7dd1df,
  "color3" : 0xff1e95d4,
  "p1" : 0.15,
  "p2" : 0.55,
  "p3" : 0.92,
  "nbrcolor" : 3,
  "fontfamily" : "MontSerrat",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize5,
  "name" : "BlueBlueBlue",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> yellowBlueTheme =
{
  "color1" : 0xFFffcf43,
  "color2" : 0xff5ce0d8,
  "color3" : 0xff1e95d4,
  "p1" : 0.0,
  "p2" : 0.81,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Allerta",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "YellowBlue",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> whitePurpleTheme =
{
  "color1" : 0xFFffffff,
  "color2" : 0xff903b6b,
  "color3" : 0xff1e95d4,
  "p1" : 0.0,
  "p2" : 0.85,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "PlayfairDisplay",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize4,
  "name" : "WhitePurple",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> purplePinkTheme =
{
  "color1" : 0xFFfcc5f9,
  "color2" : 0xfff38283,
  "color3" : 0xff1e95d4,
  "p1" : 0.20,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "InterTight",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "PurplePink",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> skinGreenTheme =
{
  "color1" : 0xFFf8d4c6,
  "color2" : 0xffa0efa5,
  "color3" : 0xff1e95d4,
  "p1" : 0.19,
  "p2" : 0.85,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "JosefinSans",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize4,
  "name" : "SkinGreen",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> skinRedTheme =
{
  "color1" : 0xFFf8d4c6,
  "color2" : 0xfffd608e,
  "color3" : 0xffd4305f,
  "p1" : 0.06,
  "p2" : 0.59,
  "p3" : 0.85,
  "nbrcolor" : 3,
  "fontfamily" : "YesevaOne",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "SkinRed",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> lightBlueWhiteTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xff16dcdb,
  "color3" : 0xff1edec7,
  "p1" : 0.0,
  "p2" : 0.47,
  "p3" : 1.0,
  "nbrcolor" : 3,
  "fontfamily" : "Quicksand",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "LightBlueWhite",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> pinkBlueTheme =
{
  "color1" : 0xFFf6d8fc,
  "color2" : 0xff0fdbee,
  "color3" : 0xffd4305f,
  "p1" : 0.16,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "BodoniModa",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize4,
  "name" : "PinkBlue",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> blueRedTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "BebasNeue",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize4,
  "name" : "blueRed",
  "isImage" : false,
  "imageName" : "",
};
Map<String,dynamic> skylineTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "BodoniModa",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize4,
  "name" : "Skyline New York",
  "isImage" : true,
  "imageName" : "1_skyline.jpg",
};
Map<String,dynamic> skyline2Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "DidactGothic",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Skyline Toronto",
  "isImage" : true,
  "imageName" : "2_skyline.jpg",
};
Map<String,dynamic> landscapeTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "MontSerrat",
  "fontcolor" : 0xFFffffff,
  "fontsize" : textSize5,
  "name" : "Mountain Path",
  "isImage" : true,
  "imageName" : "3_landscape.jpg",
};
Map<String,dynamic> skymountainTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "PlayfairDisplay",
  "fontcolor" : 0xFF000000,
  "fontsize" : textSize4,
  "name" : "Sky Mountain",
  "isImage" : true,
  "imageName" : "4_skymountain.jpg",
};
Map<String,dynamic> moonTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "LibreBaskerville",
  "fontcolor" : 0xFFffffff,
  "fontsize" : textSize5,
  "name" : "Full Moon",
  "isImage" : true,
  "imageName" : "5_moon.jpg",
};
Map<String,dynamic> beachTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "SourceSansPro",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize6,
  "name" : "Sunny Beach",
  "isImage" : true,
  "imageName" : "6_beach.jpg",
};
Map<String,dynamic> ferrariTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Sanchez",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Red Ferrari",
  "isImage" : true,
  "imageName" : "7_ferrari.jpg",
};
Map<String,dynamic> mountainTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "JosefinSans",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize4,
  "name" : "Snowy Peaks",
  "isImage" : true,
  "imageName" : "8_mountain.jpg",
};
Map<String,dynamic> snowmoutainTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Lato",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Snowy Mountain",
  "isImage" : true,
  "imageName" : "9_snowmoutain.jpg",
};
Map<String,dynamic> landscape10Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Raleway",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Golden Field",
  "isImage" : true,
  "imageName" : "10_landscape.jpg",
};
Map<String,dynamic> eiffelTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Allerta",
  "fontcolor" : 0xFFffffff,
  "fontsize" : textSize3,
  "name" : "Paris Eiffel",
  "isImage" : true,
  "imageName" : "11_eiffel.jpg",
};
Map<String,dynamic> dubaiTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Lustria",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Dubai Skyline",
  "isImage" : true,
  "imageName" : "12_dubai.jpg",
};
Map<String,dynamic> forestTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "InterTight",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Forest Path",
  "isImage" : true,
  "imageName" : "13_forest.jpg",
};
Map<String,dynamic> lagoonTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Oranlenbaum",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize4,
  "name" : "Sunset Lagoon",
  "isImage" : true,
  "imageName" : "14_lagoon.jpg",
};
Map<String,dynamic> beach15Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "YesevaOne",
  "fontcolor" : 0xFF000000,
  "fontsize" : textSize3,
  "name" : "Blue Lagoon",
  "isImage" : true,
  "imageName" : "15_beach.jpg",
};
Map<String,dynamic> riceTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "AbhayaLibre",
  "fontcolor" : 0xFFfff9ee,
  "fontsize" :textSize5,
  "name" : "Rice Fields",
  "isImage" : true,
  "imageName" : "16_rice.jpg",
};
Map<String,dynamic> boatTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "BebasNeue",
  "fontcolor" : 0xFFfff9ee,
  "fontsize" :textSize4,
  "name" : "Lake Boat",
  "isImage" : true,
  "imageName" : "17_boat.jpg",
};
Map<String,dynamic> sandTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "MontSerrat",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize5,
  "name" : "Desert Dunes",
  "isImage" : true,
  "imageName" : "18_sand.jpg",
};
//Map<String,dynamic> oilTheme =
// {
//   "color1" : 0xFF0fdbee,
//   "color2" : 0xffe6126d,
//   "color3" : 0xffd4305f,
//   "p1" : 0.0,
//   "p2" : 1.0,
//   "p3" : 0.0,
//   "nbrcolor" : 2,
//   "fontfamily" : "Oswald",
//   "fontcolor" : 0xFF000000,
//   "fontsize" :textSize4,
//   "name" : "Neon Street",
//   "isImage" : true,
//   "imageName" : "19_oil.jpg",
// };
Map<String,dynamic> sky20Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Volkorn",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "Cloudy Sky",
  "isImage" : true,
  "imageName" : "20_sky.jpg",
};
Map<String,dynamic> seaTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Ovo",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize4,
  "name" : "Sea Horizon",
  "isImage" : true,
  "imageName" : "21_sea.jpg",
};
Map<String,dynamic> birdsTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Allerta",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "Flying Birds",
  "isImage" : true,
  "imageName" : "22_birds.jpg",
};
Map<String,dynamic> bridgeTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "SourceSansPro",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize6,
  "name" : "Forest Bridge",
  "isImage" : true,
  "imageName" : "23_bridge.jpg",
};
Map<String,dynamic> marbreTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Quicksand",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "White Marble",
  "isImage" : true,
  "imageName" : "24_marbre.jpg",
};
Map<String,dynamic> blackmarbreTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "PlayfairDisplay",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize4,
  "name" : "Black Marble",
  "isImage" : true,
  "imageName" : "25_blackmarbre.jpg",
};
Map<String,dynamic> city26Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "EBGaramond",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize6,
  "name" : "City Night",
  "isImage" : true,
  "imageName" : "26_city.jpg",
};
Map<String,dynamic> lights27Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "CormorantGaramond",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize6,
  "name" : "Street Lights",
  "isImage" : true,
  "imageName" : "27_lights.jpg",
};
Map<String,dynamic> dunesTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "JosefinSlab",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize5,
  "name" : "Sand Dunes",
  "isImage" : true,
  "imageName" : "28_dunes.jpg",
};
Map<String,dynamic> redmoutainTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "DidactGothic",
  "fontcolor" : 0xFFfff9ee,
  "fontsize" :textSize3,
  "name" : "Red Canyon",
  "isImage" : true,
  "imageName" : "29_redmoutain.jpg",
};
Map<String,dynamic> water30Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "LibreBaskerville",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize5,
  "name" : "Misty Pond",
  "isImage" : true,
  "imageName" : "30_water.jpg",
};
Map<String,dynamic> city31Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Sanchez",
  "fontcolor" : 0xFFfff9ee,
  "fontsize" :textSize3,
  "name" : "City Sunset",
  "isImage" : true,
  "imageName" : "31_city.jpg",
};
Map<String,dynamic> sky32Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Lustria",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Sunset Sky",
  "isImage" : true,
  "imageName" : "32_sky.jpg",
};
Map<String,dynamic> lights33Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "JosefinSlab",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize5,
  "name" : "Bokeh Lights",
  "isImage" : true,
  "imageName" : "33_lights.jpg",
};
Map<String,dynamic> mongolfiereTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "JosefinSlab",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize5,
  "name" : "Hot Air Balloons",
  "isImage" : true,
  "imageName" : "34_mongolfiere.jpg",
};
Map<String,dynamic> sky35Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Sanchez",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Starry Sky",
  "isImage" : true,
  "imageName" : "35_sky.jpg",
};
Map<String,dynamic> planeTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Oranlenbaum",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize4,
  "name" : "Airplane Wing",
  "isImage" : true,
  "imageName" : "36_plane.jpg",
};
Map<String,dynamic> cloudsTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "AbhayaLibre",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize5,
  "name" : "Soft Clouds",
  "isImage" : true,
  "imageName" : "37_clouds.jpg",
};
Map<String,dynamic> flowersTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "BodoniModa",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize4,
  "name" : "Pink Blossoms",
  "isImage" : true,
  "imageName" : "38_flowers.jpg",
};
Map<String,dynamic> fungusTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "InterTight",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Forest Ferns",
  "isImage" : true,
  "imageName" : "39_fungus.jpg",
};
Map<String,dynamic> water40Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "LibreBaskerville",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize5,
  "name" : "Ocean Wave",
  "isImage" : true,
  "imageName" : "40_water.jpg",
};
Map<String,dynamic> forest41Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "JosefinSans",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize4,
  "name" : "Misty Forest",
  "isImage" : true,
  "imageName" : "41_forest.jpg",
};
Map<String,dynamic> sky42Theme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Oswald",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize4,
  "name" : "Aurora Sky",
  "isImage" : true,
  "imageName" : "42_sky.jpg",
};
Map<String,dynamic> sakuraTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "YesevaOne",
  "fontcolor" : 0xFF000000,
  "fontsize" :textSize3,
  "name" : "Sakura Trees",
  "isImage" : true,
  "imageName" : "43_sakura.jpg",
};
Map<String,dynamic> milkywayTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Lustria",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Milky Way",
  "isImage" : true,
  "imageName" : "44_milkyway.jpg",
};
Map<String,dynamic> auroreTheme =
{
  "color1" : 0xFF0fdbee,
  "color2" : 0xffe6126d,
  "color3" : 0xffd4305f,
  "p1" : 0.0,
  "p2" : 1.0,
  "p3" : 0.0,
  "nbrcolor" : 2,
  "fontfamily" : "Quicksand",
  "fontcolor" : 0xFFffffff,
  "fontsize" :textSize3,
  "name" : "Northern Lights",
  "isImage" : true,
  "imageName" : "45_aurore.jpg",
};


// ===============================
// Provider (LIST, not map)
// ===============================
final themeCustomListProvider = StateProvider<List<Map<String, dynamic>>>(
      (ref) => <Map<String, dynamic>>[],
);

const String kPrefsThemeCustomMap = "themeCustomDatasMap"; // on garde la même clé pour compat

DatabaseReference _userThemesBase(String uid) =>
    FirebaseDatabase.instance.ref("users/$uid/customThemesByName");

// ===============================
// Helpers SharedPreferences (LISTE)
// ===============================

/// Loads the theme list from SharedPreferences.
/// Compat: if the legacy format (Map keyed by name) is found, convert to List.
Future<List<Map<String, dynamic>>> loadThemeListFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return await _loadRawList(prefs);
}
Future<List<Map<String, dynamic>>> _loadRawList(SharedPreferences prefs) async {
  final raw = prefs.getString(kPrefsThemeCustomMap);
  debugPrint("📦 [loadThemeList] Raw data: $raw");
  if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

  final decoded = jsonDecode(raw);
  if (decoded is List) {
    // already in the correct format
    final result = decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    debugPrint("📦 [loadThemeList] Loaded ${result.length} themes");
    for (var t in result) {
      debugPrint("   - ${t['name']}: isImage=${t['isImage']}, imageName=${t['imageName']}");
    }
    return result;
  } else if (decoded is Map) {
    // ancien format: Map<String, Map> -> on convertit en List
    final m = decoded.cast<String, dynamic>();
    final list = <Map<String, dynamic>>[];
    m.forEach((k, v) {
      if (v is Map) {
        final theme = Map<String, dynamic>.from(v);
        theme["name"] ??= k; // injecte le nom si absent
        list.add(theme);
      }
    });
    return list;
  } else {
    return <Map<String, dynamic>>[];
  }
}

Future<void> _saveRawList(SharedPreferences prefs, List<Map<String, dynamic>> list) async {
  await prefs.setString(kPrefsThemeCustomMap, jsonEncode(list));
}

/// Utils LISTE
int _indexOfByName(List<Map<String, dynamic>> list, String name) {
  return list.indexWhere((t) => (t["name"] ?? "") == name);
}

void _upsertByName(List<Map<String, dynamic>> list, Map<String, dynamic> theme) {
  final name = (theme["name"] ?? "").toString();
  if (name.isEmpty) return; // on ignore si pas de nom
  final idx = _indexOfByName(list, name);
  if (idx >= 0) {
    list[idx] = theme;
  } else {
    list.add(theme);
  }
}

// ===============================
// Name generation
// ===============================
Future<String> generateThemeName() async {
  final prefs = await SharedPreferences.getInstance();
  final existingThemes = await _loadRawList(prefs);
  
  // Extract the numbers of existing themes that start with "Your theme "
  final themeNumbers = <int>[];
  for (final theme in existingThemes) {
    final name = (theme["name"] ?? "").toString();
    if (name.startsWith("Your theme ")) {
      final numberStr = name.substring("Your theme ".length);
      final number = int.tryParse(numberStr);
      if (number != null) {
        themeNumbers.add(number);
      }
    }
  }
  
  // Find the next available number
  int nextNumber = 1;
  if (themeNumbers.isNotEmpty) {
    themeNumbers.sort();
    // Find the first gap in the sequence (1, 2, 3, ...)
    bool foundGap = false;
    for (int i = 0; i < themeNumbers.length; i++) {
      if (themeNumbers[i] != i + 1) {
        nextNumber = i + 1;
        foundGap = true;
        break;
      }
    }
    // If no gap, use the next number after the last
    if (!foundGap) {
      nextNumber = themeNumbers.last + 1;
    }
  }
  
  return "Your theme $nextNumber";
}

// ===============================
// Sauvegarde locale: ajout/MAJ (LISTE)
// ===============================
Future<void> addOrUpdateThemeLocal(Map<String, dynamic> theme) async {
  final prefs = await SharedPreferences.getInstance();
  final all = await _loadRawList(prefs);
  _upsertByName(all, theme);
  await _saveRawList(prefs, all);
}

// ===============================
// Firebase save: add/update an entry (key = name)
// ===============================
Future<void> addOrUpdateThemeFirebase(Map<String, dynamic> theme) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final name = (theme["name"] ?? "").toString();
  if (name.isEmpty) return; // refuse si pas de nom
  
  // ⚠️ DO NOT save custom themes with images to Firebase
  // Images are stored locally and will be lost on uninstall
  final isImage = theme["isImage"] == true;
  final imageName = theme["imageName"] as String?;
  final hasImage = isImage && imageName != null && imageName.isNotEmpty;
  
  if (hasImage) {
    if (kDebugMode) {
      debugPrint("⏸️ [Themes] Theme with image not saved to Firebase: $name");
      debugPrint("   - Themes with images remain local only");
    }
    return; // Ne pas sauvegarder sur Firebase
  }
  
  await _userThemesBase(user.uid).child(name).set(theme);
}

// ===============================
// Local load -> Provider (LIST)
// ===============================
Future<void> loadThemesLocalIntoProvider(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final list = await _loadRawList(prefs);
  ref.read(themeCustomListProvider.notifier).state = List<Map<String, dynamic>>.from(list);
  
  // Clean orphan images in the App Group
  final usedWidgetImages = <String>[];
  for (final theme in list) {
    final widgetImageName = theme["widgetImageName"] as String?;
    if (widgetImageName != null && widgetImageName.isNotEmpty) {
      usedWidgetImages.add(widgetImageName);
    }
  }
  
  // Run cleanup asynchronously (don't block loading)
  cleanupOrphanedImages(usedWidgetImages).catchError((e) {
    if (kDebugMode) {
      debugPrint('❌ [Themes] Error while cleaning up images: $e');
    }
  });
}

// ===============================
// Add/Update directly in the local provider (LIST)
// ===============================
Future<void> addOrUpdateThemeInProvider(
    WidgetRef ref,
    Map<String, dynamic> theme,
    ) async {
  final current = List<Map<String, dynamic>>.from(ref.read(themeCustomListProvider));
  _upsertByName(current, theme);
  ref.read(themeCustomListProvider.notifier).state = current;
}

// ===============================
// Sync Firebase -> Local (+option merge) -> Provider (LISTE)
// overwrite=true: fully replace local with Firebase
// overwrite=false: merge (Firebase wins if same name)
// ===============================
Future<void> syncFirebaseIntoLocalAndProvider(WidgetRef ref, {bool overwrite = true}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // not signed in → just reload local
    await loadThemesLocalIntoProvider(ref);
    return;
  }

  // 1) Fetch Firebase (key = name) -> convert to LIST
  // ⚠️ Skip themes with images (they aren't saved to Firebase)
  final snap = await _userThemesBase(user.uid).get();
  final fbList = <Map<String, dynamic>>[];
  if (snap.exists && snap.value is Map) {
    final data = (snap.value as Map);
    data.forEach((k, v) {
      if (k is String && v is Map) {
        final theme = Map<String, dynamic>.from(v);
        theme["name"] ??= k;
        
        // Skip themes with images (they aren't on Firebase)
        final isImage = theme["isImage"] == true;
        final imageName = theme["imageName"] as String?;
        final hasImage = isImage && imageName != null && imageName.isNotEmpty;
        
        if (!hasImage) {
          fbList.add(theme);
        } else {
          if (kDebugMode) {
            debugPrint("⏸️ [Themes] Theme with image skipped during Firebase load: $k");
          }
        }
      }
    });
  }

  // 2) Merge/Overwrite local (LISTE)
  final prefs = await SharedPreferences.getInstance();
  if (overwrite) {
    await _saveRawList(prefs, fbList);
    ref.read(themeCustomListProvider.notifier).state = fbList;
  } else {
    final local = await _loadRawList(prefs);
    // merge: Firebase gagne en cas de conflit
    for (final t in fbList) {
      _upsertByName(local, t);
    }
    await _saveRawList(prefs, local);
    ref.read(themeCustomListProvider.notifier).state = local;
  }
}

// ===============================
// Suppressions
// ===============================

// -- 1) Remove from the provider only (LIST)
void removeThemeFromProvider(WidgetRef ref, String name) {
  final current = List<Map<String, dynamic>>.from(ref.read(themeCustomListProvider));
  current.removeWhere((t) => (t["name"] ?? "") == name);
  ref.read(themeCustomListProvider.notifier).state = current;
}

// -- 2) Supprimer en local (SharedPreferences) (LISTE)
Future<void> deleteThemeLocal(String name) async {
  final prefs = await SharedPreferences.getInstance();
  final all = await _loadRawList(prefs);
  all.removeWhere((t) => (t["name"] ?? "") == name);
  await _saveRawList(prefs, all);
}

// -- 3) Delete on Firebase (key = name)
Future<void> deleteThemeFirebase(String name) async {
  debugPrint("deleteThemeFirebase : $name");
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint("user null");
    return;
  }
  if (name.isEmpty) {
    debugPrint("nom vide");
    return;
  }

  await _userThemesBase(user.uid).child(name).remove();
}

// -- 4) Delete everywhere (safe order: provider -> local -> firebase)
Future<void> deleteThemeEverywhere(WidgetRef ref, String name) async {
  debugPrint("deleteThemeEverywhere: $name");
  
  // 1. Fetch the theme before deleting it to clean up the widget image
  final themes = ref.read(themeCustomListProvider);
  final themeToDelete = themes.firstWhere(
    (t) => (t["name"] ?? "") == name,
    orElse: () => <String, dynamic>{},
  );
  
  // 2. If the theme has a widget image, delete it from the App Group
  final widgetImageName = themeToDelete["widgetImageName"] as String?;
  if (widgetImageName != null && widgetImageName.isNotEmpty) {
    debugPrint("🗑️ [Themes] Suppression de l'image widget: $widgetImageName");
    await deleteImageFromWidgetGroup(widgetImageName);
  }
  
  // 3. Delete the theme everywhere
  removeThemeFromProvider(ref, name);     // UX immédiate
  await deleteThemeLocal(name);           // persistance locale
  await deleteThemeFirebase(name);        // cloud
  
  debugPrint("✅ [Themes] Theme deleted: $name");
}
