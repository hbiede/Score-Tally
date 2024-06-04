import { Dimensions, Platform } from 'react-native';

import type { ThemeType } from 'Components/ThemeProvider/DefaultTheme';
import type {
  StrTextStyle,
  StrViewStyle,
} from 'Components/ThemeProvider/useStyle';

type Style = {
  background: StrViewStyle;
  backgroundContainer: StrViewStyle;
  detail: StrTextStyle;
  leftSectionWrapper: StrViewStyle;
  orderButton: StrViewStyle;
  removeButton: StrViewStyle;
  removeWrapper: StrViewStyle;
  tally: StrTextStyle;
};

const isPad = Platform.OS === 'ios' && Platform.isPad;

const style = (theme: ThemeType): Style => ({
  background: {
    alignItems: 'center',
    backgroundColor: theme.colors.accentBackground,
    flexDirection: 'row',
    height: 100,
    justifyContent: 'space-between',
  },
  backgroundContainer: {
    borderColor:
      theme.currentTheme === 'light' ? theme.colors.border : undefined,
    borderRadius: '20@ms0.2',
    backgroundColor: theme.colors.accentBackground,
    marginBottom: '12@ms0.2',
    marginHorizontal: '8@ms0.2',
    paddingHorizontal: '16@ms0.2',
    paddingVertical: '4@ms0.2',
    width:
      Dimensions.get('window').width / (isPad ? 2 : 1) - 24 * (isPad ? 2 : 1.5),

    shadowColor: theme.colors.accentBackground,
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.5,
    shadowRadius: 3.84,
    elevation: 5,
  },
  detail: {
    color: theme.colors.primary,
    fontSize: '24@ms0.2',
    lineHeight: '30@ms0.2',
    textAlign: 'center',
  },
  leftSectionWrapper: {
    alignItems: 'center',
    flexDirection: 'row',
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
