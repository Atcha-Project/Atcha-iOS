//
//  AtchaColor.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/15/25.
//

import UIKit

enum AtchaColor{
    
    // MARK: - Static
    static let black = UIColor(named: "black")!
    static let white = UIColor(named: "white")!
    
    // MARK: - Primary
    static let main = UIColor(named: "Main")!
    
    // MARK: - Gray
    static let gray100 = UIColor(named: "gray100")!
    static let gray200 = UIColor(named: "gray200")!
    static let gray300 = UIColor(named: "gray300")!
    static let gray400 = UIColor(named: "gray400")!
    static let gray500 = UIColor(named: "gray500")!
    static let gray600 = UIColor(named: "gray600")!
    static let gray700 = UIColor(named: "gray700")!
    static let gray800 = UIColor(named: "gray800")!
    static let gray910 = UIColor(named: "gray910")!
    static let gray920 = UIColor(named: "gray920")!
    static let gray930 = UIColor(named: "gray930")!
    static let gray940 = UIColor(named: "gray940")!
    static let gray950 = UIColor(named: "gray950")!
    
    // MARK: - Opacity
    static let opacity100 = UIColor(named: "opacity100")!
    static let opacity200 = UIColor(named: "opacity200")!
    static let opacity300 = UIColor(named: "opacity300")!
    
    
    // MARK: - Transportation/Bus
    enum Bus {
        static let regular = UIColor(named: "regular")!
        static let town = UIColor(named: "town")!
        static let mainline = UIColor(named: "mainline")!
        static let widearea = UIColor(named: "widearea")!
    }
    
    // MARK: - Transportation/Subway
    enum Subway {
        static let line1 = UIColor(named: "line1")!
        static let line2 = UIColor(named: "line2")!
        static let line3 = UIColor(named: "line3")!
        static let line4 = UIColor(named: "line4")!
        static let line5 = UIColor(named: "line5")!
        static let line6 = UIColor(named: "line6")!
        static let line7 = UIColor(named: "line7")!
        static let line8 = UIColor(named: "line8")!
        static let line9 = UIColor(named: "line9")!
        static let airport = UIColor(named: "Airport")!
        static let everLine = UIColor(named: "EverLine")!
        static let gimpo = UIColor(named: "Gimpo")!
        static let gtxA = UIColor(named: "GTX-A")!
        static let gyeongchun = UIColor(named: "Gyeongchun")!
        static let gyeonggang = UIColor(named: "Gyeonggang")!
        static let gyeonguiJungang = UIColor(named: "Gyeongui-jungang")!
        static let incheon1 = UIColor(named: "Incheon1")!
        static let incheon2 = UIColor(named: "Incheon2")!
        static let seohae = UIColor(named: "Seohae")!
        static let shinbundang = UIColor(named: "Shinbundang")!
        static let sillim = UIColor(named: "Sillim")!
        static let suinBundang = UIColor(named: "SuinBundang")!
        static let uiSinseol = UIColor(named: "Ui-Sinseol")!
        static let uijeongbu = UIColor(named: "Uijeongbu")!
    }
    
    // MARK: - 사용 예시
    //
    // titleLabel.textColor = AtchaColor.gray900
    // busIcon.tintColor = AtchaColor.Bus.mainline
    // lineView.backgroundColor = AtchaColor.Subway.line2
}
