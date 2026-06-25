//
//  PrivacyPolicyViewController.swift
//  Cosmic Fit
//

import UIKit

final class PrivacyPolicyViewController: LegalDocumentViewController {
    init() {
        super.init(configuration: PrivacyPolicyContent.configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
