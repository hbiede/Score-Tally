import React, {
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

const CounterScreen = (): JSX.Element => {
  const [isEditing, setIsEditing] = useState(false);
  const onSetEditing = useCallback(() => setIsEditing(!isEditing), [isEditing]);

  const { counters, highScoreWins } = useSelector((state: AppReduxState) => ({
    counters: state.counters.counters,
    highScoreWins: state.sort.highScoreWins,
  }));

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
  const addCounterCallback = useCallback(() => {
    Alert.prompt('New Player', 'Enter a name for the new player', [
      {
        text: 'Cancel',
        style: 'cancel',
      },
      {
        text: 'OK',
        onPress: (newName: string | undefined) => {
          if (newName) {
            dispatch(appendCounter({ name: newName }));
            setHasAdded(true);
          } else {
            Alert.alert('Invalid Name', 'You must enter a valid name');
          }
        },
      },
    ]);
  }, [dispatch]);

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
      {counters.length === 0 ? (
        <View style={style.emptyContainer}>
          <TouchableOpacity
            onPress={addCounterCallback}
            style={style.addButton}
            accessibilityLabel="Add a counter"
          >
            <MaterialIcons name="add" color="#FFFFFF" size={30} />
          </TouchableOpacity>
        </View>
      ) : (
        <FlatList
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
          ListHeaderComponent={<View style={{ height: 10 }} />}
          initialNumToRender={6}
          keyboardShouldPersistTaps="handled"
          ref={listRef}
        />
      )}
    </View>
  );
};

export default CounterScreen;
