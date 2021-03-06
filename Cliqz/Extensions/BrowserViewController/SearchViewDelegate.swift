//
//  SearchDelegate.swift
//  Client
//
//  Created by Sahakyan on 3/8/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import Foundation
import Storage

//Cliqz: Replace Search Controller
extension BrowserViewController: SearchViewDelegate {
	func didSelectURL(_ url: URL, searchQuery: String?) {
        guard let tab = tabManager.selectedTab else { return }
        finishEditingAndSubmit(url, visitType: VisitType.typed, forTab: tab)
	}
	
	func autoCompeleteQuery(_ autoCompleteText: String) {
		urlBar.setAutocompleteSuggestion(autoCompleteText)
	}
	
	func dismissKeyboard() {
		urlBar.hideKeyboard()
	}

    func closeSearchOnboarding() {
        let query = cliqzSearchController?.searchQuery
        hideSearchController()
        showSearchController()
        if let query = query {
            updateSearchQuery(query: query)
        }
    }

    func makeLumenDefaultSearch() {
        let lumenSearchEngine = self.profile.searchEngines.orderedEngines.filter { $0.shortName == LumenSearchEngineDisplayName }.first
        if let engine = lumenSearchEngine {
            self.profile.searchEngines.defaultEngine = engine
            self.urlBar.updatePlaceHolders()
        }
    }
}
