# CombinePractice


## TODO
- ~Rx asSingle 빼껴서 asFuture() extension 생성(내부 구독 없는 방법?)~
- Publisher에 empty, never, fail, just 붙이기?

## 기록
- skip -> dropFirst
- take -> first
- tryMap -> map 도중에 에러방출?
- do(onNext:) -> handleEvents
- future 왠만하면 안쓰는걸로(진짜 일회성 기능의 경우만 쓰기)
- AnyCancellable -> store(in inout Set<AnyCacncellable>) disposebag이랑 비슷하게 있음
  
# SwiftUI

## TODO
- aspectRatio, ContentMode 속성에 대하여 더 알아볼것
- publisher랑 바인딩, 하위뷰에 상위뷰 레벨에서 바인드할 퍼블리셔 전달할 수 있는지

## 기록

### View는 protocol
- body에 View 구현체 리턴해줘야함

#### some: Opaque return types — generic protocols can now be used as return types.
```swift
func returnCellView(_ cellViewModel: AddItemCellViewModel) -> some View {
    switch cellViewModel {
    case .header(let title):
        return HeaderView(title).asAny()
        
    default: break
    }
    return AnyView(Text("ㅇㅇㅇ"))
}
var body: some View {
    VStack() {
        LargeHeaderView()
            .aspectRatio(contentMode: ContentMode.fit)
        List {
            ForEach(self.cellViewModels, id: \.self, content: returnCellView)
        }
    }
}
```
* 여러타입 리턴시 컴파일 에러 -> AnyView(_ view: View)로 랩핑 가능
```swift
extension View {
    func asAny() -> AnyView {
        return AnyView(self)
    }
}
```
- view 사이징, 위치, 정렬 등은 안드로이드와 비슷


### @State
Property Wrapper that holds private data for the View and its children.
- 뷰가 변화를 관찰하는 데이터
- Every State is a source of truth
- state 변경시 뷰의 body 리컴퓨팅, single source of truth -> 하위뷰로 상태 전파
```swift
struct HikeView: View {
var hike: Hike
@State private var showDetail = false 
...
   Button(action: {
      withAnimation {self.showDetail.toggle()}
   }
...
}
```

### @Binding
Property wrapper read and write without ownership.
Derivable from @State
```swift
struct myView : View {
   @Binding var passInData: String
   var body: some View {
      Text(passInData)                        
   }
}
// Pass the data to the view:
@State private var someName: String = "hi" // create your data
// pass the data to the view
MyView(someName : $someName) // create a binding & pass it down
```

### Working with external data
- Combine Publisher
    - Single Abstraction
    - Main thread: use .receive(on:)
    
1. state 추가 및 디펜던시 생성
```swift
@State private var cellViewModels: [AddItemCellViewModel] = [
        .searchBar
    ]
public var body: some View {
    NavigationView {
        List {
            AdBannerView()
            ForEach(self.cellViewModels, id: \.self, content: returnCellView)
        }
        .onReceive(self.viewModel.cellViewModels) { newValues in
            self.cellViewModels = newValues
        }
    }
}
```

2. external data에 대한 single source of truth BindableObject 생성
#### @ObjectBinding Protocol
- 외부데이터
- 레퍼런스 타입
- great for the model you already have
- model -> view로 @ObjectBinding
```swift
Class foo : BindableObject {
   Var didChange = PassthroughSubject<Void, Never>() //← Publisher()  
   Func adv() {                                                     
       didChange.send() //← send changes                            
}

struct MyView : View {
    @ObjectBinding var model: MyModelObject
    ...
}
MyView(model : modelInstance) // view has dependency on model
```

### Environment
- Data applicable to an entire hierarchy
- Convernience for indirection
- ex) Accent color, right-to-left


### Source of truth
- State: View-local, Value, Framework Managed
- BindableObject: External, reference, Develop Managed


## TODO
- ~그럼 view -> external 이벤트전파는 어케함..~
- ~View에 ObservableObject  주입할때 추상화 방안..~
    - ~Presenter를 따로 분리해야하나?~
