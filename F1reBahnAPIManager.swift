//
//  OpenBahnApiManager.swift
//  Connexions
//
//  Created by Alex Deutsch on 20.09.14.
//  Copyright (c) 2014 Alexander Deutsch. All rights reserved.
//

import Foundation

let kFireMBahnBaseURL = "http://mobile.bahn.de/bin/mobil/query.exe/"
let kFireRABahnBaseURL = "http://reiseauskunft.bahn.de/bin/ajax-getstop.exe/dn"

typealias OperationCallback = (success: Bool, result: AnyObject?) -> ()

class F1reBahnAPIManager {
    var authorizationCallback: OperationCallback?
    var operationQueue: NSOperationQueue
    var callbackQueue: dispatch_queue_t?
    
    init(){
        operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 7;
        callbackQueue = dispatch_get_main_queue();
    }
    
    
    /*
    getStation retrieves Stations
    @param stationName  name of the station to search for
    */
    
    func getStation(stationName : String, callback: OperationCallback) -> NSOperation
    {
        let parameters: Dictionary <String, String> = [
            "start" : "1",
            "tpl" : "sls",
            "REQ0JourneyStopsB" : "12",
            "REQ0JourneyStopsS0A" : "1",
            "getstop" : "1",
            "noSession" : "yes",
            "iER" : "yes",
            "S" : stationName,
            "js" : "true"]
        
        let operation : NSOperation = self.sendRequest(kFireRABahnBaseURL, parameters: parameters, httpMethod: "GET", callback: {
            (success, result) -> () in

            var jsonString : NSString = result as! String
            
            var error : NSError?
            
            // Apparently necessary for making the transforming the string to a valid json string
            jsonString = jsonString.stringByReplacingOccurrencesOfString("SLs.sls=", withString: "")
            jsonString = jsonString.stringByReplacingOccurrencesOfString(";SLs.showSuggestion();", withString: "")
            
            // Transform back into NSData and create json Object
            let jsonData : NSData = jsonString.dataUsingEncoding(NSUTF8StringEncoding)!
            let jsonObject : AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.AllowFragments, error: &error)

            if(jsonObject != nil)
            {
                callback(success: true, result: jsonObject)
            }
            else {
                callback(success: false, result: error)
            }
        })
        
        return operation
    }
    
    func getConnections(start: String, destination: String, date: String, time: String, callback: OperationCallback) -> NSOperation {
        let parameters: Dictionary <String, String> = [
            "REQ0JourneyStopsS0G":start,
            "REQ0JourneyStopsZ0G":destination,
            "REQ0JourneyStopsS0A":"1",
            "queryPageDisplayed":"yes",
            "REQ0JourneyStopsZ0A":"1",
            "REQ0JourneyDate":date,
            "REQ0JourneyTime":time,
            "REQ0HafasSearchForw":"0",
            "existOptimizePrice":"1",
            "REQ0HafasOptimize1":"0:1",
            "REQ0Tariff_TravellerType.1":"E",
            "REQ0Tariff_TravellerReductionClass.1":"0",
            "REQ0JourneyStopsS0ID":"",
            "REQ0JourneyStopsZ0ID":"",
            "start":"",
            "sotRequest:":"1",
            "use_realtime_filter":"1",
            "REQ0Tariff_Class":"2",
            "n":"1"
        ]
        let operation = self.sendRequest(kFireMBahnBaseURL + "dox", parameters: parameters, httpMethod: "GET", callback: { (success, result) -> () in
            if(success) {
                let html = result as! String
                let htmlDocument : HTMLDocument = HTMLDocument(string: html)
                let journeyTimes = NSMutableDictionary()
                
                for node in htmlDocument.nodesMatchingSelector("a")
                {
                    var error: NSError?
                    
                    let htmlNode : HTMLNode = node as! HTMLNode
                    let regex = NSRegularExpression(pattern: "\\d\\d:\\d\\d\\d\\d:\\d\\d", options: .CaseInsensitive, error: &error)
                    
                    // Check if the html node is matching a journey time
                    
                    if  regex?.matchesInString(htmlNode.textContent, options: nil, range: NSMakeRange(0, count(htmlNode.textContent))).count > 0
                    {
                        let stringIndex : String.Index = advance(htmlNode.textContent.startIndex,5)
                        let from = htmlNode.textContent.substringToIndex(stringIndex)
                        let to = htmlNode.textContent.substringFromIndex(stringIndex)
                        journeyTimes[from] = to
                    }
                    
                }
                callback(success: true, result: journeyTimes)
            }
            else {
                callback(success: false, result: nil)
                println("error retrieving connections")
            }
            
        })
        return operation
    }
    
    private func sendRequest(path: String, parameters: Dictionary <String, String>, httpMethod: String, callback:OperationCallback) -> NSOperation{
        let url : NSURL = self.constructURL(path, parameters: parameters)
        println("URL : \(url.absoluteString)")
        var request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = httpMethod
        let operation = Operation(request: request, callbackBlock: callback, callbackQueue: self.callbackQueue!)
        self.operationQueue.addOperation(operation)
        return operation
    }
    
    private func constructURL(path: String, parameters: Dictionary <String, String>) -> NSURL {
        var parametersString = path
        var firstItem = true
        for key in parameters.keys {
            let string = parameters[key]!
            let mark = (firstItem ? "?" : "&")
            parametersString += "\(mark)\(key)=\(string)"
            firstItem = false
        }
        println("parameterstring = \(parametersString)")
        let escapedString : NSString = parametersString.stringByAddingPercentEscapesUsingEncoding(NSISOLatin1StringEncoding)!
        return NSURL(string: escapedString as String)!
    }
}

class Operation: NSOperation {
    var callbackBlock: OperationCallback
    var request: NSURLRequest
    var callbackQueue: dispatch_queue_t
    
    init(request: NSURLRequest, callbackBlock: OperationCallback, callbackQueue: dispatch_queue_t) {
        self.request = request
        self.callbackBlock = callbackBlock
        self.callbackQueue = callbackQueue
    }
    
    override func main() {
        var error: NSError?
        var result: AnyObject?
        var response: NSURLResponse?
        
        var recievedData: NSData? = NSURLConnection.sendSynchronousRequest(self.request, returningResponse: &response, error: &error)
        
        if self.cancelled {return}
        
        if (recievedData != nil){

            result = NSString(data: recievedData! as NSData, encoding: NSISOLatin1StringEncoding)
            
            if result != nil {
                if result!.isKindOfClass(NSClassFromString("NSError")){
                    error = result as? NSError
                }
            }
            
            if self.cancelled {return}
            
            dispatch_async(self.callbackQueue, {
                if ((error) != nil) {
                    self.callbackBlock(success: false, result: error!);
                } else {
                    self.callbackBlock(success: true, result: result);
                }
            })
        }
        else {
            println("ERROR NO DATA RECEIVED")
        }
        
         var concurrent:Bool {get {return true}}

}

}