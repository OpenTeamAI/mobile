import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  BackHandler,
  Image,
  Linking,
  Modal,
  Platform,
  Pressable,
  StatusBar,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import {
  SafeAreaProvider,
  SafeAreaView,
  type Edge,
} from 'react-native-safe-area-context';
import InAppBrowser from 'react-native-inappbrowser-reborn';
import { WebView } from 'react-native-webview';
import type {
  ShouldStartLoadRequest,
  WebViewMessageEvent,
  WebViewNavigation,
  WebViewOpenWindowEvent,
} from 'react-native-webview/lib/WebViewTypes';
import { PORTAL_HOST_SET, PORTAL_URL } from './src/config/portal';

const LOGO_SOURCE = require('./src/assets/logo.png');
const OPEN_WINDOW_MESSAGE_TYPE = 'openteam-open-window';
const TOP_SAFE_AREA_EDGES: Edge[] = Platform.OS === 'ios' ? [] : ['top'];
const PORTAL_WINDOW_SAFE_AREA_EDGES: Edge[] =
  Platform.OS === 'ios' ? ['top'] : ['top'];
const NEW_WINDOW_INTERCEPT_SCRIPT = `
(function() {
  if (window.__openteamNativeWindowPatch) {
    return;
  }

  window.__openteamNativeWindowPatch = true;

  function toAbsoluteUrl(url) {
    try {
      return new URL(url, window.location.href).href;
    } catch (error) {
      return url;
    }
  }

  function postOpenWindow(url) {
    if (!url || isWebViewPlaceholderUrl(url) || !window.ReactNativeWebView) {
      return false;
    }

    window.ReactNativeWebView.postMessage(JSON.stringify({
      type: '${OPEN_WINDOW_MESSAGE_TYPE}',
      url: url
    }));

    return true;
  }

  function isWebViewPlaceholderUrl(url) {
    var normalizedUrl = String(url).trim().toLowerCase();

    return (
      normalizedUrl === 'about:blank' ||
      normalizedUrl.indexOf('about:blank#') === 0 ||
      normalizedUrl.indexOf('about:blank?') === 0 ||
      normalizedUrl === 'about:srcdoc'
    );
  }

  function createPopupShim(initialUrl) {
    var locationValue = initialUrl || 'about:blank';
    var locationObject = {
      assign: function(nextUrl) {
        locationObject.href = nextUrl;
      },
      replace: function(nextUrl) {
        locationObject.href = nextUrl;
      },
      toString: function() {
        return locationValue;
      }
    };
    var popup = {
      blur: function() {},
      close: function() {
        popup.closed = true;
      },
      closed: false,
      focus: function() {},
      opener: window,
      postMessage: function() {}
    };

    Object.defineProperty(locationObject, 'href', {
      get: function() {
        return locationValue;
      },
      set: function(nextUrl) {
        locationValue = toAbsoluteUrl(nextUrl);
        postOpenWindow(locationValue);
      }
    });

    Object.defineProperty(popup, 'location', {
      get: function() {
        return locationObject;
      },
      set: function(nextUrl) {
        locationObject.href = nextUrl;
      }
    });

    return popup;
  }

  window.open = function(url) {
    var targetUrl = url ? toAbsoluteUrl(url) : 'about:blank';

    postOpenWindow(targetUrl);

    return createPopupShim(targetUrl);
  };

  var openAnchor = function(anchor) {
    if (!anchor || !anchor.href) {
      return false;
    }

    return postOpenWindow(anchor.href);
  };

  document.addEventListener('click', function(event) {
    var anchor = event.target && event.target.closest
      ? event.target.closest('a[target="_blank"]')
      : null;

    if (!openAnchor(anchor)) {
      return;
    }

    event.preventDefault();
  }, true);
})();
true;
`;

type ParsedWebViewMessage = {
  type: typeof OPEN_WINDOW_MESSAGE_TYPE;
  url: string;
};

