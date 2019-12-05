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

#### some은 프로토콜을 따르는 어떤 구현체(프로토콜도 가능?)가 리턴될것이라는것을 의미
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
