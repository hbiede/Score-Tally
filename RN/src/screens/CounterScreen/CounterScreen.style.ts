import type { ThemeType } from 'Components/ThemeProvider/DefaultTheme';
import type { StrViewStyle } from 'Components/ThemeProvider/useStyle';

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
    borderRadius: '4@ms0.2',
    padding: '20@ms0.2',
  },
  container: {
    marginTop: '16@ms0.2',
    width: '100%',
  },
  emptyContainer: {
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
  },
  safeAreaContainer: {
    backgroundColor: theme.colors.background,
    flex: 1,
    width: '100%',
  },
  wrapper: {
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
  },
});

export default style;
