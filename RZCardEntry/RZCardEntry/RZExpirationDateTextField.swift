//
//  RZExpirationDateTextField.swift
//  RZCardEntry
//
//  Created by Jason Clark on 9/21/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import UIKit

final class RZExpirationDateTextField: RZFormattableTextField {

    override init(frame: CGRect) {
        super.init(frame: frame)
        placeholder = "MM/YY"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc override func textFieldDidChange(_ textField: UITextField) {
        reformatExpirationDate()
        super.textFieldDidChange(textField)
    }

    override var formattingCharacterSet: CharacterSet {
        return CharacterSet(charactersIn: "/")
    }

    override var inputCharacterSet: CharacterSet {
        return CharacterSet.decimalDigits
    }

    override var valid: Bool {
        return unformattedText.characters.count == maxLength
    }

    override var deletingShouldRemoveTrailingCharacters: Bool {
        return true
    }

    var maxLength: Int {
        return 4
    }

    func expirationDateIsPossible(_ expDate: String) -> Bool {
        guard expDate.characters.count > 0 else {
            return true
        }
        let monthsRange = "01"..."12"
        guard monthsRange.prefixMatches(expDate) else {
            return false
        }
        //months valid, check year
        guard expDate.characters.count > 2 else {
            return true
        }
        let suffixString = expDate.substring(from: expDate.characters.index(expDate.startIndex, offsetBy: 2))
        guard validYearRanges.contains(where: { $0.prefixMatches(suffixString) }), let suffixInt = Int(suffixString) else {
            return false
        }
        //year valid, check month year combo
        guard String(currentYearSuffix).prefixMatches(suffixString) else {
            return true
        }
        guard !(suffixString.characters.count == 1 && String(currentYearSuffix + 1).prefixMatches(suffixString)) else {
            //year is incomplete and can potentially be a future year
            return true
        }
        return currentMonth >= suffixInt
    }

    static let validFutureExpYearRange = 30
    var validYearRanges: [ClosedRange<String>] {
        let shortYear = currentYearSuffix
        var endYear = shortYear + RZExpirationDateTextField.validFutureExpYearRange
        if endYear < 100 {
            return [String(shortYear)...String(endYear)]
        }
        else {
            endYear = endYear % 100
            return [String(shortYear)..."99",
                    "00"...String(endYear)]
        }
    }

    var currentYearSuffix: Int {
        let fullYear = (Calendar.current as NSCalendar).component(.year, from: Date())
        return fullYear % 100
    }

    var currentMonth: Int {
        return (Calendar.current as NSCalendar).component(.month, from: Date())
    }

    override func willChangeCharactersIn(range: NSRange, replacementString string: String) {
        super.willChangeCharactersIn(range: range, replacementString: string)

        //If user manually enters formatting character after a 1, pad with a leading 0
        guard let text = text else { return }

        if range.location == 1 && string == "/" {
            self.text?.insert("0", at: text.startIndex)
            if let previousSelection = previousSelection, let startPosition = position(from: previousSelection.start, offset: 1), let endPosition = position(from: previousSelection.end, offset: 1) {
                selectedTextRange = textRange(from: startPosition, to: endPosition)
            }
        }
    }
}

private extension RZExpirationDateTextField {

    func reformatExpirationDate() {
        guard let text = text else { return }

        var cursorPos = cursorOffset

        let formatlessText = removeFormatting(text, cursorPosition: &cursorPos)

        guard formatlessText.characters.count <= maxLength else {
            rejectInput()
            return
        }
        let formattedText = formatString(formatlessText, cursorPosition: &cursorPos)
        self.text = formattedText
        if let targetPosition = position(from: beginningOfDocument, offset: cursorPos) {
            selectedTextRange = textRange(from: targetPosition, to: targetPosition)
        }

        guard expirationDateIsPossible(unformattedText) else {
            rejectInput()
            return
        }
    }

    func formatString(_ text: String, cursorPosition: inout Int) -> String {
        let cursorPositionInFormattlessText = cursorPosition
        var formattedString = String()

        for (index, character) in text.characters.enumerated() {
            if index == 0 && text.characters.count == 1 && "2"..."9" ~= character {
                formattedString.append("0")
                formattedString.append(character)
                formattedString.append("/")
                if index < cursorPositionInFormattlessText {
                    cursorPosition += 2
                }
            }
            else if index == 1 && text.characters.count == 2 && text.characters.first == "1"
                && !("1"..."2" ~= character) && validYearRanges.contains(where: { $0.prefixMatches(String(character)) }) {
                //digit after leading 1 is not a valid month but is the start of a valid year.
                formattedString.insert("0", at: formattedString.startIndex)
                formattedString.append("/")
                formattedString.append(character)
                if index < cursorPositionInFormattlessText {
                    cursorPosition += 2
                }
            }
            else {
                formattedString.append(character)
                if index == 1 {
                    formattedString.append("/")
                    if index < cursorPositionInFormattlessText {
                        cursorPosition += 1
                    }
                }
            }
        }

        return formattedString
    }
    
}
