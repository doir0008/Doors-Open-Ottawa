//
//  ViewController.swift
//  Doors Open Ottawa
//
//  Created by Ryan Doiron on 2016-12-03.
//  Copyright © 2016 doir0008@algonquinlive.com. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    var buildingID: Int?
    var jsonDictionary: [String:AnyObject]?
    
    @IBOutlet weak var buildingName: UILabel!
    @IBOutlet weak var buildingDescription: UITextView!
    @IBOutlet weak var buildingImage: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buildingHours: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadBuildingInfo(buildingID!)
    }

    func loadBuildingInfo(_ id: Int) {
        
        // define the url that we want to send to
        let buildingRequestUrl: URL = URL(string: "https://doors-open-ottawa-hurdleg.mybluemix.net/buildings/" + id.description)!
        // create the request object and pass the url
        var buildingRequest: URLRequest = URLRequest(url: buildingRequestUrl)
        // Add basic authentication in to the header
        let authString = "doir0008:password"
        let utf8String = authString.data(using: String.Encoding.utf8)
        if let base64String = utf8String?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            buildingRequest.addValue("Basic " +  base64String, forHTTPHeaderField: "Authorization")
        }
        // create the URLSession object that will make the request
        let mySession: URLSession = URLSession.shared
        // make the specific task from the session by passing in the request and the function that
        // will be used to handle the request
        let buildingTask = mySession.dataTask(with: buildingRequest, completionHandler: buildingRequestTask)
        // run the task
        buildingTask.resume()

        // Define the url that you want to send a request to for the image data
        let imageRequestUrl: URL = URL(string: "https://doors-open-ottawa-hurdleg.mybluemix.net/buildings/" + id.description + "/image")!
        // Create the request object and pass in your url
        var imageRequest: URLRequest = URLRequest(url: imageRequestUrl)
        // Add basic authentication in to the header
        if let base64String = utf8String?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            imageRequest.addValue("Basic " +  base64String, forHTTPHeaderField: "Authorization")
        }
        // Make the specific task from the session by passing in the image request, and the function that will be use to handle the image request
        let imageTask = mySession.dataTask(with: imageRequest, completionHandler: imageRequestTask )
        // Tell the image task to run
        imageTask.resume()
    }
    
    
    // handle the JSON data request which will need to recieve the data send back, the response status, and an error object to handle any errors returned
    func buildingRequestTask (_ serverData: Data?, serverResponse: URLResponse?, serverError: Error?) -> Void{
        
        // If the error object has been set then an error occured
        if serverError != nil {
            // Send en empty string as the data, and the error to the callback function
            self.buildingCallback("", error: serverError?.localizedDescription)
        }else{
            // If no error was generated then the server responce has been recieved
            // Stringify the response data
            let result = NSString(data: serverData!, encoding: String.Encoding.utf8.rawValue)!
            // Send the response string data, and nil for the error tot he callback
            self.buildingCallback(result as String, error: nil)
        }
    }
    
    
    // Define the JSON data callback function to be triggered when the JSON data response is received
    func buildingCallback(_ responseString: String, error: String?) {
        
        // If the server request generated an error then handle it
        if error != nil {
            print("ERROR is " + error!)
        }else{
            // Else take the data recieved from the server and process it
            print("DATA is " + responseString)
            
            // Take the response string and turn it back into raw data
            if let myData: Data = responseString.data(using: String.Encoding.utf8) {
                do {
                    // Try to convert response data into a dictionary to be saved into the optional dictionary
                    jsonDictionary = try JSONSerialization.jsonObject(with: myData, options: []) as? [String:AnyObject]
                    
                } catch let convertError as NSError {
                    // If it fails catch the error info
                    print(convertError.description)
                }
            }
            
            // Because this callback is run on a secondary thread, ui updates must be done on the main thread by calling the dispatch_async method
            DispatchQueue.main.async {
                
                // Cast the dictionary values from any objects to the appropriate type and set the UI outlets with the data
                self.buildingName.text = self.jsonDictionary!["name"] as? String
                self.buildingDescription.text = self.jsonDictionary!["description"] as? String
                
                // handle the open_hours seperately by looping through an array and appending it to the UI outlet
                if let openHours = self.jsonDictionary {
                    let array = openHours["open_hours"] as? [[String:String]]
                    for i in array! {
                        let dictionaryObj = i
                        self.buildingHours.text?.append(dictionaryObj["date"]! + "\n")
                    }
                }
                
                // Grab the building address info and setup the Geocoder for the map
                let address = self.jsonDictionary!["address"] as? String
                let geocodedAddress = CLGeocoder()
                geocodedAddress.geocodeAddressString(address! + ", Ottawa, ON", completionHandler: self.placeMarkerHandler)
            }
        }
    }
    
    // Called by the geocoder, places a marker on the map based on the building address @ 500x500meters
    func placeMarkerHandler (placeMarkers: [CLPlacemark]?, error: Error?) {
        if let firstMarker = placeMarkers?[0] {
            let marker = MKPlacemark(placemark: firstMarker)
            self.mapView?.addAnnotation(marker)
            let myRegion = MKCoordinateRegionMakeWithDistance(marker.coordinate, 500, 500)
            self.mapView?.setRegion(myRegion, animated: false)
        }
    }
    
    // handle the image request which will need to recieve the data send back, the response status, and an error object to handle any errors returned
    func imageRequestTask (_ serverData: Data?, serverResponse: URLResponse?, serverError: Error?) -> Void{
        
        // If the error object has been set then an error occured
        if serverError != nil {
            // Send en empty string as the data, and the error to the callback function
            print("ERROR is " + serverError!.localizedDescription)
        }else{
            // Else take the image data recieved from the server and process it
            // Because this callback is run on a secondary thread, ui updates must be done on the main thread by calling the dispatch_async method
            DispatchQueue.main.async {
                // Set the ImageView's image by converting the data object into a UIImage
                self.buildingImage.image = UIImage(data: serverData!)
            }
        }
    }
}

