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


## TODO
- ViewModel을 struct으로 전환시키기 위해 cancelbag
- ~source of truth를 최소화하기 위하여 ViewEventObserver의 발류타입이 enum 형태인경우 가능?~


## View 이벤트 상태 관리
1. alert or actionSheet
- 해당 뷰를 발생시키는 이벤트 트리깅 뷰 이후에 묶거나 전체 뷰에 묶을 수 있음
- 뷰 트리깅 이벤트는 Binding<Bool>, Binding<Identifiable: Hashable>이 가능, 후자를 이용하면 특정 데이터에 대한 알러트 생성 가능
2. NavigationLink
- 트리깅하는 뷰에 바로 밖아버리는 방법밖에 없음..
- tag: Hashable를 이용하여 링크 생성 및 분기 가능

뷰모델이 ObservableObject이 아닌이상 뷰의 전역변수에 @State 선언해주는것이 지금으로는 최선 -> 위와같이 이벤트와 관련된 플래그를 랩핑하는것과 같은 방법 고민 필요

## ~SceneBuilder~
- 뷰 내부에서 다음뷰와 직접적으로 연결해줘야함(개짜증)
- 라우팅로직이 뷰 내부의 특정 부분에 묶일수밖에 없음...(트리깅은 외부에서 가능)
- 이를 해결하기 위하여 현재 화면이 다음 화면에대한 의존을 갖는 부분이 썩 내키지 않음 + 현재 Scene별로 프레임워크로 분리된 프로젝트 구조에 적절하지 않다 
- ~Scene별 SceneBuilder protocol로 정의, View가 이를 주입받도록하고 builder의 구현체에서 computed property 혹은 lazy property를 이용하여 다음 View와 연결!
- ~최종단계에 app level의 DI Container가 하위 뷰들의 프로토콜들을 준수하며 기능을 구현하게하고 뷰에 주입하는 방법 이용할꺼임~

-> 이거 팩토리로 맨들어도 NavigationLink에 destination 지정해줄때 생성됨 존나얼탱이없음
- 뷰 init 부분에서 서부뷰 전부를 그리면 안되고 onAppear에서 그리기 시작해야 벙찌는거 사라짐

## SwiftUI는 뷰그리는것만 하고 결국 호스팅 UIViewController로 라우팅을 해보자..
- 진짜 뷰는 그리는일이랑 유저인풋 받는일만 하게함, 인터페이스빌더 코드로 짠다고 생각하자..swiftUI로는 이게 최선임 ㅇㅇ
- 호스팅 뷰 컨에서 라우팅을 담당하게 하거나 기존 방식의 코디네이터로 네비게이션 구성
- 이경우 뷰가 닫히는 이벤트에 대해서도 라우팅로직 추가되어야함 -> 코디네이터로 구현하여 전체 네비게이션 로직 
- ~호스팅 뷰컨 네비바 숨기고 스윕체스처로 백 가능하게 해둬야함~ -> 기본


## 기록 -> 뷰 타이밍
- 상황: 뷰에 onReceive를 이용하여 ViewModel의 상태변화 수신 -> @State 변경으로 뷰 변화 + 뷰 초기화시점에 초기데이터 로딩 요청 + onAppear 부터 뷰를 그리기 시작하는 상황
- 가정1: 초기데이터 로딩이 지연되는 경우 -> 데이터 수신 이후 렌더링 / 데이터 지연이 없어 onAppear 보다 먼저 불리는 경우 -> 대기 이후 초기데이터 렌더링
- 문제점: _viewIsReady passThroughSubject를 이용하여 최초 이벤트발생시까지 대기, 데이터소스는 CurrentValueSubjet로 선언하여 viewIsReady 이벤트 발생 이후 마지막 발류를 반환 하려함
```swift

// view
@State private var cellViewModels: [SearchHistoryCellViewModel] = []
public var body: some View {
      List { ... }
        .onReceive(self.viewModel.cellViewModels) { newValues in
                self.cellViewModels = newValues
        }
        ...
        .onAppear {
            self.viewModel.viewIsReady()
        }
}


// viewModel
public var cellViewModels: AnyPublisher<[SearchHistoryCellViewModel], Never> {
        
      return _viewIsReady
          .first()
          .map{ _ in [] }
          .append(_combinedCellViewModels)
//          .dropFirst() // drop 해도 안해도 append 상단에 이벤트 발생이 없어서 동작 x
          .eraseToAnyPublisher()
  }
```
- 원인: 뷰에 publisher가 바인딩 되는 시점이 맨 마지막이여서(viewDidLoad에서 바인딩 먼저 하던시절과 다름..) _viewIsReady.first() 이벤트는 진작에 발생 -> 뷰에 바인딩 되는 시점에 발생할 _viewIsReady 이벤트 없음 다운스트림 작동 x
- 해결책: 뷰바인딩이 제일 나중에 일어남으로 (appear 이후 body 가 그려질때) + 재바인딩이 일어날 수 있으므로 위의 케이스 신경 안써도됨, 최초 데이터 로딩이 지연되 onAppear 이후에 이벤트가 전달된다면 정상 동작
- 위 로직에서는 _viewIsReady를 currentValueSubject로 변경하면 될꺼같긴 하지만 무의미
- 바인딩이 제일 나중에 일어나기 때문에 데이터소스는 핫옵져블이여야만함


## 기록2 -> ForEach
- id 잘못제공하면 list 갱신 x


##  기록3 - UIViewRepresentable로 UIView 재사용하기
- UIViewRepresentable을 따르는 중간객체, 상태느 @Binding으로
- 중간객체에서 makeUIView에서 UIView리턴하고 updateUIView에서 상태에따른 뷰 업데이트
- UIViewRepresentable을 이용하여 View생성, @State를 지님 onReceive에서 상태 업데이트(publishers from viewModel)
- @State 변경에따라 UIViewRepresentable을의 updateUIView 호출
- dismantleUIView에서 teardown 가능 (에니메이셔 중지 등)




