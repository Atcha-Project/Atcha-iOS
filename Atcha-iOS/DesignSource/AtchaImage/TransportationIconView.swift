//
//  SubwayIconView.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import Foundation
import UIKit

let subwayIcon: [String: String] = [
    "1": "line1",
    "117": "line1",
    "118": "line1",
    
    "2": "line2",
    "10": "line2",
    "11": "line2",
    
    "3": "line3",
    
    "4": "line4",
    "119": "line4",
    
    "5": "line5",
    "6": "line6",
    "7": "line7",
    "8": "line8",
    
    "9": "line9",
    "120": "line9",
    
    "21": "Incheon1",
    "22": "Incheon2",
    
    "100": "Suin-Bundang",
    "121": "Suin-Bundang",
    
    "101": "airport",
    "124": "airport",
    
    "104": "Gyeongui-jungang",
    "122": "Gyeongui-jungang",
    
    "107": "EverLine",
    
    "108": "Gyeongchun",
    "123": "Gyeongchun",
    
    "109": "Shinbundang",
    "110": "Uijeongbu",
    "112": "Gyeonggang",
    "113": "Ui-Sinseol",
    "114": "Seohae",
    "115": "Gimpo",
    "116": "Sillim",
    "125": "GTX-A"
]

let busIcon: [String: String] = [
    "1": "regular",
    "10": "regular",
    "12": "regular",
    
    "3": "town",
    "13": "town",
    "21": "town",
    
    "2": "mainline",
    "11": "mainline",
    
    "4": "widearea",
    "6": "widearea",
    "14": "widearea",
    "15": "widearea",
    "16": "widearea",
    "22": "widearea",
    "23": "widearea",
    
    "5": "airport-bus",
    "17": "airport-bus",
]

let subwayGetOffIcon: [String: String] = [
    "1": "line1-getOff",
    "117": "line1-getOff",
    "118": "line1-getOff",
    
    "2": "line2-getOff",
    "10": "line2-getOff",
    "11": "line2-getOff",
    
    "3": "line3-getOff",
    
    "4": "line4-getOff",
    "119": "line4-getOff",
    
    "5": "line5-getOff",
    "6": "line6-getOff",
    "7": "line7-getOff",
    "8": "line8-getOff",
    
    "9": "line9-getOff",
    "120": "line9-getOff",
    
    "21": "Incheon1-getOff",
    "22": "Incheon2-getOff",
    
    "100": "Suin-Bundang-getOff",
    "121": "Suin-Bundang-getOff",
    
    "101": "airport-getOff",
    "124": "airport-getOff",
    
    "104": "Gyeongui-jungang-getOff",
    "122": "Gyeongui-jungang-getOff",
    
    "107": "EverLine-getOff",
    
    "108": "Gyeongchun-getOff",
    "123": "Gyeongchun-getOff",
    
    "109": "Shinbundang-getOff",
    "110": "Uijeongbu-getOff",
    "112": "Gyeonggang-getOff",
    "113": "Ui-Sinseol-getOff",
    "114": "Seohae-getOff",
    "115": "Gimpo-getOff",
    "116": "Sillim-getOff",
    "125": "GTX-A-getOff"
]

let busGetOffIcon: [String: String] = [
    "1": "regular-getOff",
    "10": "regular-getOff",
    "12": "regular-getOff",
    
    "3": "town-getOff",
    "13": "town-getOff",
    "21": "town-getOff",
    
    "2": "mainline-getOff",
    "11": "mainline-getOff",
    
    "4": "widearea-getOff",
    "6": "widearea-getOff",
    "14": "widearea-getOff",
    "15": "widearea-getOff",
    "16": "widearea-getOff",
    "22": "widearea-getOff",
    "23": "widearea-getOff",
    
    "5": "airport-getOff",
    "17": "airport-getOff",
]

let subwayDefaultIcon = "default-subway"
let busDefaultIcon = "default-bus"
let defaultGetOffIcon = "default-getOff"


// MARK: - 아이콘 매핑 정보
extension TransportMode {
    static let subwayIcon: [String: UIImage] = [
        "1": .line1, "117": .line1, "118": .line1,
        "2": .line2, "10": .line2, "11": .line2,
        "3": .line3,
        "4": .line4, "119": .line4,
        "5": .line5, "6": .line6, "7": .line7, "8": .line8,
        "9": .line9, "120": .line9,
        "21": .incheon1, "22": .incheon2,
        "100": .suinBundang, "121": .suinBundang,
        "101": .airport, "124": .airport,
        "104": .gyeonguiJungang, "122": .gyeonguiJungang,
        "107": .everLine,
        "108": .gyeongchun, "123": .gyeongchun,
        "109": .shinbundang,
        "110": .uijeongbu,
        "112": .gyeonggang,
        "113": .uiSinseol,
        "114": .seohae,
        "115": .gimpo,
        "116": .sillim,
        "125": .GTX_A
    ]
    
