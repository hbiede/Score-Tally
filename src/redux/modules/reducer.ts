import { combineReducers, Store, Reducer, AnyAction } from 'redux';
import {
  persistStore,
  persistReducer,
  Persistor,
  Transform,
  PersistState,
  FLUSH,
  REHYDRATE,
  PAUSE,
  PERSIST,
  PURGE,
  REGISTER,
} from 'redux-persist';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { configureStore } from '@reduxjs/toolkit';

import counters from 'Redux/modules/counters';
import sort from 'Redux/modules/sort';

type PersistPartial = {
  _persist: PersistState;
};

type StoreAndPersistor<S> = {
  store: Store<S>;
  persistor: Persistor;
};

const reducers = {
  counters,
  sort,
};

const mainReducer = combineReducers(reducers);

export type AppReduxState = ReturnType<typeof mainReducer>;

const createPersistedReducer = <S>(
  reducer: Reducer<S>,
  appBlacklist: string[] = [],
  transforms: Transform<any, any>[] = [], // eslint-disable-line @typescript-eslint/no-explicit-any
): StoreAndPersistor<S & PersistPartial> => {
  const persistConfig = {
    key: 'root',
    storage: AsyncStorage,
    blacklist: ([] as string[]).concat(appBlacklist),
    transforms,
    timeout: __DEV__ ? 10000 : 5000,
  };

  const persistedReducer = persistReducer<S, AnyAction>(persistConfig, reducer);

  const store = configureStore<S & PersistPartial, AnyAction>({
    reducer: persistedReducer,
    // @ts-expect-error - Return is not as the type expects
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware({
        serializableCheck: {
          ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
        },
      }),
    devTools: __DEV__,
  });
  const persistor = persistStore(store);
  return { store, persistor };
};

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
export default createPersistedReducer<AppReduxState>(mainReducer);
