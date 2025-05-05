//
//  UIPickerView+Extensions.swift
//  Cosmic Fit
//
//  Created by Ashley Davison on 04/05/2025.
//

import UIKit

extension UIPickerView {
    /// Get the selected value from an array of data based on the selected row
    /// - Parameter data: Array of data
    /// - Returns: Selected value or nil if index is out of bounds
    func selectedValue<T>(from data: [T]) -> T? {
        let selectedRow = self.selectedRow(inComponent: 0)
        guard selectedRow >= 0, selectedRow < data.count else {
            return nil
        }
        return data[selectedRow]
    }
    
    /// Select a row that corresponds to the specified value in the data array
    /// - Parameters:
    ///   - value: The value to select
    ///   - data: Array of data
    ///   - animated: Whether to animate the selection
    /// - Returns: Whether the selection was successful
    @discardableResult
    func selectValue<T: Equatable>(_ value: T, in data: [T], animated: Bool = false) -> Bool {
        guard let index = data.firstIndex(of: value) else {
            return false
        }
        
        self.selectRow(index, inComponent: 0, animated: animated)
        return true
    }
    
    /// Configure the picker with a default selection from an array
    /// - Parameters:
    ///   - defaultValue: The default value to select
    ///   - data: Array of data
    ///   - animated: Whether to animate the selection
    /// - Returns: The selected value
    @discardableResult
    func configureWithDefault<T: Equatable>(_ defaultValue: T, in data: [T], animated: Bool = false) -> T {
        if selectValue(defaultValue, in: data, animated: animated) {
            return defaultValue
        } else if let firstValue = data.first {
            // If the default value isn't in the data, select the first value
            selectRow(0, inComponent: 0, animated: animated)
            return firstValue
        } else {
            // Empty data array
            return defaultValue
        }
    }
}
