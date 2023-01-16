//
//  ContentView.swift
//  GetGeocodeSample
//
//  Created by 春蔵 on 2023/01/14.
//

import SwiftUI
import MapKit

struct ContentView: View {
    /// ViewModel
    @StateObject var viewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            HStack {
                // 場所入力欄
                TextField("", text: $viewModel.location)
                    .padding(5)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.primary.opacity(0.6), lineWidth: 0.3))
                    .onChange(of: viewModel.location) { newValue in
                        viewModel.onSearchLocation()
                    }
                
                // アラーム設定ボタン
                Image(systemName: viewModel.locationEngine.status == .start ? "mappin.slash" : "mappin")
                    .imageScale(.large)
                    .onTapGesture {
                        viewModel.setAlarm()
                    }
            }
            
            if viewModel.completions.count > 0 {
                // 検索候補
                List(viewModel.completions , id: \.self) { completion in
                    HStack{
                        VStack(alignment: .leading) {
                            Text(completion.title)
                            Text(completion.subtitle)
                                .foregroundColor(Color.primary.opacity(0.5))
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture{
                        viewModel.onLocationTap(completion)
                    }
                }
            } else {
                GeometryReader { geometry in
                    // 地図情報の表示
                    MapView(viewModel: viewModel , geometry:geometry)
                }
                
                
            }
            
            Spacer()
        }
        .padding()
        .onAppear{
            viewModel.onAppear()
        }
    }
}

struct MapView: View {
    /// ViewModel
    @ObservedObject var viewModel = ContentViewModel()
    /// Geometry
    var geometry:GeometryProxy
    
    var body: some View {
        /// 地図表示
        /// interactionModes : ユーザー操作の許可 .pan　スワイプ（ドラッグ）による操作を許可。 .zoom　ダブルタッチ or ピンチ操作による拡大・縮小の操作を許可 .all　.pan と .zoom の両方を許可します。
        /// showsUserLocation : ユーザーの現在位置を表示
        /// userTrackingMode : .follow　ユーザーの追跡 .none　ユーザーの追跡を停止します。
        /// annotationItems: RandomAccessCollection
        /// annotationContent: : MapMarker  MapPin
        Map(coordinateRegion: $viewModel.region
            ,interactionModes: .all
            ,showsUserLocation: false
            ,userTrackingMode: .none
            ,annotationItems: viewModel.pinItems
            ,annotationContent: { item in
            // 円を表示する
//            MapAnnotation(
//                coordinate: item.coordinate,
//                anchorPoint: CGPoint(x: 0.5, y: 0.5)
//            ) {
//                Circle()
//                    .strokeBorder(Color.blue,lineWidth: 3)
//                    .background(Circle().foregroundColor(Color.blue.opacity(0.2)))
//                    .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
//            }
            // ピンを表示する
            MapMarker(coordinate: item.coordinate , tint: .blue)
            }
        )
        .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.9)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.primary.opacity(0.8), lineWidth: 0.3)
        )
    }
}

