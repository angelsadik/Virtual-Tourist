//
//  Flicker.swift
//  Virtual Tourist
//
//  Created by Malak Sadik on 31/01/2019.
//  Copyright © 2019 Malak Sadik. All rights reserved.
//


import Foundation
import UIKit
import MapKit

class Flickr {
    
    static let shared = Flickr()
    
    func bboxString(lat: Double , long: Double) -> String {
        // ensure bounding box is bounded by minimum and maximums (location coordinates range)
        
        let minimumLon = max(long - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(lat - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(long + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(lat + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme //https
        components.host = Constants.Flickr.APIHost //api.flicker.com
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    func getFlickrImagesByLatLon(pin: Pin, coordinate: CLLocationCoordinate2D, completion: @escaping (_ success: Bool,_ msg:String, _ flickrImagesURLString:[[String:Any]]?) -> Void) {
        //print("start")
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(lat: coordinate.longitude , long: coordinate.longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        // create session and request
        let session = URLSession.shared
        //client send a HTTP request to the server (flicker API) using the method 'flicker.galleries.getPhotos
        let request = URLRequest(url: flickrURLFromParameters(methodParameters as [String : AnyObject]))
        //method call to create the url from parameters
        //print(request)
        // create network request
        var msg = ""
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            //debugPrint("response \(response)")
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                msg = "There was an error with your request: \(error)"
                completion(false,msg, nil)
                return
            }
            
            // guard for successful http response
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                msg = "Your request returned a status code other than 2xx!"
                completion(false,msg, nil)
                return
            }
            
            // guard if any data is returned or not
            guard let data = data else {
                msg = "No data was returned by the API"
                completion(false,msg, nil)
                return
            }
            
            // the server responds with JSON containing infromation about the photos in gallery (data)
            //client stores the JSON by
            // parse the data (serialization)
            let parsedResult: [String:AnyObject]!
            do {
                // JSONSerialization converts JSON to swift objects (arrays,dictionary,..)
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject] // as a dictionary
            } catch {
                msg = "Could not parse the data as JSON: '\(data)'"
                completion(false, msg, nil)
                return
            }
            
            // read the JSON results from the parsedResult (top-down the json tree ex flicker starts with phtos{..})
            /* GUARD: Is "photos" key in our result? */
            //convert results into dictionary
            //print ("parsedResult \(parsedResult)")
            
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                msg = "Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)"
                completion(false, msg, nil)
                return
            }
            //print (photosDictionary)
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                msg = "Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)"
                completion(false, msg, nil)
                return
            }
            // pick a random page! or url of an image in the gallery
            //since the max # of images flicker will return is 4000 with 100 image per page then, the query request should be within 4000/100= 40 page
            //Because we're not selecting the per_page parameter in your request, Flickr takes the default one, 250 photos per page. So, the correct value here would be, 4000/250 = 16
            let pageLimit = min(totalPages, 16)
            
            //generate random# in that range
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            //client requests an image data using the page number or url
            // a second request within the random page number
            // add the page to the method's parameters before building the url
            var methodParametersWithPageNumber = methodParameters as [String : AnyObject]
            methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = randomPage as AnyObject
            
            //build the url
            let request = URLRequest(url: self.flickrURLFromParameters(methodParametersWithPageNumber) )//using the Constant struct to create the methodparameters of the API (line)
            
            // create network request
            let task = session.dataTask(with: request) { (data, response, error) in
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    msg = "There was an error with your request: \(error)"
                    completion(false, msg, nil)
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    msg = "Your request returned a status code other than 2xx!"
                    completion(false, msg, nil)
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    msg = "No data was returned by the request!"
                    completion(false, msg, nil)
                    return
                }
                
                // parse the data
                let parsedResult: [String:AnyObject]!
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                } catch {
                    msg = "Could not parse the data as JSON: '\(data)'"
                    completion(false, msg, nil)
                    return
                }
                
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                    msg = "Flickr API returned an error. See error code and message in \(parsedResult)"
                    completion(false, msg, nil)
                    return
                }
                
                /* GUARD: Is the "photos" key in our result? */
                guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    msg = "Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)"
                    completion(false, msg, nil)
                    return
                }
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    msg = "Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)"
                    completion(false, msg, nil)
                    return
                }
                
                // guard if photos are present
                guard(photosArray.count > 0) else {
                    msg = "No photos Found!.Search again"
                    completion(false, msg, nil)
                    return
                }
                
                //make array of photos url string
                var flickrImages:[[String : Any]] = []
                // DispatchQueue.main.async(execute: { () -> Void in
                
                // Use the photoArray and point it to the pin
                for photo in photosArray {
                    
                    if let flickrImage = photo as? [String:Any],
                        let id = flickrImage["id"] as? String,
                        let secret = flickrImage["secret"] as? String,
                        let server = flickrImage["server"] as? String,
                        let farm = flickrImage["farm"] as? Int,
                        let title = flickrImage["title"] as? String
                        {
                            let dict : [String:Any] = ["urlString":"https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_q.jpg",
                                                       "title":"\(title)"]
                        
                            flickrImages.append(dict as! [String : String])
                            //print("flickrImagesURLString \(flickrImagesURLString)")
                    
                        }
                    
                }
                
                completion(true,"", flickrImages)
                
            }
            
            task.resume()
            
        }
        // start the task!
        task.resume()
        
    }
    
}

