import { ExpoConfig } from '@expo/config-types';

const IS_INT_DEV = process.env.APP_VARIANT === 'internal_development';

const config: ExpoConfig = {
  name: IS_INT_DEV ? 'Expo Score Tally' : 'Score Tally',
  description: 'Easily track scores for games',
  githubUrl: 'https://github.com/hbiede/Score-Tally',
  slug: 'ScoreTally',
  entryPoint: './index.js',
  privacy: 'public',
  platforms: ['ios', 'android'],
  version: '1.0.0',
  orientation: 'default',
  icon: './assets/icon.png',
  splash: {
    image: './assets/splash.png',
    resizeMode: 'contain',
    backgroundColor: '#0B9D20',
  },
  ios: {
    buildNumber: '2',
    bundleIdentifier: IS_INT_DEV
      ? 'com.hbiede.intDev.ScoreTally'
      : 'com.hbiede.ScoreTally',
    infoPlist: {
      ITSAppUsesNonExemptEncryption: false,
      NSCameraUsageDescription:
        'The camera is used to scan QR codes/barcodes, and to capture images for transactions.',
      UIBackgroundModes: ['fetch'],
    },
    supportsTablet: true,
    requireFullScreen: false,
    userInterfaceStyle: 'automatic',
  },
  android: {
    package: IS_INT_DEV
      ? 'com.hbiede.intDev.ScoreTally'
      : 'com.hbiede.ScoreTally',
    softwareKeyboardLayoutMode: 'resize',
    versionCode: 10000,
  },
  assetBundlePatterns: [
    'resources/**',
    'submodules/wedgekit/resources/**',
    'submodules/wedgekit/**/resources/**',
  ],
  jsEngine: IS_INT_DEV ? 'jsc' : 'hermes',
  runtimeVersion: 'exposdk:47.0.0',
  extra: {
    eas: {
      projectId: '9b0cc3a3-99d1-417b-8726-8fed445eb171',
    },
  },
};

export default config;