function isPortalHost(hostname: string) {
  return PORTAL_HOST_SET.has(hostname.toLowerCase());
}

function normalizePortalUrl(url: string | null | undefined) {
  if (!url) {
    return null;
  }

  try {
    const parsedUrl = new URL(url);
    const isHttp =
      parsedUrl.protocol === 'https:' || parsedUrl.protocol === 'http:';

    if (!isHttp || !isPortalHost(parsedUrl.hostname)) {
      return null;
    }

    return parsedUrl.toString();
  } catch {
    return null;
  }
}

function buildPortalRequestUrl(url: string, requestNonce: number) {
  try {
    const parsedUrl = new URL(url);
    parsedUrl.searchParams.set('_native_reload', String(requestNonce));
    return parsedUrl.toString();
  } catch {
    return url;
  }
}

function isHttpUrl(url: string) {
  return /^https?:/i.test(url);
}

function isWebViewPlaceholderUrl(url: string | null | undefined) {
  if (!url) {
    return false;
  }

  const normalizedUrl = url.trim().toLowerCase();

  return (
    normalizedUrl === 'about:blank' ||
    normalizedUrl.startsWith('about:blank#') ||
    normalizedUrl.startsWith('about:blank?') ||
    normalizedUrl === 'about:srcdoc'
  );
}

function parseWebViewMessage(data: string): ParsedWebViewMessage | null {
  try {
    const message = JSON.parse(data);

    if (
      message?.type === OPEN_WINDOW_MESSAGE_TYPE &&
      typeof message.url === 'string'
    ) {
      return {
        type: OPEN_WINDOW_MESSAGE_TYPE,
        url: message.url,
      };
    }
  } catch {}

  return null;
}

function App() {
  return (
    <SafeAreaProvider>
      <StatusBar backgroundColor="#ffffff" barStyle="dark-content" />
      <PortalShell />
    </SafeAreaProvider>
  );
}

