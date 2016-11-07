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
        inputCharacterSet = .decimalDigits
        formattingCharacterSet = CharacterSet(charactersIn: "/")
        deletingShouldRemoveTrailingCharacters = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc override func textFieldDidChange(_ textField: UITextField) {
        reformatExpirationDate()
        super.textFieldDidChange(textField)
    }

    override var valid: Bool {
        let unformatted = unformattedText
        return unformatted.characters.count == maxLength && expirationDateIsPossible(unformatted)
    }

    var maxLength: Int {
        return 4
    }

    var monthString: String? {
        guard valid else { return nil }
        return unformattedText.substring(fromNSRange: NSMakeRange(0, 2))
    }

    var yearString: String? {
        guard valid else { return nil }
        return unformattedText.substring(fromNSRange: NSMakeRange(2, 2))
    }

    override func willChangeCharactersIn(range: NSRange, replacementString string: String) {
        super.willChangeCharactersIn(range: range, replacementString: string)

        //If user manually enters formatting character after a 1, pad with a leading 0
        guard let text = text else { return }

        if range.location == 1 && string == "/" {
            self.text?.insert("0", at: text.startIndex)
            selectedTextRange = offsetTextRange(previousSelection, by: 1)
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
        selectedTextRange = textRange(cursorOffset: cursorPos)

        guard expirationDateIsPossible(unformattedText) else {
            rejectInput()
            return
        }
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
        let separatorIndex = expDate.characters.index(expDate.startIndex, offsetBy: 2)
        let monthString = expDate.substring(to: separatorIndex)
        let yearSuffixString = expDate.substring(from: separatorIndex)
        guard validYearRanges.contains(where: { $0.prefixMatches(yearSuffixString) }) else {
            return false
        }
        //year valid, check month year combo
        guard String(currentYearSuffix).prefixMatches(yearSuffixString) else {
            //If a future year, we don't have to check month
            return true
        }
        guard !(yearSuffixString.characters.count == 1 && String(currentYearSuffix + 1).prefixMatches(yearSuffixString)) else {
            //year is incomplete and can potentially be a future year
            return true
        }

        return String(currentMonth) >= monthString
    }

    var currentYearSuffix: Int {
        let fullYear = (Calendar.current as NSCalendar).component(.year, from: Date())
        return fullYear % 100
    }

    var currentMonth: Int {
        return (Calendar.current as NSCalendar).component(.month, from: Date())
    }

    func formatString(_ text: String, cursorPosition: inout Int) -> String {
        let cursorPositionInFormattlessText = cursorPosition
        var formattedString = String()

        for (index, character) in text.characters.enumerated() {
            if index == 0 && text.characters.count == 1 && "2"..."9" ~= character {
                formattedString.append("0\(character)/")
                if index < cursorPositionInFormattlessText {
                    cursorPosition += 2
                }
            }
            else if index == 1 && text.characters.count == 2 && text.characters.first == "1"
                && !("1"..."2" ~= character) && validYearRanges.contains(where: { $0.prefixMatches(String(character)) }) {
                //digit after leading 1 is not a valid month but is the start of a valid year.
                formattedString.insert("0", at: formattedString.startIndex)
                formattedString.append("/\(character)")
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
