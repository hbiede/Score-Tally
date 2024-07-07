import React, { type JSX, useCallback, useState } from 'react';
import {
  AccessibilityActionEvent,
  LayoutAnimation,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { impactAsync, ImpactFeedbackStyle } from 'expo-haptics';

import { MaterialIcons } from '@expo/vector-icons';

import { useDispatch, useSelector } from 'react-redux';

import CounterItemStyle from 'Components/CounterItem/CounterItem.style';
import useStyle from 'Components/ThemeProvider/useStyle';
import { Counter } from 'Statics/Types';
import {
  removeCounter,
  updateCounter,
  updateOrder,
} from 'Redux/modules/counters';
import useTheme from 'Components/ThemeProvider/useTheme';
import EditModal, {
  ModalState,
} from 'Components/CounterItem/EditModal/EditModal';
import { AppReduxState } from 'Redux/modules/reducer';
import { SymbolView } from 'expo-symbols';

type Props = {
  data: Counter;
  index: number;
  isEditing?: boolean;
  place: number;
};

const getPlaceString = (place: number): string => {
  switch (place) {
    case 1:
      return '🥇 ';
    case 2:
      return '🥈 ';
    case 3:
      return '🥉 ';
    default:
      return '';
  }
};

const getPlaceA11yString = (place: number): string => {
  switch (place) {
    case 1:
      return 'first place';
    case 2:
      return 'second place';
    case 3:
      return 'third place';
    default:
      return '';
  }
};

const CounterItem = ({ data, index, isEditing, place }: Props): JSX.Element => {
  const dispatch = useDispatch();
  const [currentModalState, setModalState] = useState<
    (typeof ModalState)[keyof typeof ModalState]
  >(ModalState.NONE);
  const [error, setError] = useState<string | null>(null);
  const playerCount = useSelector(
    (state: AppReduxState) => state.counters.counters.length,
  );

  const setScore = useCallback(
    (score = data.tally + 1) => {
      dispatch(
        updateCounter({
          ...data,
          tally: score,
        }),
      );
    },
    [data, dispatch],
  );
  const increment = useCallback(() => {
    void impactAsync(ImpactFeedbackStyle.Light);
    setScore();
  }, [setScore]);

  const onSetRequest = useCallback(() => {
    void impactAsync(ImpactFeedbackStyle.Heavy);
    setModalState(ModalState.SCORE);
  }, []);

  const onRemove = useCallback(() => {
    dispatch(removeCounter(data));
    if (playerCount > 1) {
      LayoutAnimation.easeInEaseOut();
    }
    void impactAsync(ImpactFeedbackStyle.Heavy);
  }, [data, dispatch, playerCount]);

  const onBackPress = useCallback(() => {
    setModalState(ModalState.NONE);
    setError(null);
  }, []);

  const onSetName = useCallback(
    (newName: string | undefined) => {
      if (newName && newName !== data.name) {
        dispatch(
          updateCounter({
            ...data,
            name: newName,
          }),
        );
        setModalState(ModalState.NONE);
        setError(null);
      } else if (newName !== data.name) {
        setError('Invalid Name');
      } else {
        setModalState(ModalState.NONE);
      }
    },
    [data, dispatch],
  );
  const onEditTitle = useCallback(() => setModalState(ModalState.NAME), []);

  const onAccessibilityAction = useCallback(
    (event: AccessibilityActionEvent) => {
      switch (event.nativeEvent.actionName) {
        case 'increment':
          dispatch(
            updateCounter({
              ...data,
              tally: data.tally + 1,
            }),
          );
          break;
        case 'decrement':
          dispatch(
            updateCounter({
              ...data,
              tally: data.tally - 1,
            }),
          );
          break;
        case 'longpress':
        case 'longPress':
        case 'magicTap':
          onSetRequest();
          break;
        default:
          break;
      }
    },
    [data, dispatch, onSetRequest],
  );

  const move = useCallback(
    (isUp: boolean) => {
      dispatch(
        updateOrder({
          index,
          isUp,
        }),
      );
      LayoutAnimation.easeInEaseOut();
    },
    [dispatch, index],
  );

  const style = useStyle(CounterItemStyle);
  const theme = useTheme();
  return (
    <>
      <EditModal
        backButtonCallback={onBackPress}
        error={error}
        isVisible={
          currentModalState === ModalState.NAME ||
          currentModalState === ModalState.SCORE
        }
        onSave={(val: string) => {
          if (currentModalState === ModalState.SCORE) {
            setScore(Number(val));
          } else {
            onSetName(val);
          }
          setModalState(ModalState.NONE);
        }}
        player={data.name}
        type={currentModalState}
        value={
          currentModalState === ModalState.NAME ? data.name : `${data.tally}`
        }
      />
      <View style={style.backgroundContainer}>
        <TouchableOpacity
          disabled={isEditing}
          onPress={increment}
          style={style.background}
          onLongPress={onSetRequest}
          delayLongPress={300}
          accessible={!isEditing}
          onAccessibilityTap={onSetRequest}
          onAccessibilityAction={onAccessibilityAction}
          accessibilityActions={[
            { name: 'increment' },
            { name: 'decrement' },
            // iOS only
            { name: 'magicTap', label: 'Add or subtract an arbitrary number' },
            // Android only
            { name: 'longpress', label: 'Add or subtract an arbitrary number' },
          ]}
          accessibilityRole="adjustable"
          accessibilityLabel={[
            data.name,
            `current score: ${Math.abs(data.tally)}`,
            getPlaceA11yString(place),
          ]
            .filter((s) => !!s)
            .join(', ')}
        >
          <View style={style.leftSectionWrapper}>
            {isEditing && playerCount > 1 && (
              <>
                {(playerCount > 2 || index === 1) && (
                  <TouchableOpacity
                    accessibilityHint="Move up"
                    disabled={index === 0}
                    onPress={() => move(true)}
                    style={[style.orderButton, index === 0 && { opacity: 0 }]}
                  >
                    <SymbolView
                      name="chevron.up"
                      resizeMode="scaleAspectFit"
                      size={25}
                      style={{ margin: 5 }}
                      tintColor={theme.colors.accentBackground}
                      weight="semibold"
                      fallback={
                        <MaterialIcons
                          color={theme.colors.accentBackground}
                          size={35}
                          name="keyboard-arrow-up"
                        />
                      }
                    />
                  </TouchableOpacity>
                )}
                {(playerCount > 2 || index === 0) && (
                  <TouchableOpacity
                    accessibilityHint="Move down"
                    disabled={index === playerCount - 1}
                    onPress={() => move(false)}
                    style={[
                      style.orderButton,
                      index === playerCount - 1 && { opacity: 0 },
                    ]}
                  >
                    <SymbolView
                      name="chevron.down"
                      resizeMode="scaleAspectFit"
                      size={25}
                      style={{ margin: 5 }}
                      tintColor={theme.colors.accentBackground}
                      weight="semibold"
                      fallback={
                        <MaterialIcons
                          color={theme.colors.accentBackground}
                          size={35}
                          name="keyboard-arrow-down"
                        />
                      }
                    />
                  </TouchableOpacity>
                )}
                <View style={{ width: 8 }} />
              </>
            )}
            <TouchableOpacity
              accessible={isEditing}
              accessibilityHint="Tap to edit player name"
              disabled={!isEditing}
              onPress={onEditTitle}
            >
              <Text style={style.detail}>{data.name}</Text>
            </TouchableOpacity>
          </View>
          <View style={style.removeWrapper}>
            <Text style={style.tally} accessible={false}>
              {getPlaceString(place)}
              {data.tally > 1e5 ? data.tally.toPrecision(3) : data.tally}
            </Text>
            {isEditing && (
              <TouchableOpacity
                style={style.removeButton}
                onPress={onRemove}
                accessible
                accessibilityLabel="Delete"
                accessibilityHint="Tap to delete player"
              >
                <SymbolView
                  name="trash.fill"
                  resizeMode="scaleAspectFit"
                  size={35}
                  style={{ margin: 10 }}
                  tintColor={theme.colors.secondary}
                  fallback={
                    <MaterialIcons
                      name="close"
                      size={45}
                      color={theme.colors.secondary}
                    />
                  }
                />
              </TouchableOpacity>
            )}
          </View>
        </TouchableOpacity>
      </View>
    </>
  );
};

export default CounterItem;
