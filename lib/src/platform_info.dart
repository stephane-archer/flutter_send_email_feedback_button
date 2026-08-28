import 'platform_info_stub.dart'
    if (dart.library.io) 'platform_info_io.dart'
    as implementation;

String get operatingSystem => implementation.operatingSystem;

String get operatingSystemVersion => implementation.operatingSystemVersion;

String get processArchitecture => implementation.processArchitecture;
