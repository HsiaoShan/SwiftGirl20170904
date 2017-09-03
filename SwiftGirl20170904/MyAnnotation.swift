//
//  MyAnnotation.swift
//  MapDemo
//
//  Created by HsiaoShan on 2017/3/2.
//  Copyright © 2017年 ESoZuo. All rights reserved.
//

import UIKit
import MapKit

@objc protocol MyAnnotation: MKAnnotation {
    var viewId: String { get }
    var img: UIImage { get }
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D)
}

class BlueAnnotation: NSObject, MyAnnotation {
    var viewId = "BlueAnnotationView"
    var img = #imageLiteral(resourceName: "blueplaceholder")
    var coordinate:CLLocationCoordinate2D //必要
    var title: String?
    var subtitle: String?
    
    required init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        super.init()
    }
}

class RedAnnotation: NSObject, MyAnnotation {
    var viewId = "RedAnnotationView"
    var img = #imageLiteral(resourceName: "redplaceholder")
    var coordinate: CLLocationCoordinate2D //必要
    var title: String?
    var subtitle: String?
    
    required init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
    
}
