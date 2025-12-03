//
//  ShareViewController.swift
//  IslandMemoShareExtension
//
//  Created by 구민준 on 12/3/25.
//

import UIKit
import SwiftUI
import SwiftData

class ShareViewController: UIViewController {
    private var sharedURL: String?
    private var hostingController: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 공유된 URL 추출
        extractSharedURL()
    }

    private func extractSharedURL() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            print("❌ Share Extension: No items to share")
            closeExtension()
            return
        }

        // 먼저 URL 타입 시도
        if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] (item, error) in
                if let url = item as? URL {
                    DispatchQueue.main.async {
                        print("✅ Share Extension: URL 받음 - \(url.absoluteString)")
                        self?.sharedURL = url.absoluteString
                        self?.showShareView()
                    }
                } else {
                    print("⚠️ Share Extension: URL 변환 실패, 텍스트 시도")
                    self?.tryExtractFromText(itemProvider)
                }
            }
        }
        // URL이 없으면 텍스트에서 URL 추출 시도
        else if itemProvider.hasItemConformingToTypeIdentifier("public.text") {
            print("📝 Share Extension: 텍스트 타입 감지")
            tryExtractFromText(itemProvider)
        }
        // Plain text도 시도
        else if itemProvider.hasItemConformingToTypeIdentifier("public.plain-text") {
            print("📝 Share Extension: Plain 텍스트 타입 감지")
            itemProvider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { [weak self] (item, error) in
                if let text = item as? String {
                    DispatchQueue.main.async {
                        self?.extractURLFromText(text)
                    }
                } else {
                    print("❌ Share Extension: Plain 텍스트 추출 실패")
                    self?.closeExtension()
                }
            }
        } else {
            print("❌ Share Extension: 지원하지 않는 타입")
            closeExtension()
        }
    }

    private func tryExtractFromText(_ itemProvider: NSItemProvider) {
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { [weak self] (item, error) in
            if let text = item as? String {
                DispatchQueue.main.async {
                    print("📝 Share Extension: 텍스트 받음 - \(text)")
                    self?.extractURLFromText(text)
                }
            } else if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    print("📝 Share Extension: Data에서 텍스트 변환 - \(text)")
                    self?.extractURLFromText(text)
                }
            } else {
                print("❌ Share Extension: 텍스트 추출 실패")
                self?.closeExtension()
            }
        }
    }

    private func extractURLFromText(_ text: String) {
        // 텍스트에서 URL 추출
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        if let match = matches?.first, let url = match.url {
            print("✅ Share Extension: 텍스트에서 URL 추출 - \(url.absoluteString)")
            sharedURL = url.absoluteString
            showShareView()
        } else if text.hasPrefix("http://") || text.hasPrefix("https://") {
            // 텍스트 자체가 URL인 경우
            print("✅ Share Extension: 텍스트 자체가 URL - \(text)")
            sharedURL = text
            showShareView()
        } else {
            print("❌ Share Extension: URL을 찾을 수 없음")
            closeExtension()
        }
    }

    private func showShareView() {
        guard let url = sharedURL else {
            closeExtension()
            return
        }

        let sharedModelContainer = SharedModelContainer.create()

        let shareView = ShareExtensionView(
            url: url,
            onSave: { [weak self] in
                self?.closeExtension()
            },
            onCancel: { [weak self] in
                self?.closeExtension()
            }
        )
        .modelContainer(sharedModelContainer)

        let hosting = UIHostingController(rootView: AnyView(shareView))
        hostingController = hosting

        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hosting.didMove(toParent: self)
    }

    private func closeExtension() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
