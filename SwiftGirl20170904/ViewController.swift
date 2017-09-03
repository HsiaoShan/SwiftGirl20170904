//
//  ViewController.swift
//  SwiftGirl20170904
//
//  Created by HsiaoShan on 2017/9/3.
//  Copyright © 2017年 ESoZuo. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Contacts

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var text: UITextField!
    
    //國父紀念館站
    let location1 = CLLocation(latitude: 25.041390, longitude: 121.557434)
    //台北101/世貿站
    let location2 = CLLocation(latitude: 25.033053, longitude: 121.563192)
    //台北101大樓的四點
    let point1 = CLLocationCoordinate2D(latitude: 25.032914, longitude: 121.563411)
    let point2 = CLLocationCoordinate2D(latitude: 25.034965, longitude: 121.563550)
    let point3 = CLLocationCoordinate2D(latitude: 25.034955, longitude: 121.565395)
    let point4 = CLLocationCoordinate2D(latitude: 25.032943, longitude: 121.565352)
    
    let geoCoder = CLGeocoder()
    var locationManager: CLLocationManager!
    var destination: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        centerMap(coordinate: location1.coordinate)
        
        mapView.showsUserLocation = true
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        //標記預設大頭針
        let annotation = MKPointAnnotation()
        annotation.coordinate = location1.coordinate
        annotation.title = "國父紀念館站"
        annotation.subtitle = "捷運站"
        mapView.addAnnotation(annotation)
        
        //標記自訂大頭針
        let myAnnotation = BlueAnnotation(title: "台北101/世貿站", subtitle: "捷運", coordinate: location2.coordinate)
        mapView.addAnnotation(myAnnotation)
        
        //標記線條
        let line = [point1, point3]
        let polyline = MKPolyline(coordinates: line, count: line.count)
        mapView.add(polyline)
        
        //標記區塊
        let points = [point1, point2, point3, point4]
        let polygon = MKPolygon(coordinates: points, count: points.count)
        mapView.add(polygon)
        
        //路線規劃
        drawRoute(from: location1, to: location2)
        
        //取得使用定位權限
        switch CLLocationManager.authorizationStatus() {
        case .denied, .restricted:
            print("App不允許使用定位服務")
        case .notDetermined:
            //永遠
            //            locationManager.requestAlwaysAuthorization()
            //使用App期間
            locationManager.requestWhenInUseAuthorization()
        default: break
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //定位
    @IBAction func getUserLocation(_ sender: Any) {
        guard CLLocationManager.locationServicesEnabled() else {
            print("裝置無定位服務")
            return
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .denied, .restricted:
            print("App不允許使用定位服務")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default: break
        }
        
        locationManager.startUpdatingLocation()
    }
    
    //顯示輸入地址的位置
    @IBAction func search(_ sender: Any) {
        text.resignFirstResponder()
        guard let str = text.text else {
            return
        }
        //移除自訂紅色大頭針
        mapView.removeAnnotations(mapView.annotations.filter { $0 is RedAnnotation })
        
        
        guard str.range(of: "^\\d+.\\d+,\\d+.\\d+$", options: .regularExpression) != nil else {
            //地址轉換成座標
            geoCoder.geocodeAddressString(str) { (placemarks, error) in
                self.handleGeocode(placemarks, and: error, with: str)
            }
            return
        }
        let arr = str.components(separatedBy: ",")
        if arr.count == 2, let lat = Double(arr[0]), let long = Double(arr[1]) {
            print("緯度:\(lat)..經度:\(long)")
            //座標轉換成地址
            geoCoder.reverseGeocodeLocation(CLLocation(latitude: lat, longitude: long)) { (placemarks, error) in
                self.handleGeocode(placemarks, and: error, with: str)
            }
        } else {
            print("Coordinate formate invalid.")
        }
        
        
    }
    
    //顯示使用者到輸入地址的路徑
    @IBAction func route(_ sender: Any) {
        guard self.destination != nil else {
            return
        }
        getUserLocation(sender)
    }
    
    //開啟內建地圖App
    @IBAction func openMapApp(_ sender: Any) {
        //使用Map Link
//        let link = "http://maps.apple.com/ll=\(location1.coordinate.latitude),\(location1.coordinate.longitude)&daddr=\(location1.coordinate.latitude),\(location1.coordinate.longitude)&dirflg=d"
//        if let url = URL(string: link) {
//            UIApplication.shared.open(url, options: [:], completionHandler: nil)
//        }
        
        //使用MKMapItem的openInMaps
        let placemark = MKPlacemark(coordinate: location1.coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "國父紀念館站123"
        mapItem.phoneNumber = "1234567890"
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }
    
    //MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        guard let myAnnotation = annotation as? MyAnnotation else {
            let id = "PinAnnotationView"
            let pin = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            pin.annotation = annotation
            pin.canShowCallout = true
            pin.pinTintColor = MKPinAnnotationView.greenPinColor()
            return pin
        }
        
        let myView = mapView.dequeueReusableAnnotationView(withIdentifier: myAnnotation.viewId) ?? MKAnnotationView(annotation: myAnnotation, reuseIdentifier: myAnnotation.viewId)
        
        myView.image = myAnnotation.img
        myView.canShowCallout = true
        myView.annotation = myAnnotation
        
        //自定CalloutAccessoryView
        let detail = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        detail.text = myAnnotation.subtitle ?? ""
        detail.numberOfLines = 0
        detail.addConstraint(NSLayoutConstraint(item: detail, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150))
        detail.addConstraint(NSLayoutConstraint(item: detail, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200))
        detail.font = detail.font.withSize(10)
        myView.detailCalloutAccessoryView = detail
        myView.leftCalloutAccessoryView = UIImageView(image: myAnnotation.img)
        myView.rightCalloutAccessoryView = UIImageView(image: myAnnotation.img)
        
        return myView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 5
            return renderer
        } else if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3
            return renderer
        }
        
        return MKOverlayRenderer()
    }
    
    //MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("緯度:\(location.coordinate.latitude) 經度: \(location.coordinate.longitude)")
            centerMap(coordinate: location.coordinate)
            
            guard let destination = self.destination else {
                locationManager.stopUpdatingLocation()
                return
            }
            drawRoute(from: location, to: destination)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print(error)
    }
    
    //以給定的經緯度為中心顯示該範圍內地圖
    func centerMap(coordinate: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegionMake(coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
    //處理Geocode結果
    func handleGeocode(_ placemarks: [CLPlacemark]?, and error: Error?, with address: String) {
        if let error = error {
            print("handleGeocode error: \(error)")
            return
        }
        guard let placemarks = placemarks, placemarks.count > 0 else {
            print("no placemark")
            return
        }
        print("=====placemark=====\n\(String(describing: placemarks))")
        let place = placemarks[0]
        guard let location = place.location else {
            print("placemark no location")
            return
        }
        
        let title = place.name ?? ""
        var addr = address
        //iOS 11.0+
//        addr = CNPostalAddressFormatter().string(from: place.postalAddress)
        
        //iOS 5.0~10.3, 11.0 Deprecated
        if let formattedAddr = place.addressDictionary?["FormattedAddressLines"] as? NSArray, let str = formattedAddr.lastObject as? String {
            addr = str
        }
        let coordinate = location.coordinate
        addr += "\n緯度:\(coordinate.latitude)\n經度:\(coordinate.longitude)"
        self.text.text = ""
        self.mapView.addAnnotation(RedAnnotation(title: title, subtitle: addr, coordinate: coordinate))
        self.centerMap(coordinate: location.coordinate)
        self.destination = location
    }
    
    //路徑規劃
    func drawRoute(from source: CLLocation, to destination: CLLocation) {
        print("\(source)...\(destination)")
        let sourceMapItem = MKMapItem(placemark: MKPlacemark(coordinate: source.coordinate, addressDictionary: nil))
        let destinationMapItem = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate, addressDictionary: nil))
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        MKDirections(request: directionRequest).calculate {
            (response, error) -> Void in
            self.locationManager.stopUpdatingLocation()
            if let error = error {
                print("MKDirections Calculate Error: \(error)")
                return
            }
            guard let response = response else {
                return
            }
            response.routes.forEach {
                print("route:\($0.name),\($0.distance),\($0.polyline),\($0.transportType)")
                self.mapView.add($0.polyline, level: .aboveRoads)
            }
            self.centerMap(coordinate: source.coordinate)
        }
    }

}

