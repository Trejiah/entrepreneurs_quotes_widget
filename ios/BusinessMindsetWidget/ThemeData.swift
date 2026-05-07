import Foundation
import SwiftUI

// MARK: - ThemeData Structure
/// Structure représentant un thème
/// Copie de la structure Map<String, dynamic> de themedatas.dart
struct ThemeData {
    let color1: UInt32
    let color2: UInt32?
    let color3: UInt32?
    let p1: Double
    let p2: Double
    let p3: Double
    let nbrColor: Int
    let fontFamily: String
    let fontColor: UInt32
    let fontSize: Int
    let name: String
    let isImage: Bool
    let imageName: String?
    
    init(
        color1: UInt32,
        color2: UInt32? = nil,
        color3: UInt32? = nil,
        p1: Double = 0.0,
        p2: Double = 0.0,
        p3: Double = 0.0,
        nbrColor: Int = 1,
        fontFamily: String = "InterTight",
        fontColor: UInt32 = 0xFFFFFFFF,
        fontSize: Int = 18,
        name: String = "",
        isImage: Bool = false,
        imageName: String? = nil
    ) {
        self.color1 = color1
        self.color2 = color2
        self.color3 = color3
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
        self.nbrColor = nbrColor
        self.fontFamily = fontFamily
        self.fontColor = fontColor
        self.fontSize = fontSize
        self.name = name
        self.isImage = isImage
        self.imageName = imageName
    }
}