- ~view는 재사용성을 위하여 뎁스가 깊어지는데 상태관리는 단일 뷰모델로 하기 어려움 -> 뷰모델을 여러개 맨들어야하나?~


### View -> External event 전파
- 하위뷰에서 발생한 이벤트를 상위뷰를 통해 외부로 전파할때 하위뷰 + @State / 상위뷰 + @Binding의 관계가 아니라 하위뷰가 Binding을 주입받고 상위뷰가 source of truth를 들고있어함
- Binding은 주입의 대상, 상위뷰가 Binding을 하위뷰로부터 주입 불가능
- ViewEventListener helper class 생성

```swift
import Combine
import SwiftUI


public class ViewEventObserver<Value>: ObservableObject {
    
    @Published public var observingValue: Value
    public var receivingNewValues: ((Value) -> Void)?
    private var observing: AnyCancellable?
    
    public init(_ defaultValue: Value, callback: ((Value) -> Void)? = nil) {
        self.observingValue = defaultValue
        self.receivingNewValues = callback
        
        self.observing = self.$observingValue
            .sink(receiveValue: { [weak self] value in
                self?.receivingNewValues?(value)
            })
    }
    
    deinit {
        observing?.cancel()
    }
}

...

fileprivate struct SearchView: View {
    
    @Binding var isSearching: Bool
    @Binding var inputTxt: String
    
    private let searchCalled: () -> Void
    
    init(isSearching: Binding<Bool>, inputTxt: Binding<String>, closure: @escaping () -> Void) {
        self._isSearching = isSearching
        self._inputTxt = inputTxt
        self.searchCalled = closure
    }
    
    var body: some View {
        ZStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.gray)
                
                TextField("place holder", text: $inputTxt) {
                    UIApplication.shared.endEditing()
                    self.searchCalled()
                }
                
                ActivityIndicator(isAnimating: $isSearching, style: .medium)
                if inputTxt.isEmpty == false && isSearching == false {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.gray.opacity(0.8))
                        .onTapGesture {
                            self.inputTxt = ""
                    }
                }
            }
            
        }
        .padding(12)
        .background(
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.2))
                .cornerRadius(10)
        )
    }
}

public struct AddItemMainView: View {
    private let viewModel: AddItemViewModelType
    @ObservedObject private var textInputListener = ViewEventObserver<String>("")
    
    var body: some View {
      ...
      SearchView(isSearching: $isSearching,
                              inputTxt: $textInputListener.observingValue)
    }
}

```
## Data 흐름
- ViewModel내 상태변화 -> View 렌더링(+ subscribe 초기화)
```swift
// ViewModel
private let _items = CurrentValueSubject<[SettingRowItem], Never>([])
private let _isCacheClearing = CurrentValueSubject<Bool, Never>(false)

public func clearCachedData() {
  self._isCacheClearing.send(true)
  self.usecase.clearMediaCache()
      .sink(receiveCompletion: { _ in },
            receiveValue: { _ in
              self._isCacheClearing.send(false)
      })
      .store(in: &self.cancelBag)
}

public var items: AnyPublisher<[SettingRowItem], Never> {
    return Publishers
        .CombineLatest(self._items.dropFirst(), self._isCacheClearing)
        .map { source, isClearing -> [SettingRowItem] in
            guard let index = source.cacheIndex else {
                return source
            }
            var sender = source
            sender[index] = .row(.clearCache(isClearing))
            return sender
        }
        .eraseToAnyPublisher()
}
```
- 위의 경우 _items, _isCacheClearing 변화에 따라 items 값 변화 -> 뷰 렌더링 -> 구독 초기화 -> 이전값으로 이벤트 재발생 -> 무한루프
- clearCachedData() 메소드 내부에서 _items에 변화를 가하고 이로인해 view가 다시 그려지도록 유도해야함
- ViewModel이 뷰를 그린다(기존의 View가 ViewModel을 소유하고 상태를 구독하는 방식은 x)
