/// Categories for ID card scanning matching CamScanner presets.
enum IdCardCategory {
  general(
    title: 'General',
    subtitle: 'Standard 2-sided identity card',
    sides: 2,
  ),
  driverLicense(
    title: 'Driver Licence',
    subtitle: 'Driver license (Front & Back)',
    sides: 2,
  ),
  idCard(
    title: 'ID Card',
    subtitle: 'National identity card (Front & Back)',
    sides: 2,
  ),
  passport(
    title: 'Passport',
    subtitle: 'Passport information page (1 side)',
    sides: 1,
  ),
  bankCard(
    title: 'Bank Card',
    subtitle: 'Debit or credit card (Front & Back)',
    sides: 2,
  ),
  certificate(
    title: 'Certificate',
    subtitle: 'Official certificate or diploma (1 side)',
    sides: 1,
  ),
  ssn(
    title: 'SSN',
    subtitle: 'Social security card',
    sides: 2,
  ),
  autoInsurance(
    title: 'Auto Insurance',
    subtitle: 'Vehicle insurance card (Front & Back)',
    sides: 2,
  );

  const IdCardCategory({
    required this.title,
    required this.subtitle,
    required this.sides,
  });

  final String title;
  final String subtitle;
  final int sides;

  bool get isSingleSide => sides == 1;

  /// Categories shown on the in-app **ID Cards** picker (not Tools shortcuts).
  /// Passport / certificates live under Tools, not this chip row.
  static const List<IdCardCategory> idCardsScreenCategories =
      <IdCardCategory>[
    general,
    driverLicense,
    idCard,
    bankCard,
  ];

  bool get showsOnIdCardsScreen => idCardsScreenCategories.contains(this);

  /// Default file name prefix when saved.
  String get filePrefix => switch (this) {
    general => 'General_ID',
    driverLicense => 'Driver_Licence',
    idCard => 'ID_Card',
    passport => 'Passport',
    bankCard => 'Bank_Card',
    certificate => 'Certificate',
    ssn => 'SSN_Card',
    autoInsurance => 'Auto_Insurance',
  };
}
