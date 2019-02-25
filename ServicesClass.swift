  //
//  ServicesClass.swift
//  MedicalApp
//
//  Created by Gaurav Varshney on 05/12/16.
//  Copyright © 2016 Flexsin. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
//import SwiftyJSON

protocol ServicesClassDelegate{
    
    func dataReceivedFromService(JSON:AnyObject, requestName : String, errorCode:Int , eroorMessage:String)
    func dataFailure(error:String, requestName:String , errorCode :Int)
    
}

class ServicesClass : NSObject
{
    
    var delegate : ServicesClassDelegate!
    
    typealias CompletionBlock = (_ result : Dictionary<String, Any>?, _ error : Error?) -> Void
    typealias CompletionDataBlock = (_ result : Data?) -> Void
    typealias ProgressBlock = (_ progressData : Progress) -> Void
    
    //MARK: Shared Instance
    
    static let sharedInstance : ServicesClass = {
        let instance = ServicesClass()
        return instance
    }()
    
    static func getDataFromURlWith(url:String,parameters:Dictionary<String, Any>?, requestName:String,completionBlock : @escaping CompletionBlock)
    {
        
        print("net available")
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseJSON { (response) in
            
            switch(response.result) {
            case .success(_):
                if let data = response.result.value
                {
                    //print(response.result.value!)
                    //print(data)
                    
                    var dic : Dictionary<String,Any> = Dictionary()
                    
                    if data as? Array<Dictionary<String,Any>> != nil
                    {
                        dic["data"] = data as? Array<Dictionary<String,Any>>
                        completionBlock(dic,nil)
                    }
                    else
                    {
                        completionBlock(data as? Dictionary<String,Any>,nil)
                    }
                }
                
                break
                
            case .failure(_):
                print(response.result.error!)
                completionBlock(nil ,response.result.error!)
                break
                
            }
        }
        
    }
    
    static func postDataFromURL(url:String,parameters:Dictionary<String, Any>?, requestName:String,completionBlock : @escaping CompletionBlock)
    {
        print("net available")
        //application/json 
        //multipart/form-data
//        let hders = [
//            
//            "content-type": "multipart/form-data"
//        }
                    let hders = [
                       "Content-Type": "application/x-www-form-urlencoded"
                    ]
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: hders).responseJSON { response in
            
            switch(response.result) {
            case .success(_):
                if let dict = response.result.value
                {
                    let data = dict as! Dictionary<String,Any>
                    
                    // print(response.result.value!)
                    // print(data)
                    completionBlock(data as Dictionary,nil)
                }
                
                break
                
            case .failure(let error):
                print((error as NSError).localizedDescription)
                completionBlock(nil ,response.result.error!)
                print("\(error.localizedDescription)")
                
                break
                
            }
        }
    }
    
   static func downloadFile(strUrl : String, progressBlock : @escaping ProgressBlock, completionBlock : @escaping CompletionDataBlock)
    {
        let utilityQueue = DispatchQueue.global(qos: .utility)
        
        Alamofire.request(URL.init(string: strUrl)!).downloadProgress(queue: utilityQueue, closure: { (progress) in
            
            progressBlock(progress)
        })
            .responseData { (response) in
            
            if let data = response.result.value
            {
                completionBlock(data)
            }
            else
            {
                completionBlock(nil)
            }
        }

    }
    
   static func uploadImage(url:String,parameters:Dictionary<String, Any>,requestName:String,img:UIImage,completionBlock : @escaping CompletionBlock)
    {
        //        if (UIApplication.shared.delegate as! AppDelegate).reachability.currentReachabilityStatus().rawValue != 0
        //        {
        print("net available")
        
        //            let hders = [
        //               "Content-Type": "application/json"
        //            ]
        
        Alamofire.upload(multipartFormData:
            {
                MultipartFormData in
                
                let imageData = UIImageJPEGRepresentation(img , 0.8)!
                if url == APIConstants.update_profile{
                    MultipartFormData.append(imageData, withName: "profile_pic" , fileName:"file.jpg", mimeType:"image/jpeg")
                }else{
                MultipartFormData.append(imageData, withName: "profile_pic" , fileName:"file.jpg", mimeType:"image/jpeg")
                }
                
                for (key, value) in parameters
                {
                    MultipartFormData.append((value as! String).data(using: String.Encoding.utf8)!, withName: key)
                    
                }
                
        }, to:url,method:.post,headers:["content-type" : "application/json"], encodingCompletion: {
            encodingResult in
            
            switch encodingResult
            {
            case .success(let upload, _, _):
                print("image uploaded")
                upload.responseJSON { response in
                    
                    print(response.request!)  // original URL request
                    print(response.response!) // URL response
                    print(response.data!)     // server data
                    print(response.result)   // result of response serialization
                    
                    if let JSON = response.result.value
                    {
                        print("JSON: \(JSON)")
                    }
                    
                    if let dict = response.result.value
                    {
                        let data = dict as! Dictionary<String,Any>
                        
                        print(response.result.value!)
                        print(data)
                        completionBlock(data as Dictionary,nil)
                    }
                }
                break
                
            case .failure(let encodingError):
                completionBlock(nil ,encodingError)
                break
            }
        } )
    }
    
    
    //            Alamofire.request(requestType,url, parameters: parameters as? [String : AnyObject])
    //                .responseJSON { response in
    //                    if let JSON = response.result.value {
    //                        print("Success with JSON:getFilesJSON:->> \(JSON)")
    //
    //                        // writing this condition beacuse API request of User/Profile is not in correct format with (JSON["logs"] key)
    //
    ////                        if(requestName == GETPROFILE_URL)
    ////                        {
    ////                            if  let delegate = self.delegate               {
    ////                                delegate.dataReceivedFromService(JSON, requestName: requestName , errorCode:1000000, eroorMessage: "" )
    ////
    ////                            }
    ////
    ////
    ////                        }
    //
    ////                        else {
    //                            let errorArray = JSON["logs"] as! NSArray
    //                            let errorCode = errorArray.objectAtIndex(0).valueForKey("code") as! Int
    //                            let errorMessage = errorArray.objectAtIndex(0).valueForKey("message") as! String
    //                            if errorCode == 200 {
    //
    //                                if  let delegate = self.delegate  {
    //                                    delegate.dataReceivedFromService(JSON, requestName: requestName, errorCode: errorCode , eroorMessage:errorMessage)
    //
    //                                }
    //                            }
    //                            else{
    //
    //                                switch response.result
    //                                {
    //                                case .Success(let JSON):
    //                                    if  let delegate = self.delegate{
    //                                        delegate.dataReceivedFromService(JSON, requestName: requestName , errorCode: errorCode, eroorMessage: errorMessage)
    //
    //                                    }
    //
    //                                    print("Success with JSON: \(JSON)")
    //                                case .Failure(let error):
    //                                    print((error as NSError).localizedDescription)
    //                                    let strError = error.localizedDescription
    //                                    print("\(error.localizedDescription)")
    //                                    if  let delegate = self.delegate{
    //                                        delegate.dataFailure(strError, requestName: requestName, errorCode : errorCode)
    //                                    }
    //
    //                                }
    //                            }
    //
    //
    //                  //      }
    //
    //
    //                    }
    //
    //            }
    //
    //        }
    //        else
    //        {
    //
    //            if  let delegate = self.delegate
    //            {
    //                delegate.dataFailure("Sorry, It seems your internet connection is not working.Please try again.", requestName: requestName , errorCode : 190909)
    //            }
    //
    //        }
    //
    //    }
    
}
