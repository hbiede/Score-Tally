import React, {
  type JSX,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import {
  Alert,
  FlatList,
  InteractionManager,
  LayoutAnimation,
  Platform,
  TouchableOpacity,
  useColorScheme,
  View,
} from 'react-native';

import { useDispatch, useSelector } from 'react-redux';

import { MaterialIcons } from '@expo/vector-icons';

import { StatusBar } from 'expo-status-bar';

import CounterScreenStyle from 'Screens/CounterScreen/CounterScreen.style';

import useStyle from 'Components/ThemeProvider/useStyle';
import { CounterItem } from 'Components/CounterItem';
import { TallyHeader } from 'Components/TallyHeader';

import { AppReduxState } from 'Redux/modules/reducer';
import { appendCounter } from 'Redux/modules/counters';
import { Counter } from 'Statics/Types';
import { SymbolView } from 'expo-symbols';
import useTheme from 'Components/ThemeProvider/useTheme';

const CounterScreen = (): JSX.Element => {
  const [isEditing, setIsEditing] = useState(false);
  const onSetEditing = useCallback(() => {
    setIsEditing(!isEditing);
    LayoutAnimation.easeInEaseOut();
  }, [isEditing]);

  const { counters, highScoreWins } = useSelector(
    (state: AppReduxState) => ({
      counters: state.counters.counters,
      highScoreWins: state.sort.highScoreWins,
    }),
    (prev, next) =>
      prev.highScoreWins === next.highScoreWins &&
      prev.counters.length === next.counters.length &&
      prev.counters.every(
        (c, i) =>
          c.key === next.counters[i].key &&
          c.name === next.counters[i].name &&
          c.tally === next.counters[i].tally,
      ),
  );

  const listRef = useRef<FlatList<Counter>>(null);
  const [hasAdded, setHasAdded] = useState(false);
  useEffect(() => {
    if (hasAdded) {
      setHasAdded(false);
      setTimeout(() => {
        InteractionManager.runAfterInteractions(() => {
          listRef.current?.scrollToEnd();
        });
      }, 20);
    }
  }, [counters.length, hasAdded]);

  useEffect(() => {
    if (counters.length === 0 && isEditing) {
      setIsEditing(false);
    }
  }, [isEditing, counters]);

  const dispatch = useDispatch();
  const addToList = useCallback(
    (name: string) => {
      dispatch(appendCounter({ name }));
      setHasAdded(true);
      LayoutAnimation.easeInEaseOut();
    },
    [dispatch],
  );
  const addCounterCallback = useCallback(() => {
    if (Platform.OS === 'ios') {
      Alert.prompt('New Player', 'Enter a name for the new player', [
        {
          text: 'Cancel',
          style: 'cancel',
        },
        {
          text: 'OK',
          onPress: (newName: string | undefined) => {
            if (newName) {
              addToList(newName);
            } else {
              Alert.alert('Invalid Name', 'You must enter a valid name');
            }
          },
        },
      ]);
    } else {
      addToList('New Player');
    }
  }, [addToList]);

  const ranking = useMemo(() => {
    const sortedOrder = counters
      .slice()
      .sort(
        ({ tally: a }, { tally: b }) =>
          (a < b ? 1 : -1) * (highScoreWins ? 1 : -1),
      );

    return sortedOrder.reduce(
      (acc, { key, tally }, i, arr): Record<string, number> => ({
        ...acc,
        [key]:
          i > 0 && tally === arr[i - 1].tally ? acc[arr[i - 1].key] : i + 1,
      }),
      {} as Record<string, number>,
    );
  }, [counters, highScoreWins]);

  const style = useStyle(CounterScreenStyle);
  const theme = useTheme();
  return (
    <View style={style.safeAreaContainer}>
      <StatusBar style={useColorScheme() === 'light' ? 'dark' : 'light'} />
      <TallyHeader
        addCounterCallback={
          counters.length === 0 ? undefined : addCounterCallback
        }
        highScoreWins={highScoreWins}
        isEditing={isEditing}
        isEmpty={counters.length === 0}
        onSetEditing={onSetEditing}
      />
      <View style={style.wrapper}>
        {counters.length === 0 ? (
          <TouchableOpacity
            onPress={addCounterCallback}
            style={style.addButton}
            accessibilityLabel="Add a counter"
          >
            <SymbolView
              name="plus"
              resizeMode="scaleAspectFit"
              size={40}
              tintColor={theme.colors.primaryAccent}
              weight="medium"
              fallback={
                <MaterialIcons
                  name="add"
                  color={theme.colors.primaryAccent}
                  size={40}
                />
              }
            />
          </TouchableOpacity>
        ) : (
          <FlatList
            numColumns={Platform.OS === 'ios' && Platform.isPad ? 2 : 1}
            contentContainerStyle={style.container}
            data={counters}
            keyExtractor={(counter) => counter.key}
            scrollEnabled
            renderItem={({ item, index }) => (
              <CounterItem
                data={item}
                index={index}
                isEditing={isEditing}
                place={ranking[item.key]}
              />
            )}
            initialNumToRender={6}
            keyboardShouldPersistTaps="handled"
            ref={listRef}
          />
        )}
      </View>
    </View>
  );
};

export default CounterScreen;
