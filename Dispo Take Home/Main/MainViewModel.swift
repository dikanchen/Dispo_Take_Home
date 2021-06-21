import Combine
import UIKit

func mainViewModel(
  cellTapped: AnyPublisher<SearchResult, Never>,
  searchText: AnyPublisher<String, Never>,
  viewWillAppear: AnyPublisher<Void, Never>,
    emptysearchText: AnyPublisher<String, Never>,
    id: AnyPublisher<String, Never>
) -> (
  loadResults: AnyPublisher<[SearchResult], Never>,
  pushDetailView: AnyPublisher<SearchResult, Never>,
    loadFeaturedResults: AnyPublisher<[SearchResult], Never>,
    gifInfoDetailView: AnyPublisher<[GifInfo], Never>
) {
  let api = TenorAPIClient.live

    let featuredGifs = emptysearchText.map { _ in api.featuredGIFs()}.switchToLatest()

  let searchResults = searchText
    .map { api.searchGIFs($0) }
    .switchToLatest()

  // show featured gifs when there is no search query, otherwise show search results
  let loadResults = searchResults
    .eraseToAnyPublisher()
    
    let loadFeaturedResults = featuredGifs.eraseToAnyPublisher()

  let pushDetailView = cellTapped
    .eraseToAnyPublisher()
    
    let searchInfo = id.map {api.gifInfo($0)}.switchToLatest()
    let gifInfoDetailView = searchInfo.eraseToAnyPublisher()

  return (
    loadResults: loadResults,
    pushDetailView: pushDetailView,
    loadFeaturedResults: loadFeaturedResults,
    gifInfoDetailView: gifInfoDetailView
  )
}
