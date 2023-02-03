import { Dimensions } from 'react-native';

import { ThemeType } from 'Components/ThemeProvider/DefaultTheme';
import { StrTextStyle, StrViewStyle } from 'Components/ThemeProvider/useStyle';

type Style = {
  background: StrViewStyle;
  backgroundContainer: StrViewStyle;
  detail: StrTextStyle;
  orderButton: StrViewStyle;
  removeButton: StrViewStyle;
  removeWrapper: StrViewStyle;
  tally: StrTextStyle;
};

const style = (theme: ThemeType): Style => ({
  background: {
    alignItems: 'center',
    backgroundColor: theme.colors.background,
    flexDirection: 'row',
    height: 100,
    justifyContent: 'space-between',
  },
  backgroundContainer: {
    borderColor:
      theme.currentTheme === 'light' ? theme.colors.border : undefined,
    borderRadius: 20,
    backgroundColor: theme.colors.background,
    marginBottom: 12,
    marginHorizontal: 12,
    paddingHorizontal: 16,
    paddingVertical: 4,
    width: Dimensions.get('window').width - 24,

    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.2,
    shadowRadius: 3.84,
    elevation: 5,
  },
  detail: {
    color: theme.colors.primary,
    fontSize: '24@ms0.2',
    lineHeight: '30@ms0.2',
    textAlign: 'center',
  },
  orderButton: {
    aspectRatio: 1,
    backgroundColor: theme.colors.primary,
    borderRadius: '4@ms0.2',
    marginRight: '4@ms0.2',
  },
  removeButton: {
    marginLeft: '8@ms0.2',
  },
  removeWrapper: {
    alignItems: 'center',
    flexDirection: 'row',
  },
  tally: {
    color: theme.colors.secondary,
    fontSize: '24@ms0.2',
    marginRight: '4@ms0.2',
    textAlign: 'center',
  },
});

export default style;
