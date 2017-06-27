//
//  TableViewController.swift
//  Doors Open Ottawa
//
//  Created by Ryan Doiron on 2016-12-03.
//  Copyright © 2016 doir0008@algonquinlive.com. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    @IBOutlet var myTableView: UITableView!
    
    var jsonObject: [String:[[String:AnyObject]]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // define the url that we want to send to
        let requestUrl: URL = URL(string: "https://doors-open-ottawa-hurdleg.mybluemix.net/buildings")!
        // create the request object and pass the url
        var myRequest: URLRequest = URLRequest(url: requestUrl)
        // Add basic authentication in to the header
        let authString = "doir0008:password"
        let utf8String = authString.data(using: String.Encoding.utf8)
        if let base64String = utf8String?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            myRequest.addValue("Basic " +  base64String, forHTTPHeaderField: "Authorization")
        }
        // create the URLSession object that will make the request
        let mySession: URLSession = URLSession.shared
        // make the specific task from the session by passing in the request and the function that
        // will be used to handle the request
        let myTask = mySession.dataTask(with: myRequest, completionHandler: requestTask)
        // run the task
        myTask.resume()
    }
    
    // function that will handle the request, receives the data sent back, the error object and handle any errors
    func requestTask (serverData: Data?, serverResponse: URLResponse?, serverError: Error?) -> Void{
        // if the error object has been set then an error occurred
        if serverError != nil {
            // send an empty string as the data and the error to the callback func
            self.myCallback(responseString: "", error: serverError?.localizedDescription)
        } else {
            // if no error, stringify the data and send it to the callback func
            let result = NSString(data: serverData!, encoding: String.Encoding.utf8.rawValue)!
            self.myCallback(responseString: result as String, error: nil)
        }
    }
    
    // callback func to be triggered when response is received
    func myCallback (responseString: String, error: String?) {
        // if the server request generated an error then we handle it
        if error != nil {
            print("ERROR is " + error!)
        } else {
            // else we process the data and encapsulate it in the array
            print("DATA is " + responseString)
            if let myData: Data = responseString.data(using: .utf8) {
                do {
                    jsonObject = try JSONSerialization.jsonObject(with: myData, options: []) as? [String:[[String:AnyObject]]]
                } catch let convertError {
                    print(convertError.localizedDescription)
                }
            }
        }
        // update the table data - this must be done because the callback runs on a secondary thread
        // only the main thread can update the UI and DispatchQueue method will do that
        DispatchQueue.main.async {
            self.myTableView.reloadData()
        }
    }
    
    // return the array count as numberOfRows else return 0
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cellCount = 0
        // Use optional binding to return the count of the jsonObject array
        if let jsonObj = jsonObject{
            if let jsonArray = jsonObj["buildings"] as [[String:AnyObject]]? {
                cellCount = jsonArray.count
            }
        }
        return cellCount
    }
    
    // Set the cell.text to the data
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath)
        
        // Use optional binding to access the JSON dictionary if it exists
        if let jsonObj = jsonObject{
            // Use optional binding to get the array of values from the JSON object
            if let jsonArray = jsonObj["buildings"] as [[String:AnyObject]]? {
                // For the current tableCell row get the corresponding building's dictionary of info
                let dictionaryRow = jsonArray[indexPath.row] as [String:AnyObject]
                // Get the name and address for the current building
                let name = dictionaryRow["name"] as? String
                let address = dictionaryRow["address"] as? String
                // Add the name and overview to the cell's textLabel
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = name! + "\n" + address!
            }
        }
        return cell
    }
    
    // prepare the segue to transition to the next view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowBuilding" {
            let NextViewController = segue.destination as? ViewController
            guard let cell = sender as? UITableViewCell,
                let indexPath = tableView.indexPath(for: cell) else {
                    return
            }
            // Pass the event object over to the viewcontroller
            NextViewController?.buildingID = tableView.indexPath(for: cell)!.row
        }
    }

}
