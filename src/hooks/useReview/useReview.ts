import { useDispatch, useSelector } from 'react-redux';

import { useCallback } from 'react';

import { Alert } from 'react-native';

import { isAvailableAsync, requestReview } from 'expo-store-review';

import { AppReduxState } from 'Redux/modules/reducer';
import { ask, reviewed } from 'Redux/modules/review';

/**
 * Used to track if you can ask for a store review, and allow you to trigger the action
 */
export default (): [boolean, () => Promise<void>] => {
  const dispatch = useDispatch();
  const { hasReviewed, lastAsked } = useSelector((s: AppReduxState) => ({
    hasReviewed: s.review.hasReviewed,
    lastAsked: new Date(s.review.lastAsked),
  }));

  // Check if the user was last asked 30 or more days ago
  const canAsk =
    Math.abs(new Date().getTime() - new Date(lastAsked).getTime()) >=
    2592000000;

  return [
    canAsk,
    useCallback(() => {
      if (hasReviewed || !canAsk) {
        return Promise.resolve();
      }

      return new Promise<void>((resolve, reject) => {
        isAvailableAsync()
          .then(() => {
            dispatch(ask());
            Alert.alert('Are you enjoying Score Tally?', undefined, [
              {
                text: 'No',
                onPress: () => {
                  Alert.alert('Thanks for your feedback');
                  resolve();
                },
              },
              {
                text: 'Yes!',
                onPress: () => {
                  requestReview().then(() => {
                    dispatch(reviewed());
                    resolve();
                  }).catch(reject);
                },
              },
            ]);
          })
          .catch(reject);
      });
    }, [canAsk, dispatch]),
  ];
};
