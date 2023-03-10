import { ThemeType } from 'Components/ThemeProvider/DefaultTheme';
import { StrViewStyle } from 'Components/ThemeProvider/useStyle';

type Style = {
  addButton: StrViewStyle;
  container: StrViewStyle;
  emptyContainer: StrViewStyle;
  safeAreaContainer: StrViewStyle;
  wrapper: StrViewStyle;
};

const style = (theme: ThemeType): Style => ({
  addButton: {
    backgroundColor: theme.colors.primary,
    borderRadius: 4,
    padding: 20,
  },
  container: {
    padding: 5,
    width: '100%',
  },
  emptyContainer: {
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
  },
  safeAreaContainer: {
    backgroundColor: theme.colors.accentBackground,
    flex: 1,
    height: '100%',
    width: '100%',
  },
  wrapper: {
    alignItems: 'center',
    height: '100%',
    justifyContent: 'center',
    width: '100%',
  },
});

export default style;
