// url_strategy_proxy.dart
// This file proxies the urlStrategy call and uses conditional imports for web/non-web.

import 'url_strategy_proxy_stub.dart'
    if (dart.library.html) 'url_strategy_proxy_web.dart';

void pushUrlState(String path) => urlStrategyPushState(path);
