import Combine
import UIKit
import Kingfisher

class MainViewController: UIViewController {
  private var cancellables = Set<AnyCancellable>()
  private let searchTextChangedSubject = PassthroughSubject<String, Never>()
    private let cellTappedChangedSubject = PassthroughSubject<SearchResult, Never>()
    private let viewWillAppearChangedSubject = PassthroughSubject<Void, Never>()
    let apikey = Constants.tenorApiKey
    var searchTerm = "featured"
    var gifs = [AnyObject]()
    static var searchText = ""
    static var indexItem = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.titleView = searchBar
    
    requestData()

    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.delegate = self
    collectionView.dataSource = self
    
    let _ = mainViewModel(
      cellTapped:  cellTappedChangedSubject.eraseToAnyPublisher(), // to compile but not function, you can replace with Empty().eraseToAnyPublisher()
      searchText: searchTextChangedSubject.eraseToAnyPublisher(),
      viewWillAppear: viewWillAppearChangedSubject.eraseToAnyPublisher() // to compile but not function, you can replace with Empty().eraseToAnyPublisher()
    )

    viewWillAppearChangedSubject
      .sink { [weak self] results in
        // load search results into data source
        self?.requestData()
      }
      .store(in: &cancellables)

    cellTappedChangedSubject
      .sink { [weak self] result in
        // push detail view
        print("result is \(result)")
        let vc = DetailViewController(searchResult: result)
        self?.navigationController?.pushViewController(vc, animated: true)
      }
      .store(in: &cancellables)
    
    searchTextChangedSubject
        .sink { [weak self] result in
        print(result)
        MainViewController.searchText = result
      }
      .store(in: &cancellables)
  }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewWillAppearChangedSubject.send()
    }

  override func loadView() {
    view = UIView()
    view.backgroundColor = .systemBackground
    view.addSubview(collectionView)

    collectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }

  private lazy var searchBar: UISearchBar = {
    let searchBar = UISearchBar()
    searchBar.placeholder = "search gifs..."
    searchBar.delegate = self
    return searchBar
  }()

  private var layout: UICollectionViewLayout {
    // TODO: implement
    //fatalError()
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.itemSize = CGSize(width: 98, height: 134)
    flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
    flowLayout.minimumInteritemSpacing = 0.0

    return flowLayout
  }

  private lazy var collectionView: UICollectionView = {
    let collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: layout
    )
    collectionView.backgroundColor = .clear
    collectionView.keyboardDismissMode = .onDrag
    return collectionView
  }()
    
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
        let media = result.results[0]["media"] as! [AnyObject]
        let gif = media[0]["gif"] as! [String: AnyObject]
        let url = gif["url"] as? String ?? ""

        // Load the GIFs into your view
        print("Result GIFS: \(url)")
        gifs = result.results
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
      }
}

// MARK: UISearchBarDelegate

extension MainViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    searchTextChangedSubject.send(searchText)
    if searchText.isEmpty == true {
        searchTerm = "featured"
    } else {
        searchTerm = searchText
    }
    
    requestData()
    
    collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
  }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchTextChangedSubject.send(searchBar.text ?? "")
        searchBar.resignFirstResponder()
        
        if searchBar.text?.isEmpty == true {
            searchTerm = "featured"
        } else {
            searchTerm = searchBar.text ?? "featured"
        }
        
        requestData()
        
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
    }
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = UIColor.white
        let gifImageView = UIImageView(frame: cell.contentView.frame)
        gifImageView.contentMode = .scaleAspectFill
        gifImageView.clipsToBounds = true
        cell.contentView.addSubview(gifImageView)
        let media = gifs[indexPath.item]["media"] as! [AnyObject]
        let gif = media[0]["gif"] as! [String: AnyObject]
        let url = gif["url"] as? String ?? ""
        gifImageView.kf.indicatorType = .activity
        gifImageView.kf.setImage(with: URL(string: url))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let id = gifs[indexPath.item]["id"] as? String ?? ""
        let media = gifs[indexPath.item]["media"] as! [AnyObject]
        let gif = media[0]["gif"] as! [String: AnyObject]
        let url = gif["url"] as? String ?? ""
        let text = gifs[indexPath.item]["title"] as? String ?? ""
        let searchResult = SearchResult(id: id, gifUrl: URL(string: url)!, text: text)
        MainViewController.indexItem = indexPath.item
        cellTappedChangedSubject.send(searchResult)
    }
}
