import 'update_logic_stub.dart' if (dart.library.html) 'update_logic_web.dart' if (dart.library.js) 'update_logic_web.dart' as impl;

void forceAppUpdate() {
  impl.forceReload();
}