function PortalShell() {
  const webViewRef = useRef<WebView>(null);
  const portalWindowRef = useRef<WebView>(null);
  const lastBrowserOpenRef = useRef<{
    openedAt: number;
    url: string;
  } | null>(null);
  const [webKey, setWebKey] = useState(0);
  const [canGoBack, setCanGoBack] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [portalWindowCanGoBack, setPortalWindowCanGoBack] = useState(false);
  const [portalWindowUrl, setPortalWindowUrl] = useState<string | null>(null);
  const [portalWindowKey, setPortalWindowKey] = useState(0);
  const [sourceUri, setSourceUri] = useState(PORTAL_URL);
  const [requestNonce, setRequestNonce] = useState(() => Date.now());

  const loadPortalUrl = useCallback((incomingUrl: string | null | undefined) => {
    const nextUrl = normalizePortalUrl(incomingUrl);

    if (!nextUrl) {
      return false;
    }

    setLoadError(null);
    setSourceUri(nextUrl);
    setRequestNonce(Date.now());
    setWebKey(currentValue => currentValue + 1);

    return true;
  }, []);

  const openPortalWindow = useCallback(
    (incomingUrl: string | null | undefined) => {
      const nextUrl = normalizePortalUrl(incomingUrl);

      if (!nextUrl) {
        return false;
      }

      setLoadError(null);
      setPortalWindowCanGoBack(false);
      setPortalWindowUrl(nextUrl);
      setPortalWindowKey(currentValue => currentValue + 1);

      return true;
    },
    [],
  );

  const closePortalWindow = useCallback(() => {
    setPortalWindowCanGoBack(false);
    setPortalWindowUrl(null);
  }, []);

  const openExternalUrl = useCallback((url: string) => {
    if (isWebViewPlaceholderUrl(url)) {
      return;
    }

    Linking.openURL(url).catch(() => {
      setLoadError(`Unable to open external link: ${url}`);
    });
  }, []);

  const openSystemBrowser = useCallback(
    async (url: string | null | undefined) => {
      if (!url) {
        return;
      }

      if (isWebViewPlaceholderUrl(url)) {
        return;
      }

      if (!isHttpUrl(url)) {
        openExternalUrl(url);
        return;
      }

      const now = Date.now();
      const lastOpen = lastBrowserOpenRef.current;

      if (lastOpen?.url === url && now - lastOpen.openedAt < 900) {
        return;
      }

      lastBrowserOpenRef.current = {
        openedAt: now,
        url,
      };

      try {
        const isAvailable = await InAppBrowser.isAvailable();

        if (!isAvailable) {
          openExternalUrl(url);
          return;
        }

        await InAppBrowser.open(url, {
          allowSwipeDismissal: true,
          animated: true,
          dismissButtonStyle: 'close',
          enableBarCollapsing: false,
          enableDefaultShare: true,
          enableUrlBarHiding: false,
          ephemeralWebSession: false,
          modalEnabled: true,
          modalPresentationStyle: 'automatic',
          modalTransitionStyle: 'coverVertical',
          preferredBarTintColor: '#ffffff',
          preferredControlTintColor: '#111111',
          readerMode: false,
          showTitle: true,
        });
      } catch {
        openExternalUrl(url);
      }
    },
    [openExternalUrl],
  );

  const openNewWindowUrl = useCallback(
    (url: string | null | undefined) => {
      if (!url || isWebViewPlaceholderUrl(url)) {
        return;
      }

      if (openPortalWindow(url)) {
        return;
      }

      openSystemBrowser(url);
    },
    [openPortalWindow, openSystemBrowser],
  );

  useEffect(() => {
    if (Platform.OS !== 'android') {
      return;
    }

    const subscription = BackHandler.addEventListener(
      'hardwareBackPress',
      () => {
        if (canGoBack) {
          webViewRef.current?.goBack();
          return true;
        }

        return false;
      },
    );

    return () => subscription.remove();
  }, [canGoBack]);

  useEffect(() => {
    let isMounted = true;

    Linking.getInitialURL()
      .then(initialUrl => {
        if (isMounted) {
          loadPortalUrl(initialUrl);
        }
      })
      .catch(() => {});

    const subscription = Linking.addEventListener('url', event => {
      loadPortalUrl(event.url);
    });

    return () => {
      isMounted = false;
      subscription.remove();
    };
  }, [loadPortalUrl]);

  const handleNavigationStateChange = (navigationState: WebViewNavigation) => {
    setCanGoBack(navigationState.canGoBack);
  };

  const handlePortalWindowNavigationStateChange = (
    navigationState: WebViewNavigation,
  ) => {
    setPortalWindowCanGoBack(navigationState.canGoBack);
  };

  const handlePortalWindowRequestClose = () => {
    if (portalWindowCanGoBack) {
      portalWindowRef.current?.goBack();
      return;
    }

    closePortalWindow();
  };

  const retryLoading = () => {
    setLoadError(null);
    setRequestNonce(Date.now());
    setWebKey(currentValue => currentValue + 1);
  };

  const handleOpenWindow = useCallback(
    (event: WebViewOpenWindowEvent) => {
      openNewWindowUrl(event.nativeEvent.targetUrl);
    },
    [openNewWindowUrl],
  );

  const handleWebViewMessage = useCallback(
    (event: WebViewMessageEvent) => {
      const message = parseWebViewMessage(event.nativeEvent.data);

      if (message?.type === OPEN_WINDOW_MESSAGE_TYPE) {
        openNewWindowUrl(message.url);
      }
    },
    [openNewWindowUrl],
  );

  const handleShouldStartLoadWithRequest = useCallback(
    (request: ShouldStartLoadRequest) => {
      if (!request.url) {
        return false;
      }

      if (isWebViewPlaceholderUrl(request.url)) {
        return false;
      }

      if (isHttpUrl(request.url)) {
        try {
          const parsedUrl = new URL(request.url);

          if (!request.isTopFrame || isPortalHost(parsedUrl.hostname)) {
            return true;
          }

          openSystemBrowser(request.url);
          return false;
        } catch {
          return true;
        }
      }

      openExternalUrl(request.url);

      return false;
    },
    [openExternalUrl, openSystemBrowser],
  );

  const renderLoading = () => (
    <View style={styles.loadingState}>
      <Image
        source={LOGO_SOURCE}
        style={styles.loadingLogo}
        resizeMode="contain"
      />
      <ActivityIndicator size="large" color="#0d6efd" />
    </View>
  );

  const requestUri = buildPortalRequestUrl(sourceUri, requestNonce);

  return (
    <SafeAreaView edges={TOP_SAFE_AREA_EDGES} style={styles.safeArea}>
      <View style={styles.screen}>
        {loadError ? (
          <View style={styles.errorState}>
            <Image
              source={LOGO_SOURCE}
              style={styles.errorLogo}
              resizeMode="contain"
            />
            <Text style={styles.errorTitle}>OpenTeam failed to load</Text>
            <Text style={styles.errorMessage}>{loadError}</Text>

            <Pressable
              accessibilityRole="button"
              onPress={retryLoading}
              style={styles.retryButton}
            >
              <Text style={styles.retryButtonLabel}>Try Again</Text>
            </Pressable>
          </View>
        ) : (
          <WebView
            key={webKey}
            ref={webViewRef}
            source={{ uri: requestUri }}
            allowsBackForwardNavigationGestures
            allowsInlineMediaPlayback
            cacheEnabled
            cacheMode={Platform.OS === 'android' ? 'LOAD_NO_CACHE' : undefined}
            hideKeyboardAccessoryView
            injectedJavaScript={NEW_WINDOW_INTERCEPT_SCRIPT}
            injectedJavaScriptBeforeContentLoaded={NEW_WINDOW_INTERCEPT_SCRIPT}
            javaScriptCanOpenWindowsAutomatically
            mediaCapturePermissionGrantType="grantIfSameHostElsePrompt"
            mediaPlaybackRequiresUserAction={false}
            onError={event => setLoadError(event.nativeEvent.description)}
            onHttpError={event =>
              setLoadError(
                `HTTP ${event.nativeEvent.statusCode} while loading portal`,
              )
            }
            onContentProcessDidTerminate={() => {
              webViewRef.current?.reload();
            }}
            onMessage={handleWebViewMessage}
            onNavigationStateChange={handleNavigationStateChange}
            onOpenWindow={handleOpenWindow}
            onShouldStartLoadWithRequest={handleShouldStartLoadWithRequest}
            originWhitelist={['http://*', 'https://*']}
            renderLoading={renderLoading}
            setSupportMultipleWindows
            sharedCookiesEnabled
            startInLoadingState
            style={styles.webView}
          />
        )}
        <Modal
          allowSwipeDismissal
          animationType="slide"
          onRequestClose={handlePortalWindowRequestClose}
          presentationStyle="pageSheet"
          visible={Boolean(portalWindowUrl)}
        >
          <SafeAreaView
            edges={PORTAL_WINDOW_SAFE_AREA_EDGES}
            style={styles.portalWindowSafeArea}
          >
            <View style={styles.portalWindowHeader}>
              <Pressable
                accessibilityRole="button"
                disabled={!portalWindowCanGoBack}
                onPress={() => portalWindowRef.current?.goBack()}
                style={[
                  styles.portalWindowHeaderButton,
                  !portalWindowCanGoBack &&
                    styles.portalWindowHeaderButtonDisabled,
                ]}
              >
                <Text style={styles.portalWindowHeaderButtonLabel}>Back</Text>
              </Pressable>

              <Text numberOfLines={1} style={styles.portalWindowTitle}>
                openteam.ai
              </Text>

              <Pressable
                accessibilityRole="button"
                onPress={closePortalWindow}
                style={styles.portalWindowHeaderButton}
              >
                <Text style={styles.portalWindowHeaderButtonLabel}>Close</Text>
              </Pressable>
            </View>

            {portalWindowUrl ? (
              <WebView
                key={portalWindowKey}
                ref={portalWindowRef}
                source={{ uri: portalWindowUrl }}
                allowsBackForwardNavigationGestures
                allowsInlineMediaPlayback
                cacheEnabled
                cacheMode={
                  Platform.OS === 'android' ? 'LOAD_NO_CACHE' : undefined
                }
                hideKeyboardAccessoryView
                injectedJavaScript={NEW_WINDOW_INTERCEPT_SCRIPT}
                injectedJavaScriptBeforeContentLoaded={
                  NEW_WINDOW_INTERCEPT_SCRIPT
                }
                javaScriptCanOpenWindowsAutomatically
                mediaCapturePermissionGrantType="grantIfSameHostElsePrompt"
                mediaPlaybackRequiresUserAction={false}
                onError={event => setLoadError(event.nativeEvent.description)}
                onHttpError={event =>
                  setLoadError(
                    `HTTP ${event.nativeEvent.statusCode} while loading portal`,
                  )
                }
                onMessage={handleWebViewMessage}
                onNavigationStateChange={
                  handlePortalWindowNavigationStateChange
                }
                onOpenWindow={handleOpenWindow}
                onShouldStartLoadWithRequest={handleShouldStartLoadWithRequest}
                originWhitelist={['http://*', 'https://*']}
                renderLoading={renderLoading}
                setSupportMultipleWindows
                sharedCookiesEnabled
                startInLoadingState
                style={styles.webView}
                thirdPartyCookiesEnabled
              />
            ) : null}
          </SafeAreaView>
        </Modal>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  errorLogo: {
    height: 96,
    marginBottom: 20,
    width: 96,
  },
  errorMessage: {
    color: '#475569',
    fontSize: 15,
    lineHeight: 22,
    marginBottom: 24,
    textAlign: 'center',
  },
  errorState: {
    alignItems: 'center',
    backgroundColor: '#ffffff',
    flex: 1,
    justifyContent: 'center',
    paddingHorizontal: 24,
  },
  errorTitle: {
    color: '#0f172a',
    fontSize: 24,
    fontWeight: '700',
    marginBottom: 10,
  },
  loadingLogo: {
    height: 120,
    marginBottom: 18,
    width: 120,
  },
  loadingState: {
    alignItems: 'center',
    backgroundColor: '#ffffff',
    flex: 1,
    justifyContent: 'center',
    paddingHorizontal: 24,
  },
  retryButton: {
    alignItems: 'center',
    backgroundColor: '#0d6efd',
    borderRadius: 999,
    justifyContent: 'center',
    minHeight: 48,
    minWidth: 128,
    paddingHorizontal: 24,
  },
  portalWindowHeader: {
    alignItems: 'center',
    borderBottomColor: '#e5e7eb',
    borderBottomWidth: StyleSheet.hairlineWidth,
    flexDirection: 'row',
    minHeight: 52,
    paddingHorizontal: 12,
  },
  portalWindowHeaderButton: {
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 44,
    minWidth: 64,
  },
  portalWindowHeaderButtonDisabled: {
    opacity: 0.35,
  },
  portalWindowHeaderButtonLabel: {
    color: '#111111',
    fontSize: 15,
    fontWeight: '600',
  },
  portalWindowSafeArea: {
    backgroundColor: '#ffffff',
    flex: 1,
  },
  portalWindowTitle: {
    color: '#111111',
    flex: 1,
    fontSize: 16,
    fontWeight: '700',
    textAlign: 'center',
  },
  retryButtonLabel: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '700',
  },
  safeArea: {
    backgroundColor: '#ffffff',
    flex: 1,
  },
  screen: {
    backgroundColor: '#ffffff',
    flex: 1,
  },
  webView: {
    backgroundColor: '#ffffff',
    flex: 1,
  },
});

export default App;
