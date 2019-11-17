# CombinePractice


## TODO
- Rx asSingle 빼껴서 asFuture() extension 생성(내부 구독 없는 방법?)
- Publisher에 empty, never, fail, just 붙이기?

## 기록
- skip -> dropFirst
- take -> first
- tryMap -> failure 타입 변환 + map
- do(onNext:) -> handleEvents
- future 왠만하면 안쓰는걸로(진짜 일회성 기능의 경우만 쓰기)
- AnyCancellable -> store(in inout Set<AnyCacncellable>) disposebag이랑 비슷하게 있음
