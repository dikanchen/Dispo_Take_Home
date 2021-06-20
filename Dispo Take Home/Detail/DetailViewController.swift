import Combine
import UIKit
import Kingfisher
import SnapKit

class DetailViewController: UIViewController {
    var imageURL: URL?
    var imageTitle: String?
    var imageID: String?
    var gifImageView = UIImageView()
    var shareCountLabel = UILabel()
    var backGroundColorLabel = UILabel()
    var tagsLabel = UILabel()
    let apikey = Constants.tenorApiKey
    let searchTerm = MainViewController.searchText
    var gifs = [AnyObject]()
    
  init(searchResult: SearchResult) {
    super.init(nibName: nil, bundle: nil)
    
    imageURL = searchResult.gifUrl
    imageTitle = searchResult.text
    imageID = searchResult.id
  }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = imageTitle
        runSnapKitAuthLayout()
        
        shareCountLabel.textAlignment = .center
        backGroundColorLabel.textAlignment = .center
        tagsLabel.textAlignment = .center
        
        shareCountLabel.text = "14 Shares"
        backGroundColorLabel.text = "Background Color: None"
        tagsLabel.text = "Tags: Excited, Funny, Gif"
        
        requestData()
    }

  override func loadView() {
    view = UIView()
    view.backgroundColor = UIColor.white
    
    //let imageViewWidth = UIScreen.main.bounds.width - 40
    //let imageViewHeight = imageViewWidth * 3 / 4
    
    //gifImageView = UIImageView(frame: CGRect(x: 20, y: 60, width: imageViewWidth, height: imageViewHeight))
    gifImageView.contentMode = .scaleAspectFit
    view.addSubview(gifImageView)
    gifImageView.kf.indicatorType = .activity
    gifImageView.kf.setImage(with: imageURL)
    view.addSubview(shareCountLabel)
    view.addSubview(backGroundColorLabel)
    view.addSubview(tagsLabel)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
    
    private func runSnapKitAuthLayout() {
        let imageViewWidth = UIScreen.main.bounds.width - 40
        let imageViewHeight = imageViewWidth * 3 / 4
        let counterHeight = 21
        gifImageView.snp.makeConstraints { (make) in
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(imageViewHeight)
            make.leading.equalTo(20)
            make.top.equalTo(60)
        }
        shareCountLabel.snp.makeConstraints { (make) in
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(counterHeight)
            make.leading.equalTo(20)
            make.top.equalTo(80 + imageViewHeight)
        }
        backGroundColorLabel.snp.makeConstraints { (make) in
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(counterHeight)
            make.leading.equalTo(20)
            make.top.equalTo(109 + imageViewHeight)
        }
        tagsLabel.snp.makeConstraints { (make) in
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(counterHeight)
            make.leading.equalTo(20)
            make.top.equalTo(138 + imageViewHeight)
        }
    }
    
    func requestData()
      {

        // Define the results upper limit
        let limit = 50

        // make initial search request for the first 8 items
        let searchRequest = URLRequest(url: URL(string: String(format: "https://g.tenor.com/v1/search?q=%@&key=%@&limit=%d",
                                                                 searchTerm,
                                                                 apikey,
                                                                 limit))!)

        makeWebRequest(urlRequest: searchRequest, callback: tenorSearchHandler)

        // Data will be loaded by each request's callback
      }

      /**
       Async URL requesting function.
       */
      func makeWebRequest(urlRequest: URLRequest, callback: @escaping ([String:AnyObject]) -> ())
      {
        // Make the async request and pass the resulting json object to the callback
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
          do {
            if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject] {
              // Push the results to our callback
              callback(jsonResult)
            }
          } catch let error as NSError {
            print(error.localizedDescription)
          }
        }
        task.resume()
      }

      /**
       Web response handler for search requests.
       */
      func tenorSearchHandler(response: [String:AnyObject])
      {
        // Parse the json response
        let responseGifs = response["results"]!
        let result = GifResults(results: responseGifs as! [AnyObject])
        /*let media = result.results[0]["media"] as! [AnyObject]
        let gif = media[0]["gif"] as! [String: AnyObject]
        let url = gif["url"] as? String ?? ""

        // Load the GIFs into your view
        print("Result GIFS: \(url)")
        gifs = result.results
        
        DispatchQueue.main.async {
            //self.collectionView.reloadData()
        }*/
        let shareAmount = result.results[MainViewController.indexItem]["shares"] as? Int ?? 0
        let backgroundColor = result.results[MainViewController.indexItem]["bg_color"] as? String ?? ""
        let tags = result.results[MainViewController.indexItem]["tags"] as? [String] ?? []
        
        DispatchQueue.main.async {
            if shareAmount < 2 {
                self.shareCountLabel.text = "\(shareAmount) Share"
            } else {
                self.shareCountLabel.text = "\(shareAmount) Shares"
            }
            if backgroundColor.isEmpty == false {
                self.backGroundColorLabel.text = "Background Color: \(backgroundColor)"
            } else {
                self.backGroundColorLabel.text = "Background Color: None"
            }
            
            if tags.isEmpty == true {
                self.tagsLabel.text = "Tags: None"
            } else {
                let tagsName = tags.joined(separator: ", ")
                self.tagsLabel.text = "Tags: \(tagsName)"
            }
        }
      }
}
