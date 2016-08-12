//
//  SagaMiddleware.swift
//  ReKatana
//
//  Created by Mauro Bolis on 09/08/16.
//  Copyright © 2016 BendingSpoons. All rights reserved.
//

import Foundation

// TODO: remove this as soon as the typealias bug has been fixed
public typealias StoreMiddleware2<RootReducer: Reducer> = (store: Store<RootReducer>) -> (next: StoreDispatch) -> (action: Action) -> Void

private func handleAction<RootReducer: Reducer>(
    _ action: Action,
    usingSagas sagas: [String: [AnySaga]],
    store: Store<RootReducer>,
    providersContainer: SagaProvidersContainer<RootReducer>
  ) -> Void {
  
  let actionName = action.actionName
  let actionSagas = sagas[actionName]
  
  
  actionSagas?.forEach { saga in
    saga(action: action, getState: store.getState, dispatch: store.dispatch, providers: providersContainer)
  }
}


private func createMiddleware<RootReducer: Reducer>(
    modules: [SagaModule],
    providersContainer: SagaProvidersContainer<RootReducer>.Type
  ) -> StoreMiddleware2<RootReducer> {
  // put saga in a structure where is easy to retrieve
  // all the sagas that are associated with an action
  // basically the key is the action name and the values are an array of 
  // sagas related to the action
  var sagas: [String: [AnySaga]] = [:]
  
  modules.forEach { module in
    module.sagas.forEach { (actionName, saga) in
      if sagas[actionName] == nil {
        sagas[actionName] = [saga]
      
      } else {
        sagas[actionName]?.append(saga)
      }
    }
  }
  
  return { store in
    
    let providers = providersContainer.init(store: store)
    
    return { next in
      return { action in
        handleAction(action, usingSagas: sagas, store: store, providersContainer: providers)
        next(action)
      }
    }
  }
}

enum SagaMiddleware <RootReducer: Reducer> {
  static func withSagaModules(
      _ sagaModules: [SagaModule],
      providersContainer: SagaProvidersContainer<RootReducer>.Type
    ) -> StoreMiddleware2<RootReducer> {

    return createMiddleware(modules: sagaModules, providersContainer: providersContainer)
  }
}
