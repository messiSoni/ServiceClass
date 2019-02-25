//
//  HomeViewController.swift
//  Como App
//
//  Created by Ankit Goel on 02/04/18.
//

import UIKit
import MBProgressHUD
import GooglePlaces
import GoogleMaps
import CoreLocation
import SVPullToRefresh

// MARK: -***** Set SearchFiled PlaceHolder Method Method -*****
extension UISearchBar
{
    func setSearchPlaceholderTextColorToo(color: UIColor)
    {
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = color
        let textFieldInsideSearchBarLabel = textFieldInsideSearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideSearchBarLabel?.textColor = color
    }
}


extension UISearchBar {
    
    func change1(textFont : UIFont?) {
        
        for view : UIView in (self.subviews[0]).subviews {
            
            if let textField = view as? UITextField {
                textField.font = textFont
            }
        }
    } }

struct Platform {
    
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
    
}

class HomeViewController: UIViewController, CLLocationManagerDelegate, locationDelegateToHome, filterDelegate, delegate,UISearchBarDelegate {
    
    //MARK:- @IBOutlets
    @IBOutlet var collectionViewHome: UICollectionView!
    @IBOutlet var tblviewHome: UITableView!
    @IBOutlet var lblLocation: UILabel!
    @IBOutlet var btnForSearch: UIButton!
    @IBOutlet var collectionviewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var btnSeallToprated: UIButton!
    @IBOutlet var lblTopRatedUser: UILabel!
    @IBOutlet var lblForNotificationCount: UILabel!
   
    //MARK:- VariablesDeclarations
    var isFromHome : Bool = true
    var categoryArray = ["Sally Mathers","John Cleese","Hettie Diaz","Shawn Garfield","Ari Mendes"]
    var userID : String = ""
    var arrHomeTask : Array<HomeViewModel> = []
    var arrTopUser : Array<TopRatedViewModelClass> = []
    var strImagePath : String = ""
    var refreshControl: UIRefreshControl!
    var isPullToRefresh = Bool()
    var myId : String = ""
    let geoCoder = CLGeocoder()
    var locationAddress : String = String()
    var locationTypeByUser : String = String()
    var arrLocationDetail  = [String]()
    var locationManager = CLLocationManager()
    var isSendToSelectLocation : Bool = true
    var dataFromLocation : Array = [String]()
    var address : String = String()
    var dataFromSelectLocationManual : Array = [String]()
    var lat : String = String()
    var long : String = String()
    var dataLocation = String()
    var isCheckAPICall = false
    var currentLocation: CLLocation!
    var latitude = Double()
    var longitude = Double()
    var pageNo : Int = 0
    var taskId : String = String()
    var task_end_date : String = String()
    var dicDataComeFromFilter : Dictionary = [String : Any]()
    var isFromResetButton : Bool = Bool()
    var isFromTaskDetail : Bool = Bool()
    
    var latVlaue : String = String()
    var longValue : String = String()
    var noDataLabel = UILabel()
    var strForLocationVal = String()
    var isCheckCurrentLocationCall = false
    var isCheckSelectAllBtnClick = false
    
