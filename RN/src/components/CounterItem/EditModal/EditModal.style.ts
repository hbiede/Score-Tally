import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { StrTextStyle, StrViewStyle } from 'Components/ThemeProvider/useStyle';
import { ThemeType } from 'Components/ThemeProvider/DefaultTheme';

type Styles = {
  container: StrViewStyle;
  errorContainer: StrViewStyle;
  errorText: StrTextStyle;
  extraButton: StrViewStyle;
  extraButtonOutline: StrViewStyle;
  headerButton: StrTextStyle;
  headerButtonContainer: StrViewStyle;
  headerRow: StrViewStyle;
  invertButtonText: StrTextStyle;
  mathText: StrTextStyle;
  modalContainer: StrViewStyle;
  nameText: StrTextStyle;
  textInput: StrTextStyle;
  textInputContainer: StrViewStyle;
  titleText: StrTextStyle;
};

export default (theme: ThemeType): Styles => {
  const { top: marginTop } = useSafeAreaInsets();
  return {
    container: {
      width: '100%',
    },
    modalContainer: {
      alignItems: 'center',
      backgroundColor: theme.colors.background,
      borderTopLeftRadius: '16@ms0.2',
      borderTopRightRadius: '16@ms0.2',
      flexDirection: 'column',
      justifyContent: 'flex-start',
      margin: 0,
      marginTop,
      paddingHorizontal: '15@ms0.2',
    },
    errorContainer: {
      backgroundColor: theme.colors.error,
      borderRadius: '4@ms0.2',
      marginTop: '20@ms0.2',
      padding: '10@ms0.2',
    },
    errorText: {
      color: theme.colors.errorText,
      fontSize: '16@ms0.2',
      lineHeight: '20@ms0.2',
      textAlign: 'center',
    },
    extraButton: {
      alignItems: 'center',
      backgroundColor: theme.colors.primary,
      borderRadius: '4@ms0.2',
      flexDirection: 'row',
      justifyContent: 'center',
      marginTop: '20@ms0.2',
      paddingVertical: '16@ms0.2',
    },
    extraButtonOutline: {
      alignItems: 'center',
      borderColor: theme.colors.primary,
      borderRadius: '4@ms0.2',
      borderWidth: '2@ms0.2',
      flexDirection: 'row',
      justifyContent: 'center',
      marginTop: '20@ms0.2',
      paddingVertical: '8@ms0.2',
    },
    headerButton: {
      color: theme.colors.primary,
      fontSize: '45@ms0.2',
    },
    headerButtonContainer: {
      alignContent: 'center',
      alignItems: 'center',
      flexDirection: 'row',
    },
    headerRow: {
      alignItems: 'center',
      flexDirection: 'row',
      justifyContent: 'space-between',
      marginTop: '20@ms0.2',
      marginBottom: '30@ms0.2',
      width: '100%',
    },
    invertButtonText: {
      color: theme.colors.primary,
      fontSize: '25@ms0.2',
    },
    mathText: {
      fontSize: '18@ms0.2',
      paddingTop: '12@ms0.2',
      textAlign: 'center',
    },
    nameText: {
      color: theme.colors.primary,
      fontSize: '24@ms0.2',
      textAlign: 'center',
    },
    textInput: {
      color: theme.colors.text,
      fontSize: '25@ms0.2',
      textAlign: 'center',
    },
    textInputContainer: {
      borderColor: theme.colors.border,
      borderRadius: '8@ms0.2',
      borderWidth: '1@ms0.2',
      marginTop: '20@ms0.2',
      padding: '10@ms0.2',
      width: '100%',
    },
    titleText: {
      color: theme.colors.text,
      fontSize: '30@ms0.2',
      lineHeight: '35@ms0.2',
    },
  };
};
