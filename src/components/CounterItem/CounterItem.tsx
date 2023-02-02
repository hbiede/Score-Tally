import React, { useCallback, useState } from 'react';
import {
  AccessibilityActionEvent,
  Text,
  TouchableHighlight,
  TouchableOpacity,
  View,
} from 'react-native';
import { impactAsync, ImpactFeedbackStyle } from 'expo-haptics';

import { MaterialIcons } from '@expo/vector-icons';

import { useDispatch } from 'react-redux';

import CounterItemStyle from 'Components/CounterItem/CounterItem.style';
import useStyle from 'Components/ThemeProvider/useStyle';
import { Counter } from 'Statics/Types';
import { removeCounter, updateCounter } from 'Redux/modules/counters';
import useTheme from 'Components/ThemeProvider/useTheme';
import EditModal, {
  ModalState,
} from 'Components/CounterItem/EditModal/EditModal';

type Props = {
  data: Counter;
  isEditing?: boolean;
};

const CounterItem = ({ data, isEditing }: Props): JSX.Element => {
  const dispatch = useDispatch();
  const [currentModalState, setModalState] = useState<
    (typeof ModalState)[keyof typeof ModalState]
  >(ModalState.NONE);
  const [error, setError] = useState<string | null>(null);

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

  const onRemove = useCallback(
    () => dispatch(removeCounter(data)),
    [data, dispatch],
  );

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
        setError('Invalid Title');
      } else {
        setModalState(ModalState.NONE);
      }
    },
    [data, dispatch],
  );
  const onEditTitle = useCallback(() => setModalState(ModalState.NAME), []);

  const onAccessibilityAction = useCallback(
    (event: AccessibilityActionEvent) => {
      // eslint-disable-next-line default-case
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
      }
    },
    [data, dispatch, onSetRequest],
  );

  const style = useStyle(CounterItemStyle);
  const theme = useTheme();

  if (isEditing) {
    return (
      <>
        <EditModal
          backButtonCallback={onBackPress}
          error={error}
          isVisible={currentModalState === ModalState.NAME}
          onSave={onSetName}
          type={currentModalState}
          value={data.name}
        />
        <View style={style.background} accessible={false}>
          <TouchableOpacity
            onPress={onEditTitle}
            hitSlop={{
              top: 20,
              left: 20,
              bottom: 20,
              right: 20,
            }}
            accessibilityHint="Tap to edit player name"
          >
            <Text style={style.detail}>{data.name}</Text>
          </TouchableOpacity>
          <View style={style.removeWrapper}>
            <Text style={style.tally} accessible={false}>
              {data.tally > 1e5 ? data.tally.toPrecision(3) : data.tally}
            </Text>
            <TouchableOpacity
              style={style.removeButton}
              onPress={onRemove}
              accessible
              accessibilityLabel="Delete"
              accessibilityHint="Tap to delete player"
            >
              <MaterialIcons
                name="close"
                size={45}
                color={theme.colors.secondary}
              />
            </TouchableOpacity>
          </View>
        </View>
      </>
    );
  }

  return (
    <>
      <EditModal
        backButtonCallback={onBackPress}
        error={error}
        isVisible={currentModalState === ModalState.SCORE}
        onSave={(string: string) => {
          setScore(Number(string));
          setModalState(ModalState.NONE);
        }}
        type={currentModalState}
        value={`${data.tally}`}
      />
      <TouchableHighlight
        onPress={increment}
        style={style.background}
        onLongPress={onSetRequest}
        delayLongPress={300}
        accessible
        onAccessibilityTap={increment}
        onAccessibilityAction={onAccessibilityAction}
        accessibilityActions={[
          { name: 'increment' },
          { name: 'decrement' },
          { name: 'longPress' },
          { name: 'longpress' },
          { name: 'magicTap' },
        ]}
        accessibilityRole="adjustable"
        accessibilityLabel={`${data.name}. current count: ${Math.abs(
          data.tally,
        )}`}
      >
        <>
          <Text style={style.detail}>{data.name}</Text>
          <Text
            style={style.tally}
            accessibilityLabel={`current count: ${data.tally}`}
          >
            {data.tally > 1e5 ? data.tally.toPrecision(3) : data.tally}
          </Text>
        </>
      </TouchableHighlight>
    </>
  );
};

export default CounterItem;
