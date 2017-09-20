/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

protocol OverlayViewDelegate: class {
    func overlayViewDidTouchEmptyArea(_ overlayView: OverlayView)
    func overlayViewDidPressSettings(_ overlayView: OverlayView)
    func overlayView(_ overlayView: OverlayView, didSearchForQuery query: String)
    func overlayView(_ overlayView: OverlayView, didSubmitText text: String)
}

class OverlayView: UIView {
    weak var delegate: OverlayViewDelegate?
    private let searchButton = InsetButton()
    private let searchBorder = UIView()
    private var presented = false
    private var searchQuery = ""
    private let copyButton = UIButton()
    private let copyBorder = UIView()

    init() {
        super.init(frame: CGRect.zero)
        KeyboardHelper.defaultHelper.addDelegate(delegate: self)
        searchButton.isHidden = true
        searchButton.alpha = 0
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .normal)
        searchButton.setImage(#imageLiteral(resourceName: "icon_searchfor"), for: .highlighted)
        searchButton.titleLabel?.font = UIConstants.fonts.searchButton
        setUpOverlayButton(button: searchButton)
        searchButton.addTarget(self, action: #selector(didPressSearch), for: .touchUpInside)
        addSubview(searchButton)

        searchBorder.isHidden = true
        searchBorder.alpha = 0
        searchBorder.backgroundColor = UIConstants.colors.settingsButtonBorder
        addSubview(searchBorder)
        searchButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
        }
        searchBorder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(searchButton.snp.bottom)
            make.height.equalTo(1)
        }
        
        copyButton.titleLabel?.font = UIConstants.fonts.copyButton
        let padding = UIConstants.layout.searchButtonInset
        copyButton.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        copyButton.titleLabel?.lineBreakMode = .byTruncatingTail
        if UIView.userInterfaceLayoutDirection(for: copyButton.semanticContentAttribute) == .rightToLeft {
            copyButton.contentHorizontalAlignment = .right
        } else {
            copyButton.contentHorizontalAlignment = .left
        }
        copyButton.addTarget(self, action: #selector(didPressCopy), for: .touchUpInside)
        addSubview(copyButton)
        
        copyBorder.backgroundColor = UIConstants.colors.copyButtonBorder
        addSubview(copyBorder)
        
        copyButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
            make.height.equalTo(56)
        }
        copyBorder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(copyButton.snp.bottom)
            make.height.equalTo(1)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setUpOverlayButton (button: InsetButton) {
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        if UIView.userInterfaceLayoutDirection(for: button.semanticContentAttribute) == .rightToLeft {
            button.contentHorizontalAlignment = .right
        } else {
            button.contentHorizontalAlignment = .left
        }
        
        let padding = UIConstants.layout.searchButtonInset
        button.imageEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        if UIView.userInterfaceLayoutDirection(for: button.semanticContentAttribute) == .rightToLeft {
            button.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding * 2)
        } else {
            button.titleEdgeInsets = UIEdgeInsets(top: padding, left: padding * 2, bottom: padding, right: padding)
        }
    }
    func setAttributedButtonTitle(phrase: String, button: InsetButton) {
        // Use [ and ] to help find the position of the query, then delete them.
        let copyTitle = NSMutableString(string: String(format: UIConstants.strings.searchButton, "[\(phrase)]"))
        let startIndex = copyTitle.range(of: "[")
        let endIndex = copyTitle.range(of: "]")
        copyTitle.deleteCharacters(in: endIndex)
        copyTitle.deleteCharacters(in: startIndex)
        
        let attributedString = NSMutableAttributedString(string: copyTitle as String)
        let queryRange = NSMakeRange(startIndex.location, (phrase as NSString).length)
        let fullRange = NSMakeRange(0, copyTitle.length)
        attributedString.addAttributes([NSAttributedStringKey.font: UIConstants.fonts.copyButtonQuery], range: queryRange)
        attributedString.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], range: fullRange)
        
        button.setAttributedTitle(attributedString, for: .normal)
    }
    func setSearchQuery(query: String, animated: Bool) {
        searchQuery = query
        let query = query.trimmingCharacters(in: .whitespaces)

        var showCopyButton = false

        UIPasteboard.general.urlAsync() { handoffUrl in
            DispatchQueue.main.async {
                if let url = handoffUrl, url.isWebPage() {
                    self.copyButton.setAttributedTitle(NSAttributedString(string: String(format: UIConstants.strings.linkYouCopied, url.absoluteString), attributes: [NSAttributedStringKey.foregroundColor: UIColor.white]), for: .normal)
                    showCopyButton = url.isWebPage()
                }

                // Show or hide the search button depending on whether there's entered text.
                if self.searchButton.isHidden != query.isEmpty {
                    let duration = animated ? UIConstants.layout.searchButtonAnimationDuration : 0
                    self.searchButton.animateHidden(query.isEmpty, duration: duration)
                    self.searchBorder.animateHidden(query.isEmpty, duration: duration)
                }
                self.setAttributedButtonTitle(phrase: query, button: self.searchButton)
                self.updateCopyConstraint(showCopyButton: showCopyButton)
            }
        }
    }

    fileprivate func updateCopyConstraint(showCopyButton: Bool) {
        if showCopyButton {
            copyButton.isHidden = false
            copyBorder.isHidden = false
            if searchButton.isHidden || searchQuery.isEmpty {
                copyButton.snp.remakeConstraints { make in
                    make.top.leading.trailing.equalTo(self)
                    make.height.equalTo(56)
                }
            } else {
                copyButton.snp.remakeConstraints { make in
                    make.leading.trailing.equalTo(self)
                    make.top.equalTo(searchBorder)
                    make.height.equalTo(56)
                }
            }
        } else {
            copyButton.isHidden = true
            copyBorder.isHidden = true
        }
    }

    @objc private func didPressSearch() {
        delegate?.overlayView(self, didSearchForQuery: searchQuery)
    }
    @objc private func didPressCopy() {
        delegate?.overlayView(self, didSubmitText: UIPasteboard.general.string!)
    }
    @objc private func didPressSettings() {
        delegate?.overlayViewDidPressSettings(self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.overlayViewDidTouchEmptyArea(self)
    }

    func dismiss() {
        setSearchQuery(query: "", animated: false)
        self.isUserInteractionEnabled = false
        copyButton.isHidden = true
        copyBorder.isHidden = true
        animateHidden(true, duration: UIConstants.layout.overlayAnimationDuration) {
            self.isUserInteractionEnabled = true
        }
    }

    func present() {
        setSearchQuery(query: "", animated: false)
        self.isUserInteractionEnabled = false
        copyButton.isHidden = false
        copyBorder.isHidden = false
        animateHidden(false, duration: UIConstants.layout.overlayAnimationDuration) {
            self.isUserInteractionEnabled = true
        }
    }
}
extension URL {
    public func isWebPage() -> Bool {
        let schemes = ["http", "https"]
        if let scheme = scheme, schemes.contains(scheme) {
            return true
        }
        return false
    }
}

extension OverlayView: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) {}
}

extension UIPasteboard {
    func urlAsync(callback: @escaping (URL?) -> Void) {
        DispatchQueue.global().async {
            let url = URL(string: UIPasteboard.general.string ?? "")
            callback(url)
        }
    }
}
