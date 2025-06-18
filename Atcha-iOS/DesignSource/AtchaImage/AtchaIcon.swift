//
//  AtchaIcon.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/18/25.
//

import Foundation
import UIKit

enum AtchaIcon {
    // MARK: - Default Icon
    enum Normal {
        enum Bell {
            static let filled = UIImage(named: "Normal/Bell/bell-filled")
            static let outlined = UIImage(named: "Normal/Bell/bell-outlined")
        }
        
        enum Check {
            static let check = UIImage(named: "Normal/check")
        }
        
        enum Chevron {
            static let left = UIImage(named: "Normal/Chevron/chevron-left")
            static let right = UIImage(named: "Normal/Chevron/chevron-right")
            static let up = UIImage(named: "Normal/Chevron/chevron-up")
            static let down = UIImage(named: "Normal/Chevron/chevron-down")
        }
        
        enum Home {
            static let size16 = UIImage(named: "Normal/Home/home-16px")
            static let size24 = UIImage(named: "Normal/Home/home-24px")
        }
        
        enum Info {
            static let filled = UIImage(named: "Normal/Info/info-filled")
            static let outlined = UIImage(named: "Normal/Info/info-outlined")
        }
        
        static let map = UIImage(named: "Normal/map")
        
        enum MyLocation {
            static let filled = UIImage(named: "Normal/MyLocation/mylocation-filled")
            static let outlined = UIImage(named: "Normal/MyLocation/mylocation-outlined")
        }
        
        enum MyPage {
            static let filled = UIImage(named: "Normal/MyPage/mypage-filled")
            static let outlined = UIImage(named: "Normal/MyPage/mypage-outlined")
        }
        
        enum Place {
            static let filled = UIImage(named: "Normal/Place/place-filled")
            static let outlined = UIImage(named: "Normal/Place/place-outlined")
        }
        
        enum Radio {
            static let on = UIImage(named: "Normal/Radio/radio-on")
            static let off = UIImage(named: "Normal/Radio/radio-off")
        }
        
        enum Refresh {
            static let filled = UIImage(named: "Normal/Refresh/refresh-filled")
            static let outlined = UIImage(named: "Normal/Refresh/refresh-outlined")
        }
        
        static let reverseReturn = UIImage(named: "Normal/reverse-return")
        
        enum Route16px {
            static let bus = UIImage(named: "Normal/Route16px/route16px-bus")
            static let subway = UIImage(named: "Normal/Route16px/route16px-subway")
            static let walk = UIImage(named: "Normal/Route16px/route16px-walk")
        }
        
        enum Route24px {
            static let bus = UIImage(named: "Normal/Route24px/route24px-bus")
            static let subway = UIImage(named: "Normal/Route24px/route24px-subway")
            static let walk = UIImage(named: "Normal/Route24px/route24px-walk")
        }
        
        enum RouteCircle {
            static let bus = UIImage(named: "Normal/RouteCircle/route-circle-bus")
            static let subway = UIImage(named: "Normal/RouteCircle/route-circle-subway")
            static let walk = UIImage(named: "Normal/RouteCircle/route-circle-walk")
        }
        
        enum RouteCircleLine {
            static let bus = UIImage(named: "Normal/RouteCircleLine/route-circle-line-bus")
            static let subway = UIImage(named: "Normal/RouteCircleLine/route-circle-line-subway")
            static let walk = UIImage(named: "Normal/RouteCircleLine/route-circle-line-walk")
        }
        
        static let search = UIImage(named: "Normal/search")
        
        enum Sound {
            static let on = UIImage(named: "Normal/Sound/sound-on")
            static let off = UIImage(named: "Normal/Sound/sound-off")
        }
        
        static let x = UIImage(named: "Normal/x")
        
        enum XCircle {
            static let filled = UIImage(named: "Normal/XCircle/x-circle-filled")
            static let outlined = UIImage(named: "Normal/XCircle/x-circle-outlined")
        }
    }
    
    // MARK: - Color Icon
    enum Color {
        enum Airport {
            static let size26 = UIImage(named: "Color/Airport/airport-26px")
            static let size36 = UIImage(named: "Color/Airport/airport-36px")
        }
        
        enum EverLine {
            static let size26 = UIImage(named: "Color/EverLine/EverLine-26px")
            static let size36 = UIImage(named: "Color/EverLine/EverLine-36px")
        }
        
        enum Gimpo {
            static let size26 = UIImage(named: "Color/Gimpo/Gimpo-26px")
            static let size36 = UIImage(named: "Color/Gimpo/Gimpo-36px")
        }
        
