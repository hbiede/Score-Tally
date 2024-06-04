import { ExpoConfig } from '@expo/config-types';

const IS_INT_DEV = process.env.APP_VARIANT === 'internal_development';

const config: ExpoConfig = {
  name: IS_INT_DEV ? 'Expo Score Tally' : 'Score Tally',
  description: 'Easily track scores for games',
  githubUrl: 'https://github.com/hbiede/Score-Tally',
  slug: 'ScoreTally',
  privacy: 'public',
  platforms: ['ios', 'android'],
  version: '1.2.0',
  orientation: 'default',
  icon: './assets/icon.png',
  splash: {
    image: './assets/splash.png',
    resizeMode: 'contain',
    backgroundColor: '#0B9D20',
  },
  ios: {
    bitcode: true,
    buildNumber: '9',
    bundleIdentifier: 'com.hbiede.ScoreTally',
    config: {
      usesNonExemptEncryption: false,
    },
    infoPlist: {
      NSCameraUsageDescription:
        'The camera is used to scan QR codes/barcodes, and to capture images for transactions.',
      UIBackgroundModes: ['fetch'],
    },
    supportsTablet: true,
    requireFullScreen: false,
    userInterfaceStyle: 'automatic',
    privacyManifests: {
      NSPrivacyTracking: false,
    },
  },
  android: {
    package: 'com.hbiede.ScoreTally',
    softwareKeyboardLayoutMode: 'resize',
    versionCode: 10200,
  },
  jsEngine: 'hermes',
  runtimeVersion: {
    policy: 'fingerprint',
  },
  updates: {
    url: 'https://u.expo.dev/9b0cc3a3-99d1-417b-8726-8fed445eb171',
  },
  extra: {
    eas: {
      projectId: '9b0cc3a3-99d1-417b-8726-8fed445eb171',
    },
    updates: {
      assetBundlePatterns: [
        'resources/**',
        'submodules/wedgekit/resources/**',
        'submodules/wedgekit/**/resources/**',
      ],
    },
  },
};

export default config;
