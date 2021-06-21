import Combine
import UIKit
import Kingfisher

class MainViewController: UIViewController {
  private var cancellables = Set<AnyCancellable>()
  private let searchTextChangedSubject = PassthroughSubject<String, Never>()
    private let cellTappedChangedSubject = PassthroughSubject<SearchResult, Never>()
    private let viewWillAppearChangedSubject = PassthroughSubject<Void, Never>()
    private let IDChangedSubject = PassthroughSubject<String, Never>()
    let apikey = Constants.tenorApiKey
    var searchResults = [SearchResult]()

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.titleView = searchBar

    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.delegate = self
    collectionView.dataSource = self
    
    let (loadResults, pushDetailView, _) = mainViewModel(
      cellTapped:  cellTappedChangedSubject.eraseToAnyPublisher(), // to compile but not function, you can replace with Empty().eraseToAnyPublisher()
      searchText: searchTextChangedSubject.eraseToAnyPublisher(),
      viewWillAppear: viewWillAppearChangedSubject.eraseToAnyPublisher(), // to compile but not function, you can replace with Empty().eraseToAnyPublisher()
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
  }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchTextChangedSubject.send("")
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
}

// MARK: UISearchBarDelegate

extension MainViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    searchTextChangedSubject.send(searchText)
    
    collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
  }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchTextChangedSubject.send(searchBar.text ?? "")
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
        let gifImageView = UIImageView(frame: cell.contentView.frame)
        gifImageView.contentMode = .scaleAspectFill
        gifImageView.clipsToBounds = true
        cell.contentView.addSubview(gifImageView)
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
