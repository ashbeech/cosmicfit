//
//  TermsOfUseViewController.swift
//  Cosmic Fit
//

import UIKit

final class TermsOfUseViewController: LegalDocumentViewController {
    init() {
        super.init(configuration: TermsOfUseContent.configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
