enum GenderChoice { female, male, other, notToSay }

const Map<GenderChoice, String> kGenderLabels = {
  GenderChoice.female: 'Female',
  GenderChoice.male: 'Male',
  GenderChoice.other: 'Other',
  GenderChoice.notToSay: 'nottosay',
};

GenderChoice? genderFromString(String? value) {
  if (value == null) return null;
  try {
    return kGenderLabels.entries.firstWhere((e) => e.value == value).key;
  } catch (_) {
    return null;
  }
}

String genderToString(GenderChoice choice) => kGenderLabels[choice]!;

