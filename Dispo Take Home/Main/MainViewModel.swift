import Combine
import UIKit

func mainViewModel(
  cellTapped: AnyPublisher<SearchResult, Never>,
  searchText: AnyPublisher<String, Never>,
  viewWillAppear: AnyPublisher<Void, Never>,
    id: AnyPublisher<String, Never>
) -> (
  loadResults: AnyPublisher<[SearchResult], Never>,
  pushDetailView: AnyPublisher<SearchResult, Never>,
    gifInfoDetailView: AnyPublisher<[GifInfo], Never>
) {
  let api = TenorAPIClient.live

  //let featuredGifs = Empty<[SearchResult], Never>()

  let searchResults = searchText
    .map { api.searchGIFs($0) }
    .switchToLatest()

  // show featured gifs when there is no search query, otherwise show search results
  let loadResults = searchResults
    .eraseToAnyPublisher()

  let pushDetailView = cellTapped
    .eraseToAnyPublisher()
    
    let searchInfo = id.map {api.gifInfo($0)}.switchToLatest()
    let gifInfoDetailView = searchInfo.eraseToAnyPublisher()

  return (
    loadResults: loadResults,
    pushDetailView: pushDetailView,
    gifInfoDetailView: gifInfoDetailView
  )
}
