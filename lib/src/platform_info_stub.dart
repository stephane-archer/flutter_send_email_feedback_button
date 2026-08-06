String get operatingSystem => 'web';

// Browsers do not expose a reliable operating-system version through Dart's
// platform APIs. Returning an empty value lets the email formatter omit it.
String get operatingSystemVersion => '';