    static let subwayGetOffIcon: [String: String] = [
        "1": "line1-getOff", "117": "line1-getOff", "118": "line1-getOff",
        "2": "line2-getOff", "10": "line2-getOff", "11": "line2-getOff",
        "3": "line3-getOff",
        "4": "line4-getOff", "119": "line4-getOff",
        "5": "line5-getOff", "6": "line6-getOff", "7": "line7-getOff", "8": "line8-getOff",
        "9": "line9-getOff", "120": "line9-getOff",
        "21": "Incheon1-getOff", "22": "Incheon2-getOff",
        "100": "Suin-Bundang-getOff", "121": "Suin-Bundang-getOff",
        "101": "airport-getOff", "124": "airport-getOff",
        "104": "Gyeongui-jungang-getOff", "122": "Gyeongui-jungang-getOff",
        "107": "EverLine-getOff",
        "108": "Gyeongchun-getOff", "123": "Gyeongchun-getOff",
        "109": "Shinbundang-getOff",
        "110": "Uijeongbu-getOff",
        "112": "Gyeonggang-getOff",
        "113": "Ui-Sinseol-getOff",
        "114": "Seohae-getOff",
        "115": "Gimpo-getOff",
        "116": "Sillim-getOff",
        "125": "GTX-A-getOff"
    ]
    
    static let busIcon: [String: UIImage] = [
        "1": .regular, "10": .regular, "12": .regular,
        "3": .town, "13": .town, "21": .town,
        "2": .mainline, "11": .mainline,
        "4": .widearea, "6": .widearea, "14": .widearea,
        "15": .widearea, "16": .widearea, "22": .widearea, "23": .widearea,
        "5": .airportBus, "17": .airportBus
    ]
    
    static let busGetOffIcon: [String: String] = [
        "1": "regular-getOff", "10": "regular-getOff", "12": "regular-getOff",
        "3": "town-getOff", "13": "town-getOff", "21": "town-getOff",
        "2": "mainline-getOff", "11": "mainline-getOff",
        "4": "widearea-getOff", "6": "widearea-getOff", "14": "widearea-getOff",
        "15": "widearea-getOff", "16": "widearea-getOff",
        "22": "widearea-getOff", "23": "widearea-getOff",
        "5": "airport-getOff", "17": "airport-getOff"
    ]
    
    static let busColor: [String: UIColor] = [
        "1": .regular, "10": .regular, "12": .regular,
        "3": .town, "13": .town, "21": .town,
        "2": .mainline, "11": .mainline,
        "4": .widearea, "6": .widearea, "14": .widearea,
        "15": .widearea, "16": .widearea, "22": .widearea, "23": .widearea,
        "5": .widearea, "17": .widearea
    ]
    
    static let subwayColor: [String: UIColor] = [
        "1": .line1, "117": .line1, "118": .line1,
        "2": .line2, "10": .line2, "11": .line2,
        "3": .line3,
        "4": .line4, "119": .line4,
        "5": .line5, "6": .line6, "7": .line7, "8": .line8,
        "9": .line9, "120": .line9,
        "21": .incheon1, "22": .incheon2,
        "100": .suinBundang, "121": .suinBundang,
        "101": .airport, "124": .airport,
        "104": .gyeonguiJungang, "122": .gyeonguiJungang,
        "107": .everLine,
        "108": .gyeongchun, "123": .gyeongchun,
        "109": .shinbundang,
        "110": .uijeongbu,
        "112": .gyeonggang,
        "113": .uiSinseol,
        "114": .seohae,
        "115": .gimpo,
        "116": .sillim,
        "125": .GTX_A
    ]
}

enum BusType: String {
    case 일반, 좌석, 마을, 직행좌석, 공항
    case 간선급행, 외곽, 간선, 지선, 순환, 광역, 급행
    case 시외, 리무진, 농어촌, 시외버스, 고속버스
    case unknown
    
    init(from raw: String) {
        self = BusType(rawValue: raw) ?? .unknown
    }
    
    var icon: UIImage {
        switch self {
        case .일반, .외곽, .지선:
            return UIImage(named: "bus-regular") ?? UIImage(named: "bus-default")!
        case .좌석, .간선:
            return UIImage(named: "bus-mainline") ?? UIImage(named: "bus-default")!
        case .마을, .순환, .농어촌:
            return UIImage(named: "bus-town") ?? UIImage(named: "bus-default")!
        case .직행좌석, .간선급행, .광역, .급행, .시외, .시외버스, .고속버스:
            return UIImage(named: "bus-widearea") ?? UIImage(named: "bus-default")!
        case .공항, .리무진:
            return UIImage(named: "bus-airport") ?? UIImage(named: "bus-default")!
        case .unknown:
            return UIImage(named: "bus-default")!
        }
    }
}
