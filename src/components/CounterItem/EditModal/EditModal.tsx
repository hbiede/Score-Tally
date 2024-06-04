import React, {
  type JSX,
  useCallback,
  useEffect,
  useRef,
  useState,
} from 'react';
import {
  AccessibilityInfo,
  findNodeHandle,
  KeyboardAvoidingView,
  SafeAreaView,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import Modal from 'react-native-modal';
import { Animation } from 'react-native-animatable';

import { MaterialIcons } from '@expo/vector-icons';

import useStyle from 'Components/ThemeProvider/useStyle';

import useTheme from 'Components/ThemeProvider/useTheme';

import EditModalStyles from './EditModal.style';
import useReview from '../../../hooks/useReview';
import { SymbolView } from 'expo-symbols';

export const ModalState = {
  NONE: 'None',
  NAME: 'Name',
  SCORE: 'Score',
} as const;

type Props = {
  backButtonCallback?: () => void;
  error: string | null;
  isVisible: boolean;
  onSave: (newValue: string) => void;
  player: string;
  type?: (typeof ModalState)[keyof typeof ModalState];
  value?: string;
};

function EditModal({
  backButtonCallback = () => {},
  error,
  isVisible,
  onSave,
  player,
  type = ModalState.NONE,
  value: propValue = '',
}: Props): JSX.Element {
  const style = useStyle(EditModalStyles);
  const theme = useTheme();

  const [canAskForReview, askForReview] = useReview();

  const [value, setValue] = useState(propValue);
  const onValueChange = useCallback(
    (newValue: string) => setValue(newValue),
    [],
  );
  const invertValue = useCallback(() => {
    if (value) {
      if (value?.startsWith('-')) {
        setValue(value.slice(1));
      } else {
        setValue(`-${value}`);
      }
    } else {
      setValue('1');
    }
  }, [value]);

  useEffect(() => {
    setValue(propValue);
  }, [propValue]);

  const numberPropValue = Number(propValue);
  const numberValue = Number(value);
  const onSaveCallback = useCallback(() => {
    onSave(
      type === ModalState.SCORE ? `${numberPropValue + numberValue}` : value,
    );
    if (canAskForReview && numberPropValue > 0) {
      void askForReview();
    }
  }, [
    askForReview,
    canAskForReview,
    numberPropValue,
    numberValue,
    onSave,
    type,
    value,
  ]);

  const [selectTextOnFocus, setSelectTextOnFocus] = useState(true);
  useEffect(() => {
    AccessibilityInfo.isScreenReaderEnabled().then((result) =>
      setSelectTextOnFocus(!result),
    );
  }, []);
  const [animationTime, setAnimationTime] = useState(300);
  const [animation, setAnimation] = useState<{
    animateIn?: Animation;
    animateOut?: Animation;
  }>({});
  useEffect(() => {
    AccessibilityInfo.isReduceMotionEnabled().then((result) => {
      setAnimationTime(result ? 500 : 300);
      setAnimation(
        result
          ? {
              animateIn: 'fadeIn' as const,
              animateOut: 'fadeOut' as const,
            }
          : {},
      );
    });
  }, []);

  const errorViewRef = useRef<View>(null);
  const focusErrorOnAccessibility = useCallback(() => {
    if (errorViewRef.current) {
      const reactTag = findNodeHandle(errorViewRef.current);
      if (reactTag) {
        AccessibilityInfo.setAccessibilityFocus(reactTag);
      }
    }
  }, []);

  return (
    <SafeAreaView>
      <Modal
        accessibilityViewIsModal
        animationIn={animation.animateIn}
        animationInTiming={animationTime}
        animationOut={animation.animateOut}
        animationOutTiming={animationTime}
        isVisible={isVisible}
        onAccessibilityEscape={backButtonCallback}
        onBackButtonPress={backButtonCallback}
        style={style.modalContainer}
      >
        <KeyboardAvoidingView style={style.container}>
          <View>
            <View style={style.headerRow}>
              <TouchableOpacity
                style={style.headerButtonContainer}
                onPress={backButtonCallback}
                accessible
                accessibilityLabel="Back"
              >
                <SymbolView
                  name="chevron.backward"
                  resizeMode="scaleAspectFit"
                  size={30}
                  tintColor={theme.colors.primary}
                  fallback={
                    <MaterialIcons
                      name="chevron-left"
                      style={style.headerButton}
                    />
                  }
                />
              </TouchableOpacity>
              <Text style={style.titleText} accessible={false}>
                {type === ModalState.NAME ? 'Set Name' : 'Add to Score'}
              </Text>
              <TouchableOpacity
                style={style.headerButtonContainer}
                onPress={onSaveCallback}
                accessible
                accessibilityLabel={`Confirm ${type}`}
              >
                <SymbolView
                  name="checkmark"
                  resizeMode="scaleAspectFit"
                  size={30}
                  tintColor={theme.colors.primary}
                  fallback={
                    <MaterialIcons name="check" style={style.headerButton} />
                  }
                />
              </TouchableOpacity>
            </View>
            {type === ModalState.SCORE && (
              <Text style={style.nameText}>{player}</Text>
            )}
            <View style={style.textInputContainer}>
              <TextInput
                allowFontScaling
                keyboardType={
                  type === ModalState.SCORE ? 'number-pad' : 'default'
                }
                onChangeText={onValueChange}
                onSubmitEditing={onSaveCallback}
                placeholder={propValue}
                placeholderTextColor={`${theme.colors.text}88`}
                selectTextOnFocus={selectTextOnFocus}
                style={style.textInput}
                returnKeyType="done"
                value={value}
              />
            </View>
            {error && (
              <View
                style={style.errorContainer}
                accessibilityLiveRegion="assertive"
                accessibilityRole="alert"
                ref={errorViewRef}
                onLayout={focusErrorOnAccessibility}
              >
                <Text style={style.errorText}>{error}</Text>
              </View>
            )}
          </View>
          {type === ModalState.SCORE && (
            <>
              <TouchableOpacity
                style={style.extraButtonOutline}
                onPress={invertValue}
                accessibilityLabel="Invert value"
                accessibilityHint="Multiply the score by -1"
              >
                <SymbolView
                  name="plus.forwardslash.minus"
                  resizeMode="scaleAspectFit"
                  size={30}
                  tintColor={theme.colors.primary}
                  weight="heavy"
                  fallback={
                    <Text style={style.invertButtonText} accessible={false}>
                      +/-
                    </Text>
                  }
                />
              </TouchableOpacity>
              <Text style={style.mathText}>
                {numberPropValue} {numberValue < 0 ? '-' : '+'}{' '}
                {Math.abs(numberValue)} = {numberPropValue + numberValue}
              </Text>
              <TouchableOpacity
                style={style.extraButton}
                onPress={onSaveCallback}
                accessibilityLabel={`Confirm ${type}`}
              >
                <SymbolView
                  name="checkmark"
                  resizeMode="scaleAspectFit"
                  size={24}
                  tintColor={theme.colors.primaryAccent}
                  weight="semibold"
                  fallback={
                    <MaterialIcons
                      name="check"
                      size={24}
                      color={theme.colors.primaryAccent}
                    />
                  }
                />
              </TouchableOpacity>
            </>
          )}
        </KeyboardAvoidingView>
      </Modal>
    </SafeAreaView>
  );
}

export default EditModal;
