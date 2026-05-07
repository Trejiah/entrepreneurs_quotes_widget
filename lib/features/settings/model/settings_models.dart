// Modèles de données pour l’écran Réglages (MVVM).

enum SettingAction {
  myPersonalizedFeed,
  myFavoriteTones,
  notifications,
  widget,
  name,
  gender,
  language,
  manageSub,
  signIn,
  share,
  review,
  contact,
  privacy,
  terms,
  chooseQuote,
  choixLockscreen,
  choixNotifications,
  appOrderedQuotes,
}

class SettingItemData {
  final String icon;
  final String labelKey;
  final SettingAction action;
  const SettingItemData({
    required this.icon,
    required this.labelKey,
    required this.action,
  });
}

class SettingSectionData {
  final String titleKey;
  final List<SettingItemData> items;
  const SettingSectionData({required this.titleKey, required this.items});
}

/// Sections affichées (hors debug : [includeDebugMenu] depuis la vue).
List<SettingSectionData> buildSettingsSections({required bool includeDebugMenu}) {
  return [
    const SettingSectionData(
      titleKey: "PERSONALIZATION",
      items: [
        SettingItemData(
          icon: "mypersfeed_white.png",
          labelKey: "personalized_feed",
          action: SettingAction.myPersonalizedFeed,
        ),
        SettingItemData(
          icon: "personalized_quote_white.png",
          labelKey: "my_favorite_tones",
          action: SettingAction.myFavoriteTones,
        ),
        SettingItemData(icon: "notif.png", labelKey: "Notifications", action: SettingAction.notifications),
        SettingItemData(icon: "widget.png", labelKey: "Widget", action: SettingAction.widget),
        SettingItemData(icon: "name.png", labelKey: "Name", action: SettingAction.name),
        SettingItemData(icon: "gender.png", labelKey: "Gender", action: SettingAction.gender),
      ],
    ),
    const SettingSectionData(
      titleKey: "ACCOUNT",
      items: [
        SettingItemData(icon: "sub.png", labelKey: "managesub", action: SettingAction.manageSub),
        SettingItemData(icon: "signin.png", labelKey: "cloudsync", action: SettingAction.signIn),
      ],
    ),
    const SettingSectionData(
      titleKey: "SUPPORT & COMMUNITY",
      items: [
        SettingItemData(icon: "share2.png", labelKey: "sharebus", action: SettingAction.share),
        SettingItemData(icon: "review.png", labelKey: "leavereview", action: SettingAction.review),
        SettingItemData(icon: "contact.png", labelKey: "contactus", action: SettingAction.contact),
      ],
    ),
    SettingSectionData(
      titleKey: "LEGAL",
      items: [
        const SettingItemData(icon: "privacy.png", labelKey: "privpol", action: SettingAction.privacy),
        const SettingItemData(icon: "terms.png", labelKey: "termscond", action: SettingAction.terms),
        if (includeDebugMenu) ...const [
          SettingItemData(icon: "quote.png", labelKey: "Choix Citation", action: SettingAction.chooseQuote),
          SettingItemData(icon: "quote.png", labelKey: "Choix Lockscreen", action: SettingAction.choixLockscreen),
          SettingItemData(icon: "notif.png", labelKey: "Choix Notifications", action: SettingAction.choixNotifications),
          SettingItemData(icon: "quote.png", labelKey: "Citations ordonnées", action: SettingAction.appOrderedQuotes),
        ],
      ],
    ),
  ];
}
