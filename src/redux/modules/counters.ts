import 'react-native-get-random-values';
import { nanoid } from 'nanoid';

import { createSlice, PayloadAction } from '@reduxjs/toolkit';

import { Counter } from 'Statics/Types';

export type AppendCounterAction = Partial<Counter> | undefined;

export type RemoveCounterAction = Counter;

export type UpdateCounterAction = Counter;

export type UpdateOrderAction = {
  index: number;
  isUp: boolean;
};

type CounterState = Readonly<{
  counters: Counter[];
}>;

export const defaultCounter = {
  increment: 1,
  name: 'New Player',
  tally: 0,
};

const initialState: CounterState = {
  counters: [],
};

const counterReducerSlice = createSlice({
  name: 'Counter',
  initialState,
  reducers: {
    appendCounter: (
      state: CounterState,
      action: PayloadAction<AppendCounterAction>,
    ): CounterState => ({
      ...state,
      counters: [
        ...state.counters,
        {
          ...defaultCounter,
          ...(action.payload || {}),
          key: nanoid(),
        },
      ],
    }),
    removeCounter: (
      state: CounterState,
      action: PayloadAction<RemoveCounterAction>,
    ): CounterState => {
      const matchingCounterIndex = state.counters.findIndex(
        (counter) => counter.key === action.payload.key,
      );
      if (matchingCounterIndex >= 0) {
        return {
          ...state,
          counters: [
            ...state.counters.slice(0, matchingCounterIndex),
            ...state.counters.slice(matchingCounterIndex + 1),
          ],
        };
      }
      return state;
    },
    updateCounter: (
      state: CounterState,
      action: PayloadAction<UpdateCounterAction>,
    ): CounterState => {
      const matchingCounterIndex = state.counters.findIndex(
        (counter) => counter.key === action.payload.key,
      );
      if (matchingCounterIndex >= 0) {
        // replace
        return {
          ...state,
          counters: [
            ...state.counters.slice(0, matchingCounterIndex),
            action.payload,
            ...state.counters.slice(matchingCounterIndex + 1),
          ],
        };
      }
      // append
      return {
        ...state,
        counters: [...state.counters, action.payload],
      };
    },
    updateOrder: (
      state: CounterState,
      { payload: { index, isUp } }: PayloadAction<UpdateOrderAction>,
    ) => {
      if (isUp) {
        if (index === 0) {
          return state;
        }
        return {
          ...state,
          counters: [
            ...state.counters.slice(0, index - 1),
            state.counters[index],
            state.counters[index - 1],
            ...state.counters.slice(index + 1),
          ].filter((c) => !!c),
        };
      }
      if (index === state.counters.length - 1) {
        return state;
      }
      return {
        ...state,
        counters: [
          ...state.counters.slice(0, index),
          state.counters[index + 1],
          state.counters[index],
          ...state.counters.slice(index + 2),
        ].filter((c) => !!c),
      };
    },
  },
});
export const { appendCounter, removeCounter, updateCounter, updateOrder } =
  counterReducerSlice.actions;
export default counterReducerSlice.reducer;
