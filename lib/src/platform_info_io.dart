import 'dart:ffi';
import 'dart:io';

String get operatingSystem => Platform.operatingSystem;

String get operatingSystemVersion => Platform.operatingSystemVersion;

String get processArchitecture => Abi.current().toString();
