//
//  LocationService.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import Foundation
import MapKit
import CoreLocation

class LocationService: NSObject {
    
    // MARK: - Types
    
    /// Completion handler type for search results
    typealias SearchCompletionHandler = ([MKLocalSearchCompletion]) -> Void
    
    /// Completion handler type for location coordinates
    typealias CoordinateCompletionHandler = (CLLocation?) -> Void
    
    // MARK: - Properties
    
    /// The search completer that provides search suggestions
    private let searchCompleter = MKLocalSearchCompleter()
    
    /// Current search results
    private var searchResults = [MKLocalSearchCompletion]()
    
    /// Current completion handler for search
    private var searchCompletionHandler: SearchCompletionHandler?
    
    /// Search request operation queue to manage concurrent requests
    private let operationQueue = OperationQueue()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        // Configure the search completer
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        
        // Configure operation queue for search requests
        operationQueue.maxConcurrentOperationCount = 1 // Serial queue
    }
    
    // MARK: - Public Methods
    
    /// Search for locations matching the query
    /// - Parameters:
    ///   - query: The search query
    ///   - completion: The completion handler to call with the results
    func searchLocation(query: String, completion: @escaping SearchCompletionHandler) {
        // Reset search results for empty queries
        if query.isEmpty {
            completion([])
            return
        }
        
        // Save completion handler
        searchCompletionHandler = completion
        
        // Set query fragment to trigger search
        searchCompleter.queryFragment = query
    }
    
    /// Get coordinates for a search result
    /// - Parameters:
    ///   - searchResult: The search result to get coordinates for
    ///   - completion: The completion handler to call with the location
    func getCoordinates(for searchResult: MKLocalSearchCompletion, completion: @escaping CoordinateCompletionHandler) {
        // Create a search request using the full title and subtitle
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "\(searchResult.title), \(searchResult.subtitle)"
        
        // Start the search
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] (response, error) in
            guard self != nil else { return }
            
            // Check for errors
            if let error = error {
                print("Location search error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // Extract the location from the first result
            guard let response = response,
                  let firstMapItem = response.mapItems.first,
                  let location = firstMapItem.placemark.location else {
                completion(nil)
                return
            }
            
            // Return the location
            completion(location)
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationService: MKLocalSearchCompleterDelegate {
    // Called when search results are updated
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Save the results
        searchResults = completer.results
        
        // Call the completion handler with the results
        searchCompletionHandler?(searchResults)
    }
    
    // Called when search fails
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search completer error: \(error.localizedDescription)")
        searchCompletionHandler?([])
    }
}
