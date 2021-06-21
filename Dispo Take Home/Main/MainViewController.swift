import Combine
import UIKit
import Kingfisher
import SnapKit

class MainViewController: UIViewController {
  private var cancellables = Set<AnyCancellable>()
  private let searchTextChangedSubject = PassthroughSubject<String, Never>()
    private let cellTappedChangedSubject = PassthroughSubject<SearchResult, Never>()
    private let viewWillAppearChangedSubject = PassthroughSubject<Void, Never>()
    private let IDChangedSubject = PassthroughSubject<String, Never>()
    private let FeatureloadChangedSubject = PassthroughSubject<String, Never>()
    let apikey = Constants.tenorApiKey
    var searchResults = [SearchResult]()


  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.titleView = searchBar

    runSnapKitAuthLayout()
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.delegate = self
    collectionView.dataSource = self
    
    let (loadResults, pushDetailView, loadFeaturedResults, _) = mainViewModel(
      cellTapped:  cellTappedChangedSubject.eraseToAnyPublisher(), // to compile but not function, you can replace with Empty().eraseToAnyPublisher()
      searchText: searchTextChangedSubject.eraseToAnyPublisher(),
        viewWillAppear: viewWillAppearChangedSubject.eraseToAnyPublisher(),
        emptysearchText: FeatureloadChangedSubject.eraseToAnyPublisher(), // to compile but not function, you can replace with Empty().eraseToAnyPublisher()
        id: IDChangedSubject.eraseToAnyPublisher()
    )

    loadResults
      .sink { [weak self] results in
        // load search results into data source
        //self?.requestData()
        self?.searchResults = results
        print("results are \(results)")
        self?.collectionView.reloadData()
      }
      .store(in: &cancellables)

    pushDetailView
      .sink { [weak self] result in
        // push detail view
        print("result is \(result)")
        let vc = DetailViewController(searchResult: result)
        self?.navigationController?.pushViewController(vc, animated: true)
      }
      .store(in: &cancellables)
    
    loadFeaturedResults
        .sink { [weak self] results in
          // load search results into data source
          //self?.requestData()
          self?.searchResults = results
          print("results are \(results)")
          self?.collectionView.reloadData()
        }
        .store(in: &cancellables)
  }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        FeatureloadChangedSubject.send("")
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
    flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 110)
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
    
    private func runSnapKitAuthLayout() {
        
    }
}

// MARK: UISearchBarDelegate

extension MainViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if searchText.isEmpty {
        FeatureloadChangedSubject.send("")
    } else {
        searchTextChangedSubject.send(searchText)
    }
    
    collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
  }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text?.isEmpty == true {
            FeatureloadChangedSubject.send("")
        } else {
            searchTextChangedSubject.send(searchBar.text!)
        }
        
        searchBar.resignFirstResponder()
        
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
    }
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = UIColor.white
        let gifImageView = UIImageView()
        let gifNameLabel = UILabel()
        if searchResults[indexPath.item].text == "" {
            gifNameLabel.text = "No Title"
        } else {
            gifNameLabel.text = searchResults[indexPath.item].text
        }
        gifImageView.contentMode = .scaleAspectFill
        gifImageView.clipsToBounds = true
        cell.contentView.addSubview(gifImageView)
        cell.contentView.addSubview(gifNameLabel)
        let imageViewWidth = 100
        let imageViewHeight = 100
        let labelHeight = 22
        gifImageView.snp.makeConstraints { (make) in
            make.top.equalTo(5)
            make.leading.equalTo(8)
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(imageViewHeight)
        }
        
        gifNameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(44)
            make.leading.equalTo(116)
            make.trailing.equalTo(8)
            make.height.equalTo(labelHeight)
        }
        let url = searchResults[indexPath.item].gifUrl
        gifImageView.kf.indicatorType = .activity
        gifImageView.kf.setImage(with: url)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let id = searchResults[indexPath.item].id
        let url = searchResults[indexPath.item].gifUrl
        let text = searchResults[indexPath.item].text
        let result = SearchResult(id: id, gifUrl: url, text: text)
        cellTappedChangedSubject.send(result)
    }
}
