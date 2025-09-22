//
//  Colors.swift
//  macLlama
//
//  Created by Minyoung Yoo on 7/27/25.
//

import SwiftUI

extension Color {
    
    static var gray1: (ColorScheme) -> Color {
        { colorScheme in
            return self.returnCustomColor(scheme: colorScheme, red: (240, 230), green: (240, 230), blue: (240, 230))
        }
    }
    
    static var gray2: (ColorScheme) -> Color {
        { colorScheme in
            return self.returnCustomColor(scheme: colorScheme, red: (200, 190), green: (200, 190), blue: (200, 190))
        }
    }
    
    static var gray3: (ColorScheme) -> Color {
        { colorScheme in
            return self.returnCustomColor(scheme: colorScheme, red: (160, 150), green: (160, 150), blue: (160, 150))
        }
    }
    
    static var gray4: (ColorScheme) -> Color {
        { colorScheme in
            return self.returnCustomColor(scheme: colorScheme, red: (120, 110), green: (120, 110), blue: (120, 110))
        }
    }
    
    static var gray5: (ColorScheme) -> Color {
        { colorScheme in
            return self.returnCustomColor(scheme: colorScheme, red: (80, 70), green: (80, 70), blue: (80, 70))
        }
    }
    
    static var gray6: (ColorScheme) -> Color {
        { colorScheme in
            return self.returnCustomColor(scheme: colorScheme, red: (40, 30), green: (40, 30), blue: (40, 30))
        }
    }
    
    ///Tuple's index 0 is for light mode, 1 is for dark mode.
    static internal func returnCustomColor(scheme: ColorScheme, red: (Double, Double), green: (Double, Double), blue: (Double, Double)) -> Color {
        if scheme == .light {
            return Color(red: red.0/255, green: green.0/255, blue: blue.0/255)
        } else {
            return Color(red: red.1/255, green: green.1/255, blue: blue.1/255)
        }
    }
}
