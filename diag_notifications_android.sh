#!/bin/bash
# ─────────────────────────────────────────────────────────────
# diag_notifications_android.sh
# Diagnostic ADB pour notifications Flutter (Business Mindset)
# Usage :
#   chmod +x diag_notifications_android.sh
#   ./diag_notifications_android.sh          # mode BEFORE (avant test)
#   ./diag_notifications_android.sh after    # mode AFTER  (après l'heure prévue)
#   ./diag_notifications_android.sh live     # mode LIVE   (logcat en temps réel)
# ─────────────────────────────────────────────────────────────

APP_PACKAGE="com.businessmindset"   # ← adapte si besoin
CHANNEL_ID="daily_quote_channel_v2"
OUT_DIR="./notif_diag"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MODE="${1:-before}"

mkdir -p "$OUT_DIR"

check_adb() {
  if ! command -v adb &>/dev/null; then
    echo "❌ ADB introuvable. Installe Android Platform Tools."
    exit 1
  fi
  if ! adb devices | grep -q "device$"; then
    echo "❌ Aucun téléphone détecté. Branche le câble et active le débogage USB."
    exit 1
  fi
  echo "✅ Téléphone détecté : $(adb devices | grep 'device$' | awk '{print $1}')"
}

dump_before() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 MODE : BEFORE — Snapshot état initial"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  local OUT="$OUT_DIR/before_$TIMESTAMP.txt"

  {
    echo "═══ DATE SYSTÈME ═══"
    adb shell date

    echo ""
    echo "═══ DOZE / DEVICEIDLE STATE ═══"
    adb shell dumpsys deviceidle | grep -E "mLightState|mState|mForceIdle|enabled"

    echo ""
    echo "═══ BATTERY OPTIMIZATION (app) ═══"
    adb shell dumpsys deviceidle whitelist | grep -i "$APP_PACKAGE" || echo "(app absente de la whitelist)"

    echo ""
    echo "═══ ALARMES PENDANTES (app) ═══"
    adb shell dumpsys alarm | grep -A3 -i "$APP_PACKAGE"

    echo ""
    echo "═══ CANAL DE NOTIFICATION ═══"
    adb shell dumpsys notification --noredact | grep -A10 -i "$CHANNEL_ID"

    echo ""
    echo "═══ ÉTAT GLOBAL NOTIFICATIONS APP ═══"
    adb shell dumpsys notification --noredact | grep -A5 -i "$APP_PACKAGE"

    echo ""
    echo "═══ FLUTTER LOCAL NOTIFICATIONS (logcat récent) ═══"
    adb logcat -d -v time | grep -i "flutter_local_notifications\|AlarmService\|$APP_PACKAGE" | tail -50

  } | tee "$OUT"

  echo ""
  echo "✅ Snapshot sauvegardé : $OUT"
  echo ""
  echo "👉 PROCHAINE ÉTAPE :"
  echo "   1. Programme tes notifications dans l'app"
  echo "   2. Ferme l'app"
  echo "   3. Attends l'heure prévue"
  echo "   4. Lance : ./diag_notifications_android.sh after"
}

dump_after() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 MODE : AFTER — Snapshot post-notification"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  local OUT="$OUT_DIR/after_$TIMESTAMP.txt"

  {
    echo "═══ DATE SYSTÈME ═══"
    adb shell date

    echo ""
    echo "═══ DOZE STATE ═══"
    adb shell dumpsys deviceidle | grep -E "mLightState|mState|mForceIdle"

    echo ""
    echo "═══ ALARMES RESTANTES (app) ═══"
    adb shell dumpsys alarm | grep -A3 -i "$APP_PACKAGE"

    echo ""
    echo "═══ NOTIFICATIONS POSTÉES ═══"
    adb shell dumpsys notification --noredact | grep -A10 -i "$APP_PACKAGE"

    echo ""
    echo "═══ LOGCAT — AlarmManager / NotificationManager ═══"
    adb logcat -d -v time | grep -iE \
      "AlarmManager|NotificationManager|AlarmService|flutter_local_notifications|$APP_PACKAGE|deviceidle|doze|inexact|batch" \
      | tail -100

    echo ""
    echo "═══ LOGCAT — Erreurs Flutter ═══"
    adb logcat -d -v time | grep -iE "flutter|E/flutter|W/flutter" | tail -30

  } | tee "$OUT"

  echo ""
  echo "✅ Snapshot sauvegardé : $OUT"
  echo ""
  echo "👉 Copie le contenu de $OUT et colle-le pour analyse."
}

dump_live() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📡 MODE : LIVE — Logcat en temps réel"
  echo "    (Ctrl+C pour arrêter)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  local OUT="$OUT_DIR/live_$TIMESTAMP.txt"

  echo "(Logs aussi sauvegardés dans $OUT)"
  echo ""

  adb logcat -c  # vide le buffer
  adb logcat -v time | grep --line-buffered -iE \
    "AlarmManager|NotificationManager|AlarmService|flutter_local_notifications|$APP_PACKAGE|deviceidle|doze|inexact|batch|I/flutter|E/flutter" \
    | tee "$OUT"
}

# ─── MAIN ───
check_adb

case "$MODE" in
  before) dump_before ;;
  after)  dump_after  ;;
  live)   dump_live   ;;
  *)
    echo "Usage: $0 [before|after|live]"
    exit 1
    ;;
esac