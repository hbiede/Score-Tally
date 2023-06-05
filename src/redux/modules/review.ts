import { createSlice } from '@reduxjs/toolkit';

type ReviewState = {
  hasReviewed: boolean;
  lastAsked: string;
};

const initialState: ReviewState = {
  hasReviewed: false,
  lastAsked: '1970-01-01',
};

const reviewReducerSlice = createSlice({
  name: 'reviews',
  initialState,
  reducers: {
    ask: (state) => ({
      ...state,
      lastAsked: new Date().toISOString(),
    }),
    reviewed: (state) => ({
      ...state,
      hasReviewed: true,
    })
  },
});

export const { ask, reviewed } = reviewReducerSlice.actions;
export default reviewReducerSlice.reducer;
