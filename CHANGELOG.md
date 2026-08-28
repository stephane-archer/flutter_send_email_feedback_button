## 0.4.0

* Add system and resolved application locales to runtime diagnostics.
* Add current-view logical size and device pixel ratio when a diagnostics
  context is available.
* Add native process architecture and a privacy-safe device model where the
  platform exposes one reliably.
* Add an optional `diagnosticsContext` argument to `sendEmail`; the packaged
  widget supplies it automatically.
* Keep package and device metadata collection independent and best-effort.
* Add `device_info_plus` 11.3.3 through 11.x and raise the package minimums to
  Dart 3.7 and Flutter 3.29.

## 0.3.0

* Add an optional pre-filled email body.
* Add runtime diagnostics for the app and operating system.
* Allow applications to append their own diagnostic fields.
* Return the platform launch result from `sendEmail`.
* Bound asynchronous diagnostic collection so email launches are still
  attempted when metadata lookup stalls.
* Add `package_info_plus` 8.3.1 through 8.x. This dependency is registered for
  every consuming app, even when runtime diagnostics are disabled. This is an
  integration-breaking change for applications below Android API 19, iOS 12,
  or macOS 10.14, or applications using older Android build tooling. Version
  8.x is pinned to prevent newer major versions from silently raising those
  requirements. See the README for the complete native requirements.
* Disable the feedback button while an email launch is in progress to prevent
  repeated taps from opening multiple composers.

## 0.2.0

* Expose `sendEmail` utility function for custom button implementations

## 0.1.0

* allow overwrite label

## 0.0.1

* initial release.