        enum GTX_A {
            static let size26 = UIImage(named: "Color/GTX-A/GTX-A-26px")
            static let size36 = UIImage(named: "Color/GTX-A/GTX-A-36px")
        }
        
        enum Gyeongchun {
            static let size26 = UIImage(named: "Color/Gyeongchun/Gyeongchun-26px")
            static let size36 = UIImage(named: "Color/Gyeongchun/Gyeongchun-36px")
        }
        
        enum Gyeonggang {
            static let size26 = UIImage(named: "Color/Gyeonggang/Gyeonggang-26px")
            static let size36 = UIImage(named: "Color/Gyeonggang/Gyeonggang-36px")
        }
        
        enum GyeonguiJungang {
            static let size26 = UIImage(named: "Color/Gyeongui-jungang/Gyeongui-jungang-26px")
            static let size36 = UIImage(named: "Color/Gyeongui-jungang/Gyeongui-jungang-36px")
        }
        
        enum Incheon1 {
            static let size26 = UIImage(named: "Color/Incheon1/Incheon1-26px")
            static let size36 = UIImage(named: "Color/Incheon1/Incheon1-36px")
        }
        
        enum Incheon2 {
            static let size26 = UIImage(named: "Color/Incheon2/Incheon2-26px")
            static let size36 = UIImage(named: "Color/Incheon2/Incheon2-36px")
        }
        
        enum Seohae {
            static let size26 = UIImage(named: "Color/Seohae/Seohae-26px")
            static let size36 = UIImage(named: "Color/Seohae/Seohae-36px")
        }
        
        enum Shinbundang {
            static let size26 = UIImage(named: "Color/Shinbundang/Shinbundang-26px")
            static let size36 = UIImage(named: "Color/Shinbundang/Shinbundang-36px")
        }
        
        enum Sillim {
            static let size26 = UIImage(named: "Color/Sillim/Sillim-26px")
            static let size36 = UIImage(named: "Color/Sillim/Sillim-36px")
        }
        
        enum SuinBundang {
            static let size26 = UIImage(named: "Color/Suin-Bundang/Suin-Bundang-26px")
            static let size36 = UIImage(named: "Color/Suin-Bundang/Suin-Bundang-36px")
        }
        
        enum UiSinseol {
            static let size26 = UIImage(named: "Color/Ui-Sinseol/Ui-Sinseol-26px")
            static let size36 = UIImage(named: "Color/Ui-Sinseol/Ui-Sinseol-36px")
        }
        
        enum Uijeongbu {
            static let size26 = UIImage(named: "Color/Uijeongbu/Uijeongbu-26px")
            static let size36 = UIImage(named: "Color/Uijeongbu/Uijeongbu-36px")
        }
        
        enum Line1 {
            static let size26 = UIImage(named: "Color/Line1/line1-26px")
            static let size36 = UIImage(named: "Color/Line1/line1-36px")
        }
        
        enum Line2 {
            static let size26 = UIImage(named: "Color/Line2/line2-26px")
            static let size36 = UIImage(named: "Color/Line2/line2-36px")
        }
        
        enum Line3 {
            static let size26 = UIImage(named: "Color/Line3/line3-26px")
            static let size36 = UIImage(named: "Color/Line3/line3-36px")
        }
        
        enum Line4 {
            static let size26 = UIImage(named: "Color/Line4/line4-26px")
            static let size36 = UIImage(named: "Color/Line4/line4-36px")
        }
        
        enum Line5 {
            static let size26 = UIImage(named: "Color/Line5/line5-26px")
            static let size36 = UIImage(named: "Color/Line5/line5-36px")
        }
        
        enum Line6 {
            static let size26 = UIImage(named: "Color/Line6/line6-26px")
            static let size36 = UIImage(named: "Color/Line6/line6-36px")
        }
        
        enum Line7 {
            static let size26 = UIImage(named: "Color/Line7/line7-26px")
            static let size36 = UIImage(named: "Color/Line7/line7-36px")
        }
        
        enum Line8 {
            static let size26 = UIImage(named: "Color/Line8/line8-26px")
            static let size36 = UIImage(named: "Color/Line8/line8-36px")
        }
        
        enum Line9 {
            static let size26 = UIImage(named: "Color/Line9/line9-26px")
            static let size36 = UIImage(named: "Color/Line9/line9-36px")
        }
        
        enum Marker {
                static let start = UIImage(named: "Color/Marker/marker-start")
                static let end = UIImage(named: "Color/Marker/marker-end")
            }
    }
    
    // MARK: - Atcha 캐릭터
    enum AtchaCharacter {
            static let atcha = UIImage(named: "AtchaCharacter/Atcha")
        }
}
