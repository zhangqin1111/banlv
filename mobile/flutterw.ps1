$ErrorActionPreference = 'Stop'

$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'

$flutter = 'D:\flutter-sdk\bin\flutter.bat'
if (!(Test-Path $flutter)) {
  throw "Flutter SDK not found at $flutter"
}

& $flutter @args
