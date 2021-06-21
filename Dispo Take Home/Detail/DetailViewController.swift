import Combine
import UIKit
import Kingfisher
import SnapKit

class DetailViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let searchTextChangedSubject = PassthroughSubject<String, Never>()
      private let cellTappedChangedSubject = PassthroughSubject<SearchResult, Never>()
      private let viewWillAppearChangedSubject = PassthroughSubject<Void, Never>()
    private let IDChangedSubject = PassthroughSubject<String, Never>()
    private let FeatureloadChangedSubject = PassthroughSubject<String, Never>()
    var imageURL: URL?
    var imageTitle: String?
    var imageID: String?
    var gifImageView = UIImageView()
    var shareCountLabel = UILabel()
    var backGroundColorLabel = UILabel()
    var tagsLabel = UILabel()
    var infos = [GifInfo]()
    
  init(searchResult: SearchResult) {
    super.init(nibName: nil, bundle: nil)
    
    imageURL = searchResult.gifUrl
    imageTitle = searchResult.text
    imageID = searchResult.id
  }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let (_, _, _, gifInfoDetailView) = mainViewModel(
          cellTapped:  cellTappedChangedSubject.eraseToAnyPublisher(), // to compile but not function, you can replace with Empty().eraseToAnyPublisher()
          searchText: searchTextChangedSubject.eraseToAnyPublisher(),
            viewWillAppear: viewWillAppearChangedSubject.eraseToAnyPublisher(),
            emptysearchText: FeatureloadChangedSubject.eraseToAnyPublisher(), // to compile but not function, you can replace with Empty().eraseToAnyPublisher()
            id: IDChangedSubject.eraseToAnyPublisher()
        )
        
        gifInfoDetailView
            .sink { [weak self] results in
            print("detail result is \(results)")
                self?.infos = results
                let shareAmount = self?.infos[0].shares
                let backgroundColor = self?.infos[0].backgroundColor
                let tags = self?.infos[0].tags
                DispatchQueue.main.async {
                    if shareAmount ?? 0 < 2 {
                        self?.shareCountLabel.text = "\(shareAmount ?? 0) Share"
                    } else {
                        self?.shareCountLabel.text = "\(shareAmount ?? 0) Shares"
                    }
                    if backgroundColor?.isEmpty == false {
                        self?.backGroundColorLabel.text = "Background Color: \(backgroundColor ?? "None")"
                    } else {
                        self?.backGroundColorLabel.text = "Background Color: None"
                    }
                    
                    if tags?.isEmpty == true {
                        self?.tagsLabel.text = "Tags: None"
                    } else {
                        let tagsName = tags?.joined(separator: ", ")
                        self?.tagsLabel.text = "Tags: \(tagsName ?? "None")"
                    }
                }
                
        }
        .store(in: &cancellables)
        
        if imageTitle == "" {
            self.navigationItem.title = "No Title"
        } else {
            self.navigationItem.title = imageTitle
        }
        
        runSnapKitAuthLayout()
        
        shareCountLabel.textAlignment = .center
        backGroundColorLabel.textAlignment = .center
        tagsLabel.textAlignment = .center
        
        shareCountLabel.text = ""
        backGroundColorLabel.text = ""
        tagsLabel.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        IDChangedSubject.send(imageID!)
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
}
