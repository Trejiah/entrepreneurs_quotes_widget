import 'package:businessmindset/features/settings/model/settings_models.dart';

/// Résultat d’un tap sur une ligne réglages : navigation, paywall ou action système.
sealed class SettingsOutcome {
  const SettingsOutcome();
}

/// Ouvrir le paywall (non premium).
class SettingsOutcomePaywall extends SettingsOutcome {
  const SettingsOutcomePaywall();
}

/// Navigation vers un écran interne.
class SettingsOutcomeNavigate extends SettingsOutcome {
  const SettingsOutcomeNavigate(this.destination);
  final SettingsNavDestination destination;
}

/// Partager l’app.
class SettingsOutcomeShare extends SettingsOutcome {
  const SettingsOutcomeShare();
}

/// Ouvrir la fiche app pour laisser un avis.
class SettingsOutcomeOpenStoreReview extends SettingsOutcome {
  const SettingsOutcomeOpenStoreReview();
}

/// Ouvrir le client mail.
class SettingsOutcomeOpenMail extends SettingsOutcome {
  const SettingsOutcomeOpenMail();
}

/// Ouvrir la politique de confidentialité (URL).
class SettingsOutcomeOpenPrivacy extends SettingsOutcome {
  const SettingsOutcomeOpenPrivacy();
}

/// Ouvrir les CGU (URL).
class SettingsOutcomeOpenTerms extends SettingsOutcome {
  const SettingsOutcomeOpenTerms();
}

enum SettingsNavDestination {
  myFeed,
  myFavoriteTones,
  notifications,
  widgetPage,
  namePage,
  genderPage,
  languagePage,
  managePage,
  signInPage,
  chooseQuote,
  lockscreenChoice,
  notificationsChoice,
  appOrderedQuotes,
}

SettingsOutcome outcomeForSettingAction(SettingAction action, {required bool premium}) {
  switch (action) {
    case SettingAction.myPersonalizedFeed:
      return premium
          ? const SettingsOutcomeNavigate(SettingsNavDestination.myFeed)
          : const SettingsOutcomePaywall();
    case SettingAction.myFavoriteTones:
      return premium
          ? const SettingsOutcomeNavigate(SettingsNavDestination.myFavoriteTones)
          : const SettingsOutcomePaywall();
    case SettingAction.notifications:
      return const SettingsOutcomeNavigate(SettingsNavDestination.notifications);
    case SettingAction.widget:
      return const SettingsOutcomeNavigate(SettingsNavDestination.widgetPage);
    case SettingAction.name:
      return const SettingsOutcomeNavigate(SettingsNavDestination.namePage);
    case SettingAction.gender:
      return const SettingsOutcomeNavigate(SettingsNavDestination.genderPage);
    case SettingAction.language:
      return const SettingsOutcomeNavigate(SettingsNavDestination.languagePage);
    case SettingAction.manageSub:
      return const SettingsOutcomeNavigate(SettingsNavDestination.managePage);
    case SettingAction.signIn:
      return const SettingsOutcomeNavigate(SettingsNavDestination.signInPage);
    case SettingAction.share:
      return const SettingsOutcomeShare();
    case SettingAction.review:
      return const SettingsOutcomeOpenStoreReview();
    case SettingAction.contact:
      return const SettingsOutcomeOpenMail();
    case SettingAction.privacy:
      return const SettingsOutcomeOpenPrivacy();
    case SettingAction.terms:
      return const SettingsOutcomeOpenTerms();
    case SettingAction.chooseQuote:
      return const SettingsOutcomeNavigate(SettingsNavDestination.chooseQuote);
    case SettingAction.choixLockscreen:
      return const SettingsOutcomeNavigate(SettingsNavDestination.lockscreenChoice);
    case SettingAction.choixNotifications:
      return const SettingsOutcomeNavigate(SettingsNavDestination.notificationsChoice);
    case SettingAction.appOrderedQuotes:
      return const SettingsOutcomeNavigate(SettingsNavDestination.appOrderedQuotes);
  }
}