// MARK: - All App Themes
/// Liste de tous les thèmes de l'app
/// Copie directe de allAppThemes de themedatas.dart (70 thèmes)
let allAppThemes: [ThemeData] = [
    ThemeData(
        color1: 0xFF1f1f1f,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "JosefinSlab",
        fontColor: 0xFFffffff,
        fontSize: 25,
        name: "Black",
        isImage: false,
        imageName: nil
    ), // blackTheme
    ThemeData(
        color1: 0xFFa2f1a7,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "DidactGothic",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Green",
        isImage: false,
        imageName: nil
    ), // greenTheme
    ThemeData(
        color1: 0xFFf8d4c6,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "Raleway",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "LightPink",
        isImage: false,
        imageName: nil
    ), // lightPinkTheme
    ThemeData(
        color1: 0xFFfd608e,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "InterTight",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Pink",
        isImage: false,
        imageName: nil
    ), // pinkTheme
    ThemeData(
        color1: 0xFFfef6bb,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "InterTight",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "LightYellow",
        isImage: false,
        imageName: nil
    ), // lightYellowTheme
    ThemeData(
        color1: 0xFFf6d8fc,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "Lustria",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "LightPurple",
        isImage: false,
        imageName: nil
    ), // lightPurpleTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "BebasNeue",
        fontColor: 0xFF000000,
        fontSize: 20,
        name: "LightBlue",
        isImage: false,
        imageName: nil
    ), // lightBlueTheme
    ThemeData(
        color1: 0xFFf9d1a5,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "Volkorn",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "Skin",
        isImage: false,
        imageName: nil
    ), // skinTheme
    ThemeData(
        color1: 0xFF4865fd,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "SourceSansPro",
        fontColor: 0xFFffffff,
        fontSize: 19,
        name: "LittlePurple",
        isImage: false,
        imageName: nil
    ), // littlePurpleTheme
    ThemeData(
        color1: 0xFFfbf4ed,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "Sanchez",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "LittleSkin",
        isImage: false,
        imageName: nil
    ), // littleSkinTheme
    ThemeData(
        color1: 0xFF86f5cc,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "Lato",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "LittleGreen",
        isImage: false,
        imageName: nil
    ), // littleGreenTheme
    ThemeData(
        color1: 0xFFabbde0,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "EBGaramond",
        fontColor: 0xFF000000,
        fontSize: 20,
        name: "BlueGreen",
        isImage: false,
        imageName: nil
    ), // blueGreenTheme
    ThemeData(
        color1: 0xFF10eaff,
        color2: 0xff29918a,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.0,
        p3: 0.0,
        nbrColor: 1,
        fontFamily: "InterTight",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "VeryLightBlue",
        isImage: false,
        imageName: nil
    ), // veryLightBlueTheme
    ThemeData(
        color1: 0xFF72fa93,
        color2: 0xff9ac1f0,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.85,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "InterTight",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "GreenBlue",
        isImage: false,
        imageName: nil
    ), // greenBlueTheme
    ThemeData(
        color1: 0xFFf9858b,
        color2: 0xff9ac1f0,
        color3: 0xffe09571,
        p1: 0.0,
        p2: 0.74,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "InterTight",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "RedBlue",
        isImage: false,
        imageName: nil
    ), // redBlueTheme
    ThemeData(
        color1: 0xFFb5e5e7,
        color2: 0xff7dd1df,
        color3: 0xff1e95d4,
        p1: 0.15,
        p2: 0.55,
        p3: 0.92,
        nbrColor: 3,
        fontFamily: "MontSerrat",
        fontColor: 0xFFffffff,
        fontSize: 19,
        name: "BlueBlueBlue",
        isImage: false,
        imageName: nil
    ), // blueBlueBlueTheme
    ThemeData(
        color1: 0xFFffcf43,
        color2: 0xff5ce0d8,
        color3: 0xff1e95d4,
        p1: 0.0,
        p2: 0.81,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Allerta",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "YellowBlue",
        isImage: false,
        imageName: nil
    ), // yellowBlueTheme
    ThemeData(
        color1: 0xFFffffff,
        color2: 0xff903b6b,
        color3: 0xff1e95d4,
        p1: 0.0,
        p2: 0.85,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "PlayfairDisplay",
        fontColor: 0xFFffffff,
        fontSize: 19,
        name: "WhitePurple",
        isImage: false,
        imageName: nil
    ), // whitePurpleTheme
    ThemeData(
        color1: 0xFFfcc5f9,
        color2: 0xfff38283,
        color3: 0xff1e95d4,
        p1: 0.20,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "InterTight",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "PurplePink",
        isImage: false,
        imageName: nil
    ), // purplePinkTheme
    ThemeData(
        color1: 0xFFf8d4c6,
        color2: 0xffa0efa5,
        color3: 0xff1e95d4,
        p1: 0.19,
        p2: 0.85,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "JosefinSans",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "SkinGreen",
        isImage: false,
        imageName: nil
    ), // skinGreenTheme
    ThemeData(
        color1: 0xFFf8d4c6,
        color2: 0xfffd608e,
        color3: 0xffd4305f,
        p1: 0.06,
        p2: 0.59,
        p3: 0.85,
        nbrColor: 3,
        fontFamily: "YesevaOne",
        fontColor: 0xFFffffff,
        fontSize: 19,
        name: "SkinRed",
        isImage: false,
        imageName: nil
    ), // skinRedTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xff16dcdb,
        color3: 0xff1edec7,
        p1: 0.0,
        p2: 0.47,
        p3: 1.0,
        nbrColor: 3,
        fontFamily: "Quicksand",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "LightBlueWhite",
        isImage: false,
        imageName: nil
    ), // lightBlueWhiteTheme
    ThemeData(
        color1: 0xFFf6d8fc,
        color2: 0xff0fdbee,
        color3: 0xffd4305f,
        p1: 0.16,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "BodoniModa",
        fontColor: 0xFF000000,
        fontSize: 19,
        name: "PinkBlue",
        isImage: false,
        imageName: nil
    ), // pinkBlueTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "BebasNeue",
        fontColor: 0xFFffffff,
        fontSize: 20,
        name: "blueRed",
        isImage: false,
        imageName: nil
    ), // blueRedTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "BodoniModa",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Skyline New York",
        isImage: true,
        imageName: "1_skyline"
    ), // skylineTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "DidactGothic",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Skyline Toronto",
        isImage: true,
        imageName: "2_skyline"
    ), // skyline2Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "MontSerrat",
        fontColor: 0xFFffffff,
        fontSize: 25,
        name: "Mountain Path",
        isImage: true,
        imageName: "3_landscape"
    ), // landscapeTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "PlayfairDisplay",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Sky Mountain",
        isImage: true,
        imageName: "4_skymountain"
    ), // skymountainTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "LibreBaskerville",
        fontColor: 0xFFffffff,
        fontSize: 25,
        name: "Full Moon",
        isImage: true,
        imageName: "5_moon"
    ), // moonTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "SourceSansPro",
        fontColor: 0xFFffffff,
        fontSize: 26,
        name: "Sunny Beach",
        isImage: true,
        imageName: "6_beach"
    ), // beachTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Sanchez",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Red Ferrari",
        isImage: true,
        imageName: "7_ferrari"
    ), // ferrariTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "JosefinSans",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Snowy Peaks",
        isImage: true,
        imageName: "8_mountain"
    ), // mountainTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Lato",
        fontColor: 0xFFFFFFFF,
        fontSize: 24,
        name: "Snowy Mountain",
        isImage: true,
        imageName: "9_snowmoutain"
    ), // snowmoutainTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Raleway",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Golden Field",
        isImage: true,
        imageName: "10_landscape"
    ), // landscape10Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Allerta",
        fontColor: 0xFFFFFFFF,
        fontSize: 24,
        name: "Paris Eiffel",
        isImage: true,
        imageName: "11_eiffel"
    ), // eiffelTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Lustria",
        fontColor: 0xFFFFFFFF,
        fontSize: 24,
        name: "Dubai Skyline",
        isImage: true,
        imageName: "12_dubai"
    ), // dubaiTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "InterTight",
        fontColor: 0xFFFFFFFF,
        fontSize: 24,
        name: "Forest Path",
        isImage: true,
        imageName: "13_forest"
    ), // forestTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Oranlenbaum",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Sunset Lagoon",
        isImage: true,
        imageName: "14_lagoon"
    ), // lagoonTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "YesevaOne",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Blue Lagoon",
        isImage: true,
        imageName: "15_beach"
    ), // beach15Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "AbhayaLibre",
        fontColor: 0xFFFFF9EE,
        fontSize: 25,
        name: "Rice Fields",
        isImage: true,
        imageName: "16_rice"
    ), // riceTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "BebasNeue",
        fontColor: 0xFFFFF9EE,
        fontSize: 24,
        name: "Lake Boat",
        isImage: true,
        imageName: "17_boat"
    ), // boatTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "MontSerrat",
        fontColor: 0xFF000000,
        fontSize: 25,
        name: "Desert Dunes",
        isImage: true,
        imageName: "18_sand"
    ), // sandTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Volkorn",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Cloudy Sky",
        isImage: true,
        imageName: "20_sky"
    ), // sky20Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Ovo",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Sea Horizon",
        isImage: true,
        imageName: "21_sea"
    ), // seaTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Allerta",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Flying Birds",
        isImage: true,
        imageName: "22_birds"
    ), // birdsTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "SourceSansPro",
        fontColor: 0xFFffffff,
        fontSize: 26,
        name: "Forest Bridge",
        isImage: true,
        imageName: "23_bridge"
    ), // bridgeTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Quicksand",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "White Marble",
        isImage: true,
        imageName: "24_marbre"
    ), // marbreTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "PlayfairDisplay",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Black Marble",
        isImage: true,
        imageName: "25_blackmarbre"
    ), // blackmarbreTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "EBGaramond",
        fontColor: 0xFF000000,
        fontSize: 26,
        name: "City Night",
        isImage: true,
        imageName: "26_city"
    ), // city26Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "CormorantGaramond",
        fontColor: 0xFFffffff,
        fontSize: 26,
        name: "Street Lights",
        isImage: true,
        imageName: "27_lights"
    ), // lights27Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "JosefinSlab",
        fontColor: 0xFFffffff,
        fontSize: 25,
        name: "Sand Dunes",
        isImage: true,
        imageName: "28_dunes"
    ), // dunesTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "DidactGothic",
        fontColor: 0xFFFFF9EE,
        fontSize: 24,
        name: "Red Canyon",
        isImage: true,
        imageName: "29_redmoutain"
    ), // redmoutainTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "LibreBaskerville",
        fontColor: 0xFFffffff,
        fontSize: 25,
        name: "Misty Pond",
        isImage: true,
        imageName: "30_water"
    ), // water30Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Sanchez",
        fontColor: 0xFFFFF9EE,
        fontSize: 24,
        name: "City Sunset",
        isImage: true,
        imageName: "31_city"
    ), // city31Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Lustria",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Sunset Sky",
        isImage: true,
        imageName: "32_sky"
    ), // sky32Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "JosefinSlab",
        fontColor: 0xFFffffff,
        fontSize: 25,
        name: "Bokeh Lights",
        isImage: true,
        imageName: "33_lights"
    ), // lights33Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "JosefinSlab",
        fontColor: 0xFFFFFFFF,
        fontSize: 25,
        name: "Hot Air Balloons",
        isImage: true,
        imageName: "34_mongolfiere"
    ), // mongolfiereTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Sanchez",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Starry Sky",
        isImage: true,
        imageName: "35_sky"
    ), // sky35Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Oranlenbaum",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Airplane Wing",
        isImage: true,
        imageName: "36_plane"
    ), // planeTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "AbhayaLibre",
        fontColor: 0xFF000000,
        fontSize: 25,
        name: "Soft Clouds",
        isImage: true,
        imageName: "37_clouds"
    ), // cloudsTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "BodoniModa",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Pink Blossoms",
        isImage: true,
        imageName: "38_flowers"
    ), // flowersTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "InterTight",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Forest Ferns",
        isImage: true,
        imageName: "39_fungus"
    ), // fungusTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "LibreBaskerville",
        fontColor: 0xFFffffff,
        fontSize: 25,
        name: "Ocean Wave",
        isImage: true,
        imageName: "40_water"
    ), // water40Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "JosefinSans",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Misty Forest",
        isImage: true,
        imageName: "41_forest"
    ), // forest41Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Oswald",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Aurora Sky",
        isImage: true,
        imageName: "42_sky"
    ), // sky42Theme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "YesevaOne",
        fontColor: 0xFF000000,
        fontSize: 24,
        name: "Sakura Trees",
        isImage: true,
        imageName: "43_sakura"
    ), // sakuraTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Lustria",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Milky Way",
        isImage: true,
        imageName: "44_milkyway"
    ), // milkywayTheme
    ThemeData(
        color1: 0xFF0fdbee,
        color2: 0xffe6126d,
        color3: 0xffd4305f,
        p1: 0.0,
        p2: 1.0,
        p3: 0.0,
        nbrColor: 2,
        fontFamily: "Quicksand",
        fontColor: 0xFFffffff,
        fontSize: 24,
        name: "Northern Lights",
        isImage: true,
        imageName: "45_aurore"
    ), // auroreTheme
]

