/**
 * @format
 */

import React from 'react';
import InAppBrowser from 'react-native-inappbrowser-reborn';
import ReactTestRenderer from 'react-test-renderer';
import App from '../App';

const mockInjectJavaScript = jest.fn();

jest.mock('react-native-inappbrowser-reborn', () => ({
  __esModule: true,
  default: {
    isAvailable: jest.fn(() => Promise.resolve(true)),
    open: jest.fn(() => Promise.resolve({ type: 'dismiss' })),
  },
}));

jest.mock('react-native-safe-area-context', () => {
  const { View } = require('react-native');

  return {
    SafeAreaProvider: ({ children }: { children: React.ReactNode }) => (
      <View>{children}</View>
    ),
    SafeAreaView: ({ children, ...props }: { children: React.ReactNode }) => (
      <View {...props}>{children}</View>
    ),
  };
});

jest.mock('react-native-webview', () => {
  const ReactRuntime = require('react');
  const { View } = require('react-native');

  return {
    WebView: ReactRuntime.forwardRef((props: any, ref: any) => {
      ReactRuntime.useImperativeHandle(ref, () => ({
        goBack: jest.fn(),
        injectJavaScript: mockInjectJavaScript,
        reload: jest.fn(),
      }));

      return <View {...props} testID="mock-webview" />;
    }),
  };
});

function getWebView(renderer: ReactTestRenderer.ReactTestRenderer) {
  const webView = getWebViews(renderer)[0];

  if (!webView) {
    throw new Error('WebView not found');
  }

  return webView;
}

function getWebViews(renderer: ReactTestRenderer.ReactTestRenderer) {
  const webViews = renderer.root.findAll(node => {
    return (
      node.props.testID === 'mock-webview' &&
      typeof node.props.source?.uri === 'string'
    );
  });

  return webViews.filter((webView, index) => {
    return (
      webViews.findIndex(
        otherWebView =>
          otherWebView.props.source.uri === webView.props.source.uri,
      ) === index
    );
  });
}

beforeEach(() => {
  jest.clearAllMocks();
});

test('renders correctly', async () => {
  await ReactTestRenderer.act(() => {
    ReactTestRenderer.create(<App />);
  });
});

test('opens portal new-window requests in an app WebView modal', async () => {
  let renderer!: ReactTestRenderer.ReactTestRenderer;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  ReactTestRenderer.act(() => {
    getWebView(renderer).props.onOpenWindow({
      nativeEvent: {
        targetUrl: 'https://openteam.ai/settings',
      },
    });
  });

  const webViews = getWebViews(renderer);

  expect(webViews).toHaveLength(2);
  expect(webViews[1].props.source.uri).toBe('https://openteam.ai/settings');
  expect(webViews[1].props.sharedCookiesEnabled).toBe(true);
  expect(mockInjectJavaScript).not.toHaveBeenCalled();
  expect(InAppBrowser.open).not.toHaveBeenCalled();
});

test('opens external new-window requests in the in-app browser', async () => {
  let renderer!: ReactTestRenderer.ReactTestRenderer;

  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  await ReactTestRenderer.act(async () => {
    getWebView(renderer).props.onOpenWindow({
      nativeEvent: {
        targetUrl: 'https://example.com/docs',
      },
    });

    await Promise.resolve();
    await Promise.resolve();
  });

  expect(mockInjectJavaScript).not.toHaveBeenCalled();
  expect(getWebViews(renderer)).toHaveLength(1);
  expect(InAppBrowser.open).toHaveBeenCalledWith(
    'https://example.com/docs',
    expect.objectContaining({
      modalEnabled: true,
    }),
  );
});
