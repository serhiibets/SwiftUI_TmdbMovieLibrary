//  DetailNewsVC.swift
//  NewsApp
//  Created by Serhii Bets on 13.04.2022.
//  Copyright by Serhii Bets. All rights reserved.

import UIKit
import WebKit
import SafariServices

class DetailNewsVC: UIViewController, SFSafariViewControllerDelegate {
    
    enum FavoriteImage: String {
        case heart
        case heartFill
        
        var localizedDescription: UIImage {
            switch self {
            case .heart       : return UIImage(systemName: "heart")!
            case .heartFill   : return UIImage(systemName: "heart.fill")!
            }
        }
    }
    
    var news : News!
    var newsFromDB : [NewsEntity]?

    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var newsText: UITextView!
    @IBOutlet weak var newsUrl: UIButton!
    @IBOutlet weak var addToFavorite: UIButton!
    
    @IBAction func newsUrlBtn(_ sender: Any) {
        showLinksClicked()
    }
    
    
    @IBAction func addToFavoriteBtn(_ sender: Any) {
        addToFavorite.setImage(FavoriteImage.heartFill.localizedDescription, for: UIControl.State.normal)

            CoreDataManager.shared.fetchingNewsFromCoreData { result in
                switch result {
                case .success(let news):
                    self.newsFromDB = news
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            
            if !(newsFromDB?.contains(where: { $0.id == news.id  }) ?? true) {
                CoreDataManager.shared.downloadNews(model: news) { result in
                    switch result {
                    case .success():
                        NotificationCenter.default.post(name: NSNotification.Name("Downloaded"), object: nil)
                        print("News save success!")
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            } else {
                print("This news already saved!")
            }
            
        }
    
    func getImageUrl() -> URL? {
        let imageUrl = news?.media.first?.metadata.first(where: {$0.height == 293})
        return imageUrl?.url
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerTitle.text = news?.title
        newsText.text = news?.abstract
        newsUrl.titleLabel?.text = news?.url
        
        guard let imageUrl = getImageUrl() else { return }
        imageView.loadFrom(URLAddress: imageUrl.absoluteString)
    }
}

// === MARK: - SafariService ===
extension DetailNewsVC {
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        if navigationType == UIWebView.NavigationType.linkClicked {
            self.showLinksClicked()
            return false
        }
        return true;
    }
    
    func showLinksClicked() {
        guard let url = URL(string: news!.url) else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true, completion: nil)
        safariVC.delegate = self
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// === MARK: - UIImage extension ===
extension UIImageView {
    func loadFrom(URLAddress: String) {
        guard let url = URL(string: URLAddress) else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            if let imageData = try? Data(contentsOf: url) {
                if let loadedImage = UIImage(data: imageData) {
                        self?.image = loadedImage
                }
            }
        }
    }
}