    //MARK:- ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.btnSeallToprated.isHidden = true
        self.lblTopRatedUser.isHidden = true
        self.collectionviewHeightConstraint.constant = 0
        collectionViewHome.layoutIfNeeded()
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        
        if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            
        }
        refreshControl = UIRefreshControl()
        //refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
        tblviewHome.addSubview(refreshControl) // not required when using UITableViewController
        
        tblviewHome.addInfiniteScrolling {
            if !self.refreshControl.isRefreshing{
                self.homeTaskAPI()
            }else{
                self.tblviewHome.infiniteScrollingView.stopAnimating()
            }
        }
        
        //updateLocationAPI()
        NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.getNotificationValue), name: NSNotification.Name(rawValue: "CallHomeViewOnNotificationTap"), object: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        setUI()
        getLatLong()
        self.tabBarController?.tabBar.isHidden = false
         NotificationCenter.default.addObserver(self, selector: #selector(HomeViewController.upadteMessageCountValue), name: NSNotification.Name(rawValue: "UpdateMessageCount"), object: nil)
    }
    @objc func upadteMessageCountValue(){
        notificationUnreadCountAPI()
    }
     //MARK:- Setup Initial
    func setUI(){
        lblForNotificationCount.isHidden = true
        lblForNotificationCount.text = ""
        lblForNotificationCount.layer.cornerRadius = lblForNotificationCount.frame.size.width / 2
        lblForNotificationCount.clipsToBounds = true
        if isFromTaskDetail{
            homeTaskAPI()
        }
        //homeTaskAPI()
        pageNo = 0
        self.tblviewHome.layer.cornerRadius = 10.0
    }
    
    // -*****  On Notification Tap Redirect In Transaction Details -*****
    func redirectOnNotification() {
        if UserDefaults.standard.value(forKey: "IsCheckSelectedSegmentIndex") != nil
        {
            let selectedIndex = UserDefaults.standard.value(forKey: "IsCheckSelectedSegmentIndex") as! String
            if selectedIndex == "5"{
                //let defaults = UserDefaults.standard
                //defaults.removeObject(forKey:"IsCheckSelectedSegmentIndex")
                let vc = self.storyboard?.instantiateViewController(withIdentifier:  "MyProfileViewController") as! MyProfileViewController
                self.navigationController?.pushViewController(vc, animated: true)
            }
            else{
            let vc = self.storyboard?.instantiateViewController(withIdentifier:  "MyTaskParentViewController") as! MyTaskParentViewController
            self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    @objc func getNotificationValue() {
        redirectOnNotification()
    }
    //MARK:- CustomMethods
    @objc func btnAcceptTask(sender : UIButton){
        
        let row = sender.tag
        taskId = arrHomeTask[row].task_id
        task_end_date = arrHomeTask[row].task_end_date
        acceptTaskAPI(taskId : taskId , task_end_date : task_end_date )
        arrHomeTask.remove(at: row)
        let cell = tblviewHome.cellForRow(at: IndexPath.init(row: row, section: 0))
        let indexPath = tblviewHome.indexPath(for: cell!)
        tblviewHome.deleteRows(at: [indexPath!], with: .left)
        tblviewHome.reloadData()
    }
    @objc func btnSkipAction(sender : UIButton){
        
        let row = sender.tag
        taskId = arrHomeTask[row].task_id
        skipAPI(taskId : taskId)
        arrHomeTask.remove(at: row)
        let cell = tblviewHome.cellForRow(at: IndexPath.init(row: row, section: 0))
        let indexPath = tblviewHome.indexPath(for: cell!)
        tblviewHome.deleteRows(at: [indexPath!], with: .left)
        tblviewHome.reloadData()
    }
    
    func getLatLong(){
        
        let address = dataLocation
        // Geocode Address String
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            // Process Response
            self.processResponse(withPlacemarks: placemarks, error: error)
            
        }
        
    }
    
    private func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) {
        // Update View
//        if Platform.isSimulator {
//            //lat = "28.618467"
//           // long = "77.390704"
//            self.updateLocationAPI()
//        }
//        else{
        
        if let error = error {
            print("Unable to Forward Geocode Address (\(error))")
            // locationLabel.text = "Unable to Find Location for Address"
            
        } else {
            var location: CLLocation?
            
            if let placemarks = placemarks, placemarks.count > 0 {
                location = placemarks.first?.location
            }
            
            if let location = location {
                let coordinate = location.coordinate
                print("\(coordinate.latitude), \(coordinate.longitude)")
                lat = String(coordinate.latitude)
                long = String(coordinate.longitude)
                // locationLabel.text = "\(coordinate.latitude), \(coordinate.longitude)"
            } else {
                //  locationLabel.text = "No Matching Location Found"
            }
            
            self.updateLocationAPI()
        }
        //}
    }
    //MARK:- CustomDelegate
    //TaskDetailScreen
    
    func dataReceiveFromTaskDetail(isFromTaskDetail: Bool) {
        self.isFromTaskDetail = isFromTaskDetail
    }
    
    func dataPassBoolToHome(data : Bool){
        isCheckSelectAllBtnClick = true
        pageNo = 0
        homeTaskAPI()
    }
    //FromLocationScreen
    func dataPassToHome(data: Array<String>, address : String) {
        isCheckCurrentLocationCall = true
        dataFromLocation = data
        self.address = address
        
        if dataFromLocation.count > 0{
            lblLocation.text = (dataFromLocation as NSArray).componentsJoined(by: " ,")
            self.dataLocation.removeAll()
            let trimmedString = lblLocation.text?.replacingOccurrences(of: " , ", with: " ,")
            lblLocation.text! = trimmedString!
            strForLocationVal = lblLocation.text!
            self.lat.removeAll()
            self.long.removeAll()
            self.updateLocationAPI()
        }
    }
    //FromLocationScreen
    func dataPassAttributedStringToHome(data: String) {
        //"Noida , Uttar Pradesh , India"
        //"Noida , Uttar Pradesh , India"
        dataLocation = data
        dataFromSelectLocationManual = data.components(separatedBy: ",")
        lblLocation.text = (dataFromSelectLocationManual as NSArray).componentsJoined(by: " ,")
        let trimmedString = lblLocation.text?.replacingOccurrences(of: " , ", with: " ,")
        lblLocation.text! = trimmedString!
        strForLocationVal = lblLocation.text!
    }
    
    //FromFilterScreen
    func dataSendToHomeFromFilter(dicDataComeFromFilterToHome: Dictionary<String, Any>) {
        isFromResetButton = false
        pageNo = 0
        dicDataComeFromFilter = dicDataComeFromFilterToHome
        homeTaskAPI()
    }
    
    func dataSendFromResetButtonToFilter(isFromReset: Bool) {
        pageNo = 0
        isFromResetButton = isFromReset
        homeTaskAPI()
    }
    
    //Update location.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let latitudeVal = locationManager.location?.coordinate.latitude {
            
            latitude = latitudeVal
            SingletonClass.sharedInstance().latitude = latitudeVal
        }
        if let longitudeVal = locationManager.location?.coordinate.longitude {
            
            longitude = longitudeVal
            SingletonClass.sharedInstance().longitude = longitudeVal
        }
        findCurrentLocation()
        locationManager.stopUpdatingLocation()
    }
    @objc func refresh() {
        pageNo = 0
        isPullToRefresh = true
        homeTaskAPI()
    }
    
    //MARK:- ActionMethods
    @IBAction func notificationListBtnClick(_ sender: Any) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "NotificationVC") as! NotificationVC
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
     @IBAction func btnSerch(_ sender: Any) {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "SearchUserListVC") as! SearchUserListVC
        self.navigationController?.pushViewController(controller, animated: true)
    }
    @IBAction func btnChangeLocation(_ sender: Any) {
        isCheckSelectAllBtnClick = false
        if let controller = storyboard?.instantiateViewController(withIdentifier: "SelectLocationViewController") as? SelectLocationViewController{
            if dataLocation.isEmpty{
            }
            else{
                controller.strforLocation = lblLocation.text!
            }
            controller.delegateToHome = self
            controller.isFromHomeScreen = isSendToSelectLocation
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
    }
    @IBAction func btnTopRatedUsers(_ sender: Any) {
        
        if let controller = storyboard?.instantiateViewController(withIdentifier: "TopRatedViewController"){
            
            self.navigationController?.pushViewController(controller, animated: true)
            
        }
    }
    @IBAction func btnFilter(_ sender: Any) {
        
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "FilterViewController") as? FilterViewController{
            
            controller.delegate = self as? filterDelegate 
            controller.modalPresentationStyle = .overCurrentContext
            controller.modalTransitionStyle = .crossDissolve
            self.tabBarController?.present(controller, animated: false, completion: nil)
            
        }
        
    }
    @objc func btnUserProfile(sender : UIButton){
        myId = arrHomeTask[sender.tag].user_id
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        controller.isHome = isFromHome
        controller.receiveUserIdFromHome = myId
        controller.strForType = "2"
        controller.receiveUserIdFromFollowing = arrHomeTask[sender.tag].user_id
        controller.strForOtherUserId = arrHomeTask[sender.tag].user_id
        controller.taskIdStr = arrHomeTask[sender.tag].task_id
        self.navigationController?.pushViewController(controller, animated: true)
    }
    @objc func btnOption(sender : UIButton){
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        alert.view.tintColor = UIColor.darkGray
        
        alert.view.layer.cornerRadius = 25
        
        let action1 = UIAlertAction(title: "Report this Post", style: .default, handler: { (action) -> Void in
            MBProgressHUD.showAdded(to: self.view, animated: true)
            var param : Dictionary<String,Any> = Dictionary()
            if let userId : String = UserDefaults.standard.value(forKey: keyUserId) as? String{
                self.userID = userId
            }
            param["type"] = "1"
            param["report_user_id"] = ""
            param["user_id"] = self.userID
            param["task_id"] = self.arrHomeTask[sender.tag].task_id
            param["report_text"] = "report text message"
            
            print(param)
            ServicesClass.postDataFromURL(url: APIConstants.TaskReportByUser, parameters: param, requestName: "") { (json, error) in
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
                if error == nil{
                    if json!["status"] as? Int != nil && json!["status"] as? Int == 1{
                        let strMsg = json!["message"] as! String
                        MBProgressHUD.hide(for: self.view, animated: true)
                        CommanUtil.showAlert(withTitle: "Adkube", withMsg: strMsg, in: self)
                    }else{
                        let strMsg = json!["message"] as! String
                        MBProgressHUD.hide(for: self.view, animated: true)
                        CommanUtil.showAlert(withTitle: "Adkube", withMsg: strMsg, in: self)
                    }
                }
                else{
                    MBProgressHUD.hide(for: self.view, animated: true)
                    CommanUtil.showAlert(withTitle: "Adkube", withMsg: (error?.localizedDescription)!, in: self)
                }
            }
        })
        
        let action2 = UIAlertAction(title: "Hide this Post", style: .default, handler: { (action) -> Void in
            
        })
        // Cancel button
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        cancel.setValue(UIColor.init(red: 255/255, green: 77/255, blue: 225/255, alpha: 1), forKey: "titleTextColor")
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK:- GeoCoder
    func findCurrentLocation() {
        let location = CLLocation(latitude: SingletonClass.sharedInstance().latitude, longitude: SingletonClass.sharedInstance().longitude)
        
        self.geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            
            // Complete address as PostalAddress
           // print(placeMark.postalCode as Any)  //  Import Contacts
            
            if placemarks != nil {
                
            // Location name
            if let locationName = placeMark.name  {
                print(locationName)
            }
            // Street address
            if let street = placeMark.thoroughfare {
                self.locationAddress = street
                print(street)
            }
            
            // city
            if let city = placeMark.addressDictionary!["City"] {
                self.arrLocationDetail.append(city as! String)
                print(city)
            }
            
            if let state = placeMark.administrativeArea{
                print(state)
            }
            
            // Country
            if let country = placeMark.country {
                self.arrLocationDetail.append(country)
                print(country)
            }
            
            self.lblLocation.text = (self.arrLocationDetail as NSArray).componentsJoined(by: ", ")
            self.strForLocationVal = ""
            if self.isCheckAPICall == false{
                self.isCheckAPICall = true
                self.updateLocationAPI()
            }
            }
        })
        
        arrLocationDetail.removeAll()
    }
    //MARK:- Notification Unread Count API
    func notificationUnreadCountAPI(){
        var param : Dictionary<String,Any> = Dictionary()
        if let loginUserId = UserDefaults.standard.value(forKey: keyUserId) {
            param["user_id"] = loginUserId
        }
        print(param)
        ServicesClass.postDataFromURL(url: APIConstants.NotificationCount, parameters: param, requestName: "") { (json, error) in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
            if error == nil{
                if json!["status"] as? Int != nil && json!["status"] as? Int == 1{
                    MBProgressHUD.hide(for: self.view, animated: true)
                    if json!["unread_count"] as? Int != nil && json!["unread_count"] as? Int == 0{
                        self.lblForNotificationCount.isHidden = true
                    }
                    else{
                        self.lblForNotificationCount.isHidden = false
                        let notificationCount = json!["unread_count"] as! Int
                        self.lblForNotificationCount.text = String(describing: notificationCount)
                    }
                    
                }else{
                    
                }
            }
            else{
               
            }
        }
    }
    
    //MARK:- API's
    func acceptTaskAPI(taskId : String , task_end_date : String){
        MBProgressHUD.showAdded(to: self.view, animated: true)
        //user_id,task_id,task_end_date
        if let userId : String = UserDefaults.standard.value(forKey: keyUserId) as? String{
            self.userID = userId
        }
        var param : Dictionary<String,Any> = Dictionary()
        
        param["user_id"] = userID
        param["task_id"] = taskId
        param["task_end_date"] = AppHelper.convertDateFormater(task_end_date)
        
        print(param)
        
        ServicesClass.postDataFromURL(url: APIConstants.accept_task, parameters: param, requestName: "") { (json, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if error == nil{
                
                if json!["status"] as? Int != nil && json!["status"] as? Int == 1{
                    
                    print("success")
                    
                }else{
                    MBProgressHUD.hide(for: self.view, animated: true)
                    CommanUtil.showAlert(withTitle: "Adkube", withMsg: json!["message"] as! String, in: self)
                }
                
            }else{
                MBProgressHUD.hide(for: self.view, animated: true)
                CommanUtil.showAlert(withTitle: "Adkube", withMsg: (error?.localizedDescription)!, in: self)
            }
        }
        
    }
    
    func skipAPI(taskId : String) {
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        if let userId : String = UserDefaults.standard.value(forKey: keyUserId) as? String{
            self.userID = userId
        }
        var param : Dictionary<String,Any> = Dictionary()
        
        param["user_id"] = userID
        param["task_id"] = taskId
        
        print(param)
        
        ServicesClass.postDataFromURL(url: APIConstants.skip_task, parameters: param, requestName: "") { (json, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if error == nil{
                
                if json!["status"] as? Int != nil && json!["status"] as? Int == 1{
                    
                    print("success")
                    
                }else{
                    CommanUtil.showAlert(withTitle: "Adkube", withMsg: json!["message"] as! String, in: self)
                }
                
            }else{
                MBProgressHUD.hide(for: self.view, animated: true)
                CommanUtil.showAlert(withTitle: "Adkube", withMsg: (error?.localizedDescription)!, in: self)
            }
        }
        
    }
    
    func homeTaskAPI() {
        
        if !isPullToRefresh && pageNo == 0{
            MBProgressHUD.showAdded(to: self.view, animated: true)
        }
        if let userId : String = UserDefaults.standard.value(forKey: keyUserId) as? String{
            self.userID = userId
        }
        
        var param : Dictionary<String,Any> = Dictionary()
        if strForLocationVal.isEmpty{
            param["address"] = strForLocationVal
        }
        else{
            if isCheckSelectAllBtnClick == true{
                param["address"] = ""
            }
            else{
                let trimmedString = lblLocation.text?.replacingOccurrences(of: " ,", with: ", ")
                param["address"] = trimmedString
            }
        }
        
//        if lat != "" {
//            param["latitude"] = lat //lat
//        }else{
//            param["latitude"] = SingletonClass.sharedInstance().latitude
//        }
//
//        if long != ""{
//            param["longitude"] = long //long
//        }else{
//            param["longitude"] = SingletonClass.sharedInstance().longitude
//        }
        
        if isFromResetButton {
            param["category_id"] = ""
            param["min_kube"] = ""
            param["max_kube"] = ""
            param["min_distance"] = "0"
            param["max_distance"] = "0"
        }else{
            
            if !dicDataComeFromFilter.isEmpty {
                
                param["category_id"] =  (dicDataComeFromFilter["arrIdCategory"] as! NSArray).componentsJoined(by: ",")
                param["min_kube"] = dicDataComeFromFilter["lowerValueKubes"] as? String
                param["max_kube"] = dicDataComeFromFilter["upperValueKubes"] as? String
                param["min_distance"] = dicDataComeFromFilter["lowerValueDistance"] as? String
                param["max_distance"] = dicDataComeFromFilter["upperValueDistance"] as? String
                
            }else{
                param["category_id"] = ""//
                param["min_kube"] = ""
                param["max_kube"] = ""
                param["min_distance"] = "0"
                param["max_distance"] = "0"
            }
            
        }
        if isCheckSelectAllBtnClick == true{
            param["category_id"] = ""//
            param["min_kube"] = ""
            param["max_kube"] = ""
            param["min_distance"] = "0"
            param["max_distance"] = "0"
        }
        param["user_id"] = userID
        param["limit"] = 20
        param["offset"] = pageNo * 20
        
        print(param)
        
        ServicesClass.postDataFromURL(url: APIConstants.hometask, parameters: param, requestName: "") { (json, error) in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            self.tblviewHome.infiniteScrollingView.stopAnimating()
            self.refreshControl.endRefreshing()
            if error == nil{
                if json!["status"] as? Int != nil && json!["status"] as? Int == 1{
                    
                    if let homeTask : Array<Dictionary<String,Any>> = json!["hometask"] as? Array<Dictionary<String,Any>> {
                        
                        print(homeTask.count)
                        if homeTask.count > 0{
                            if self.pageNo == 0{
                                self.arrHomeTask.removeAll()
                            }
                            
                            self.pageNo = self.pageNo + 1
                            
                            for dic in homeTask{
                                
                                let model : HomeModel = HomeModel.init(task_id: "", task_title: "", task_description: "", task_credit: "", task_end_date: "", created_at: "", task_visibility: "", user_id: "", full_name: "", profile_pic_image: "", location_address: "", category_name: "")
                                
                                if let task_id : String = dic["task_id"] as? String{
                                    model.task_id = task_id
                                }
                                
                                if let task_title : String = dic["task_title"] as? String{
                                    model.task_title = task_title
                                }
                                
                                if let task_description : String = dic["task_description"] as? String{
                                    model.task_description = task_description
                                }
                                
                                if let task_credit : String = dic["task_credit"] as? String{
                                    model.task_credit = task_credit
                                }
                                
                                if let task_end_date : String = dic["task_end_date"] as? String{
                                    model.task_end_date = task_end_date
                                    self.task_end_date = model.task_end_date //AppHelper.convertDateFormater(model.task_end_date)
                                }
                                
                                if let created_at : String = dic["created_at"] as? String{
                                    model.created_at = created_at
                                }
                                
                                if let task_visibility : String = dic["task_visibility"] as? String{
                                    model.task_visibility = task_visibility
                                }
                                
                                if let user_id : String = dic["user_id"] as? String{
                                    model.user_id = user_id
                                }
                                
                                if let full_name : String = dic["full_name"] as? String{
                                    model.full_name = full_name
                                }
                                
                                if let profile_pic_image : String = dic["profile_pic_image"] as? String{
                                    model.profile_pic_image = profile_pic_image
                                }
                                
                                if let location_address : String = dic["location_address"] as? String{
                                    model.location_address = location_address
                                }
                                
                                if let category_name : String = dic["category_name"] as? String{
                                    model.category_name = category_name
                                }
                                
                                let viewModel : HomeViewModel = HomeViewModel.init(model: model)
                                self.arrHomeTask.append(viewModel)
                            }
                            self.noDataLabel.text = ""
                            self.tblviewHome.reloadData()
                            self.notificationUnreadCountAPI()
                            
                        }else{
                            self.notificationUnreadCountAPI()
                            if self.pageNo == 0 {
                                self.noDataLabel.isHidden = false
                                self.arrHomeTask.removeAll()
                                self.tblviewHome.reloadData()
                                self.noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tblviewHome.bounds.size.width, height: self.tblviewHome.bounds.size.height))
                                
                                self.noDataLabel.font = UIFont(name: "Shaded Larch PERSONAL USE ONLY", size: 30)
                                self.noDataLabel.text = "No data found"
                                self.noDataLabel.textColor = UIColor.white
                                
                                self.noDataLabel.textAlignment = .center
                                self.tblviewHome.backgroundView  = self.noDataLabel
                                self.tblviewHome.separatorStyle  = .none
                            }
                        }
                        
                    }
                    if self.arrTopUser.count == 0{
                    self.topRatedUserListAPI()
                    }
                }else{
                    if self.arrTopUser.count == 0{
                        self.topRatedUserListAPI()
                    }
                    CommanUtil.showAlert(withTitle: "Adkube", withMsg: json!["message"] as! String, in: self)
                }
            }else{
                
                CommanUtil.showAlert(withTitle: "Adkube", withMsg: (error?.localizedDescription)!, in: self)
            }
        }
    }
    
    // TopRatedUser API List
    //MARK:- API's For Squabbles
    func topRatedUserListAPI(){
        
        if !isPullToRefresh && pageNo == 0{
            MBProgressHUD.showAdded(to: self.view, animated: true)
        }
        if let user_id = UserDefaults.standard.value(forKey: keyUserId) as? String{
           self.userID = user_id
        }
        var param : Dictionary<String,Any> = Dictionary()
        
        param["user_id"] = userID
        print(param)
        
        ServicesClass.postDataFromURL(url: APIConstants.TopRatedUsers, parameters: param, requestName: "") { (json, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.refreshControl.endRefreshing()
            if error == nil{
                if json!["status"] as? Int != nil && json!["status"] as? Int == 1{
                    
                    if let arrayDic : Array<Dictionary<String,Any>> = json!["top_rated_users"] as? Array<Dictionary<String,Any>>{
                        
                        if arrayDic.count > 0{
                            self.arrTopUser.removeAll()
                            for dic in arrayDic{
                                let model : TopRatedModelClass = TopRatedModelClass.init(user_id : "", full_name : "", email : "", profile_pic_image : "", followers : "", following : "", kubeness : "", kubnes_count : "",rating : "", post : "")
                                
                                if let user_id = dic["user_id"] as? String{
                                    model.user_id = user_id
                                }
                                if let full_name = dic["full_name"] as? String{
                                    model.full_name = full_name
                                }
                                if let email = dic["email"] as? String{
                                    model.email = email
                                }
                                if let profile_pic_image = dic["profile_pic_image"] as? String{
                                    model.profile_pic_image = profile_pic_image
                                }
                                let viewModel : TopRatedViewModelClass = TopRatedViewModelClass.init(model: model)
                                self.arrTopUser.append(viewModel)
                            }
                            self.btnSeallToprated.isHidden = false
                            self.lblTopRatedUser.isHidden = false
                            self.collectionviewHeightConstraint.constant = 100
                            self.collectionViewHome.reloadData()
                            
                        }
                        else{
                            self.btnSeallToprated.isHidden = true
                            self.lblTopRatedUser.isHidden = true
                            self.collectionviewHeightConstraint.constant = 0
                        }
                        
                    }
                    
                }else{
                    self.btnSeallToprated.isHidden = true
                    self.lblTopRatedUser.isHidden = true
                    self.collectionviewHeightConstraint.constant = 0
                    CommanUtil.showAlert(withTitle: "Adkube", withMsg: json!["message"] as! String, in: self)
                }
            }else{
                self.btnSeallToprated.isHidden = true
                self.lblTopRatedUser.isHidden = true
                self.collectionviewHeightConstraint.constant = 0
                CommanUtil.showAlert(withTitle: "Adkube", withMsg: (error?.localizedDescription)!, in: self)
            }
        }
        
    }


    func updateLocationAPI(){
        //user_id,latitude,longitude, address
        MBProgressHUD.showAdded(to: self.view, animated: true)
        if let userId : String = UserDefaults.standard.value(forKey: keyUserId) as? String{
            self.userID = userId
        }
        var param : Dictionary<String,Any> = Dictionary()
        if lat != "" {
            latVlaue = lat
            param["latitude"] = lat
        }else{
            let longTempval = SingletonClass.sharedInstance().latitude
            latVlaue =  String(describing: longTempval)
            param["latitude"] = SingletonClass.sharedInstance().latitude
        }
        
        if long != ""{
            longValue = long
            param["longitude"] = long
        }else{
            let latTempval = SingletonClass.sharedInstance().longitude
            longValue =  String(describing: latTempval)
            param["longitude"] = SingletonClass.sharedInstance().longitude
        }
        param["user_id"] = userID
        param["address"] = self.lblLocation.text
        
        print(param)
        
        ServicesClass.postDataFromURL(url: APIConstants.updatelocation, parameters: param, requestName: "") { (json, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if error == nil{
                if json!["status"] as? Int != nil && json!["status"] as? Int == 1{
                    self.homeTaskAPI()
                }else{
                    CommanUtil.showAlert(withTitle: "Adkube", withMsg: json!["message"] as! String, in: self)
                }
            }else{
                
                CommanUtil.showAlert(withTitle: "Adkube", withMsg: (error?.localizedDescription)!, in: self)
            }
        }
        
    }
    
}
extension HomeViewController : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrHomeTask.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeTableViewCell", for: indexPath) as! HomeTableViewCell
        
        //myId = arrHomeTask[indexPath.row].user_id
        cell.btnSkip.tag = indexPath.row
        cell.btnOptions.tag = indexPath.row
        cell.btnAccept.tag = indexPath.row
        cell.btnUserProfile.tag = indexPath.row
        cell.lblUserName.text = arrHomeTask[indexPath.row].full_name
        cell.lblTimeAgo.text = arrHomeTask[indexPath.row].created_at
        cell.lblTaskDescription.text = arrHomeTask[indexPath.row].task_description
        cell.lblCategory.text = arrHomeTask[indexPath.row].category_name
        cell.lblEndDate.text = "End date : \(arrHomeTask[indexPath.row].task_end_date!)"
        let strCubes = arrHomeTask[indexPath.row].task_credit
        let totalCubes:Float? = Float(strCubes!)
        let intCibes:Int? = Int(totalCubes!)
        cell.lblKubes.text = String(format:"%d",intCibes!)
        if let strImagePath = arrHomeTask[indexPath.row].profile_pic_image{
            self.strImagePath = strImagePath
            let url = URL(string: self.strImagePath)!
            cell.imgUser.af_setImage(withURL: url , placeholderImage: nil)
        }
        cell.btnAccept.addTarget(self, action: #selector(btnAcceptTask(sender:)), for: .touchUpInside)
        cell.btnOptions.addTarget(self, action: #selector(btnOption(sender:)), for: .touchUpInside)
        cell.btnUserProfile.addTarget(self, action: #selector(btnUserProfile(sender:)), for: .touchUpInside)
        cell.btnSkip.addTarget(self, action: #selector(btnSkipAction(sender:)), for: .touchUpInside)
        cell.imgUser.layer.cornerRadius = cell.imgUser.frame.size.width/2
        cell.imgUser.clipsToBounds = true
        cell.btnSkip.backgroundColor = .clear
        cell.btnSkip.layer.borderWidth = 2
        cell.btnSkip.layer.borderColor = UIColor.init(red: 191/255, green: 190/255, blue: 205/255, alpha: 1).cgColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let controller = storyboard?.instantiateViewController(withIdentifier: "TaskDetailViewController") as? TaskDetailViewController{
            controller.delegate = self
            controller.dicReceiveTaskIdAndTaskEndDateFromInitiatePending["taskId"] = arrHomeTask[indexPath.row].task_id
            controller.dicReceiveTaskIdAndTaskEndDateFromInitiatePending["task_end_date"] = arrHomeTask[indexPath.row].task_end_date
            self.navigationController?.pushViewController(controller, animated: true)
            
        }
        
    }
    
    
}
extension HomeViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrTopUser.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeCollectionViewCell", for: indexPath) as! HomeCollectionViewCell
        cell.imgUser.layer.cornerRadius = cell.imgUser.frame.size.width/2
        cell.imgUser.clipsToBounds = true
        
         cell.lblUserName.text = arrTopUser[indexPath.item].full_name
        if let strImagePath = arrTopUser[indexPath.row].profile_pic_image{
            self.strImagePath = strImagePath
            let url = URL(string: self.strImagePath)!
            cell.imgUser.af_setImage(withURL: url , placeholderImage: nil)
        }
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        controller.strForType = "1"
        controller.receiveUserIdFromHome = arrTopUser[indexPath.row].user_id
        controller.receiveUserIdFromFollowing = arrTopUser[indexPath.row].user_id
        controller.strForOtherUserId = arrTopUser[indexPath.row].user_id
        
        self.navigationController?.pushViewController(controller, animated: true)
        
       // CommanUtil.showAlert(withTitle: "AdKube", withMsg: "Underdevelopment", in: self)
        
    }
    
}
