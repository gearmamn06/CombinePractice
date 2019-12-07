//
//  MyParentView.swift
//  CombinePractice
//
//  Created by Sudo.park on 2019/12/07.
//  Copyright © 2019 ParkHyunsoo. All rights reserved.
//

import Combine
import SwiftUI

struct MyChildView: View {
    
    @Binding var text: String
    
    var body: some View {
        Text("\text")
    }
}

struct MyParentView: View {
    
    private let viewModel: ViewModel
    @State private var text: String = ""
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Text(text)
            .onReceive(viewModel.newText) { newValue in
                self.text = newValue
        }
    }
}

struct ViewModel {

    var newText: AnyPublisher<String, Never> {
        return Just("1")
            .eraseToAnyPublisher()
            
    }
}

struct MyParentView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        let viewModel = ViewModel()
        return MyParentView(viewModel: viewModel)
    }
}
