import { createSlice } from '@reduxjs/toolkit';

type SortState = Readonly<{
  highScoreWins: boolean;
}>;

const initialState: SortState = {
  highScoreWins: true,
};

const sortReducerSlice = createSlice({
  name: 'sort',
  initialState,
  reducers: {
    flipSortOrder: (state: SortState) => ({
      ...state,
      highScoreWins: !state.highScoreWins,
    }),
  },
});

export const { flipSortOrder } = sortReducerSlice.actions;
export default sortReducerSlice.reducer;
