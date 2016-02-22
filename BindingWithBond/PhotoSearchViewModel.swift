//
//  xxx.swift
//  BindingWithBond
//
//  Created by matsuosh on 2016/02/19.
//  Copyright © 2016年 Razeware. All rights reserved.
//

import Foundation
import Bond

class PhotoSearchViewModel {

    let searchString = Observable<String?>("")
    let validSearchText = Observable<Bool>(false)
    let searchInProgress = Observable<Bool>(false)
    let errorMessages = EventProducer<String>()
    let searchMetadataViewModel = PhotoSearchMetadataViewModel()
    
    private let searchService: PhotoSearch = {
        let apiKey = NSBundle.mainBundle().objectForInfoDictionaryKey("apiKey") as! String
        return PhotoSearch(key: apiKey)
    }()

    let searchResults = ObservableArray<Photo>()

    init() {
        searchString
            .map { $0!.characters.count > 3 }
            .bindTo(validSearchText)
        searchString
            .filter { $0!.characters.count > 3 }
            .throttle(0.5, queue: Queue.Main)
            .observe {
                [unowned self] text in
                self.executeSearch(text!)
            }
        combineLatest(searchMetadataViewModel.dateFilter, searchMetadataViewModel.maxUploadDate, searchMetadataViewModel.minUploadDate, searchMetadataViewModel.creativeCommons)
            .throttle(0.5, queue: .Main)
            .observe { [unowned self] _ in
               self.executeSearch(self.searchString.value!)
            }
    }

    func executeSearch(text: String) {
        var query = PhotoQuery()
        query.text = searchString.value ?? ""
        query.creativeCommonsLicence = searchMetadataViewModel.creativeCommons.value
        query.dateFilter = searchMetadataViewModel.dateFilter.value
        query.minDate = searchMetadataViewModel.minUploadDate.value
        query.maxDate = searchMetadataViewModel.maxUploadDate.value
        searchInProgress.value = true
        searchService.findPhotos(query) { [unowned self] (result) -> () in
            self.searchInProgress.value = false
            switch result {
            case .Success(let photos):
                self.searchResults.removeAll()
                self.searchResults.insertContentsOf(photos, atIndex: 0)
            case .Error:
                self.errorMessages.next("There was an API request issue of some sort. Go ahead, hit me with that 1-star review!")
            }
        }
        print(text)
    }

}