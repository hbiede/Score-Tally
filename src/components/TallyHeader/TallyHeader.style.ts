import type { ThemeType } from 'Components/ThemeProvider/DefaultTheme';
import type {
  StrTextStyle,
  StrViewStyle,
} from 'Components/ThemeProvider/useStyle';

type Style = {
  buttonContainer: StrViewStyle;
  container: StrViewStyle;
  shadowContainer: StrViewStyle;
  title: StrTextStyle;
};

export const ICON_SIZE = 30;

export default (theme: ThemeType): Style => ({
  buttonContainer: {
    width: '40@ms0.2',
  },
  container: {
    alignItems: 'center',
    alignSelf: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: '12@ms0.2',
    paddingVertical: '12@ms0.2',
    width: '100%',
  },
  shadowContainer: {
    backgroundColor: theme.colors.accentBackground,
    shadowOffset: { height: 4, width: 0 },
    shadowOpacity: theme.currentTheme === 'light' ? 0.25 : 0.75,
    shadowColor: theme.colors.accentBackground,
    shadowRadius: 8,
    zIndex: 1,
    elevation: 5,
  },
  title: {
    color: theme.colors.primary,
    fontSize: '45@ms0.2',
    lineHeight: '50@ms0.2',
    textAlign: 'center',
  },
});
