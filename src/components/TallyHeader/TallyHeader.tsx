import React, { type JSX, useCallback } from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import { FontAwesome5, MaterialIcons } from '@expo/vector-icons';

import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { useDispatch } from 'react-redux';

import useStyle from 'Components/ThemeProvider/useStyle';
import useTheme from 'Components/ThemeProvider/useTheme';

import { flipSortOrder } from 'Redux/modules/sort';

import TallyHeaderStyles from './TallyHeader.style';
import { SymbolView } from 'expo-symbols';

type Props = {
  addCounterCallback?: () => void;
  highScoreWins: boolean;
  isEditing?: boolean;
  isEmpty?: boolean;
  onSetEditing: () => void;
};

function TallyHeader({
  addCounterCallback = () => {},
  highScoreWins,
  isEditing,
  isEmpty,
  onSetEditing,
}: Props): JSX.Element {
  const style = useStyle(TallyHeaderStyles);
  const theme = useTheme();

  const { top } = useSafeAreaInsets();

  const dispatch = useDispatch();
  const toggleSortOrder = useCallback(() => {
    dispatch(flipSortOrder());
  }, [dispatch]);

  const leftButton = isEmpty ? (
    <View />
  ) : (
    <TouchableOpacity
      style={style.buttonContainer}
      onPress={onSetEditing}
      accessibilityRole="imagebutton"
    >
      <SymbolView
        name={isEditing ? 'checkmark' : 'pencil'}
        resizeMode="scaleAspectFit"
        size={30}
        tintColor={theme.colors.primary}
        weight={isEditing ? undefined : 'heavy'}
        accessibilityLabel={isEditing ? 'Confirm counters' : 'Edit counters'}
        fallback={
          <MaterialIcons
            name={isEditing ? 'check' : 'edit'}
            color={theme.colors.primary}
            size={30}
            accessibilityLabel={
              isEditing ? 'Confirm counters' : 'Edit counters'
            }
          />
        }
      />
    </TouchableOpacity>
  );

  const rightButton = (() => {
    if (isEmpty) {
      return <View />;
    }
    return isEditing ? (
      <TouchableOpacity
        style={style.buttonContainer}
        onPress={toggleSortOrder}
        accessibilityRole="imagebutton"
      >
        <FontAwesome5
          name={highScoreWins ? 'sort-amount-down' : 'sort-amount-up-alt'}
          color={theme.colors.primary}
          size={30}
          accessibilityLabel="Toggle sort order"
        />
      </TouchableOpacity>
    ) : (
      <TouchableOpacity
        style={style.buttonContainer}
        onPress={addCounterCallback}
        accessibilityRole="imagebutton"
      >
        <SymbolView
          accessibilityLabel="Add counter"
          name="plus"
          resizeMode="scaleAspectFit"
          size={30}
          tintColor={theme.colors.primary}
          fallback={
            <MaterialIcons
              name="add"
              color={theme.colors.primary}
              size={30}
              accessibilityLabel="Add counter"
            />
          }
        />
      </TouchableOpacity>
    );
  })();

  return (
    <View style={style.shadowContainer} accessibilityRole="header">
      <View
        style={[
          style.container,
          {
            paddingTop: top,
          },
        ]}
      >
        {leftButton}
        <Text style={style.title} accessibilityRole="header">
          Score Tally
        </Text>
        {rightButton}
      </View>
    </View>
  );
}

export default TallyHeader;
