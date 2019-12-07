# CombinePractice


## TODO
- Rx asSingle 빼껴서 asFuture() extension 생성(내부 구독 없는 방법?)
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
- 그럼 view -> external 이벤트전파는 어케함..
- View에 ObservableObject  주입할때 추상화 방안..
    - Presenter를 따로 분리해야하나?
- view는 재사용성을 위하여 뎁스가 깊어지는데 상태관리는 단일 뷰모델로 하기 어려움 -> 뷰모델을 여러개 맨들어야하나?
