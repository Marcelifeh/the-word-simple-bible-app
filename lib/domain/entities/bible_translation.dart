enum BibleTranslation {
  kjv('English (KJV)', isLicensed: false),
  web('English (WEB)', isLicensed: false),
  hausa('Hausa (HA)', isLicensed: false),
  igbo('Igbo (IG)', isLicensed: false),
  yoruba('Yoruba (YO)', isLicensed: false),
  french('French', isLicensed: false),
  spanish('Spanish', isLicensed: false),
  nkjv('NKJV', isLicensed: true),
  niv('NIV', isLicensed: true),
  esv('ESV', isLicensed: true),
  nlt('NLT', isLicensed: true);

  const BibleTranslation(this.label, {required this.isLicensed});

  final String label;
  final bool isLicensed;

  String get id => name;
}
