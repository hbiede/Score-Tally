import React, { useCallback } from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import { FontAwesome5, MaterialIcons } from '@expo/vector-icons';

import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { useDispatch } from 'react-redux';

import useStyle from 'Components/ThemeProvider/useStyle';
import useTheme from 'Components/ThemeProvider/useTheme';

import { flipSortOrder } from 'Redux/modules/sort';

import TallyHeaderStyles from './TallyHeader.style';

type Props = {
  addCounterCallback?: () => void;
  highScoreWins: boolean;
  isEditing?: boolean;
  isEmpty?: boolean;
  onSetEditing: () => void;
};

const TallyHeader = ({
  addCounterCallback = () => {},
  highScoreWins,
  isEditing,
  isEmpty,
  onSetEditing,
}: Props): JSX.Element => {
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
      <MaterialIcons
        name={isEditing ? 'check' : 'edit'}
        color={theme.colors.primary}
        size={30}
        accessibilityLabel={isEditing ? 'Confirm counters' : 'Edit counters'}
      />
    </TouchableOpacity>
  );

  const rightButton = isEmpty ? (
    <View />
  ) : (
    <>
      {isEditing ? (
        <TouchableOpacity
          style={style.buttonContainer}
          onPress={toggleSortOrder}
          accessibilityRole="imagebutton"
        >
          <FontAwesome5
            name={highScoreWins ? 'sort-amount-down' : 'sort-amount-up-alt'}
            color={theme.colors.primary}
            size={28}
            accessibilityLabel="Toggle sort order"
          />
        </TouchableOpacity>
      ) : (
        <TouchableOpacity
          style={style.buttonContainer}
          onPress={addCounterCallback}
          accessibilityRole="imagebutton"
        >
          <MaterialIcons
            name="add"
            color={theme.colors.primary}
            size={35}
            accessibilityLabel="Add counter"
          />
        </TouchableOpacity>
      )}
    </>
  );

  return (
    <>
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
          <Text style={style.title} accessible={false}>
            Score Tally
          </Text>
          {rightButton}
        </View>
      </View>
    </>
  );
};

export default TallyHeader;
