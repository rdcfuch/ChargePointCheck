//
//  ChargePointNetworkHandler.swift
//  ChargePointCheck
//
//  Created by Chen Fu on 6/9/17.
//  Copyright © 2017 Chen Fu. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

enum StationStatus{
    case Unknown
    case OK
    case NotOK
    case Handi
    case NotAvailable
}
struct chargingStation {
    var building:String
    var stationNumber:String
    var port1status:StationStatus
    var port2status:StationStatus
    var Status:StationStatus
    var availablePortNumber:Int
}

struct handiPort {
    var station:String
    var port:String
}

class ChargePointHandler{
    
    var sessionMgr=Alamofire.SessionManager.default
    var tmpCookie : [HTTPCookie]? = nil
    var ci_ui_session = "", coulomb_sess = ""
    var stationList:[chargingStation]=[]
    var externalTableView:UITableView?=nil
    var handiCapList:[String:Int] = [:]
    
    
    
    func craeteStationList(inputSL:[String],inputbuilding:String)->Void{
        for item in inputSL{
            let tmpStation=chargingStation(building: inputbuilding, stationNumber: item, port1status:.Unknown, port2status:.Unknown, Status: .Unknown,availablePortNumber:0)
            self.stationList.append(tmpStation)
        }
        
        for item in self.stationList{
            print(item)
        }
    }
    
    func updateListStatus() -> Void {
        
        let np  = [
            "user_name":"rdcfuch@yahoo.com",
            "user_password":"FCchargepoint123",
            "auth_code":"",
            "recaptcha_response_field":"",
            "timezone_offset":420,
            "timezone":"PDT",
            "timezone_name":""
            ] as [String:Any]
        let header = [
            "origin":" https://na.chargepoint.com"
            , "accept-encoding":" gzip, deflate, br"
            , "x-requested-with":" XMLHttpRequest"
            , "accept-language":" en,zh-CN;q=0.8,zh;q=0.6"
            , "user-agent":" Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"
            , "content-type":" application/x-www-form-urlencoded; charset=UTF-8"
            , "accept":" */*"
            , "referer":" https://na.chargepoint.com/home?redirect="
            , "authority":" na.chargepoint.com"
            , "cookie":"ci_ui_session=0ebe2e51e1ed8f38b1993daba12337fc; _ga=GA1.3.1065139693.1497045966; _gid=GA1.3.1585662701.1497045966; _gat=1"
            ] as [String:String]
        
        self.sessionMgr.request("https://na.chargepoint.com/users/validate", method: .post,parameters:np,headers:header).responseString { response in
            //debugPrint(response)
            
            if let
                headerFields = response.response?.allHeaderFields as? [String: String],
                let URL = response.response?.url
            {
                self.tmpCookie = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: URL)
                for cc in self.tmpCookie!{
                    switch(cc.name) {
                    case "ci_ui_session" :
                        if(cc.value.contains("%")) {
                            self.ci_ui_session=cc.value
                            print("got the right ci_ui_session:  "+self.ci_ui_session)
                            //login is successful, go ahead to get the Station Info
                            //below is html version
                            //self.getStationInfo()
                            //below is JSON version
                            self.getStationInfoJSONVersion()
                        }
                        
                    case "coulomb_sess" :
                        self.coulomb_sess=cc.value
                        
                    default:
                        print()
                        
                    }
                }
            }
        }
    }
    
    //use json response
    func getStationInfoJSONVersion() -> Void {
        let header = [
            "origin":" https://na.chargepoint.com",
            "x-requested-with":" XMLHttpRequest"
            , "accept-language":" en,zh-CN;q=0.8,zh;q=0.6"
            , "user-agent":" Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"
            , "content-type":" application/x-www-form-urlencoded; charset=UTF-8"
            , "accept":" */*"
            , "referer":" https://na.chargepoint.com/charge_point"
            , "authority":" na.chargepoint.com"
            , "cookie":" showLocationError=true; _ga=GA1.3.693960171.1497043239; _gid=GA1.3.1102542595.1497043239; ci_ui_session="+self.ci_ui_session] as [String:String]
        
        for ind in 0..<self.stationList.count{
            let st=["deviceId":self.stationList[ind].stationNumber] as [String:Any]
            self.sessionMgr.request("https://na.chargepoint.com/dashboard/get_station_info_json", method: .post, parameters: st, headers: header).responseJSON{ response in
//                print(response)
                //to get status code
                if let status = response.response?.statusCode {
                    switch(status){
                    case 200:
                        print("example success")
                    default:
                        print("error with response status: \(status)")
                    }
                }
                //to get JSON return value
                if let result = response.data {
                    let json = JSON(result)
                    let portcount=json[0]["summaries"][0]["port_count"]["total"].intValue
                    //check the single port station
                    if(portcount==1){
                        self.judgeSingleStationPortStatus(inString: json[0]["summaries"][0]["port_status"]["outlet_1"]["status"].stringValue, index: ind)
                    }
                    else if(portcount==2){
                        //just if it contains handicap port
                        let sn=self.stationList[ind].stationNumber as String
                        let ccc=self.handiCapList[sn]
                        if(ccc != nil){
                            if(ccc==1){
                                self.judgeSingleStationPortStatus(inString: json[0]["summaries"][0]["port_status"]["outlet_2"]["status"].stringValue, index: ind)
                            }else if(ccc==0){
                                self.judgeSingleStationPortStatus(inString: json[0]["summaries"][0]["port_status"]["outlet_1"]["status"].stringValue, index: ind)
                            }else{
                                print("Error: your handicap port indicator has some problem, please check!")
                            }
                        }
                        // no handicap port
                        else{
                            var availablePortnum_temp=0
                            self.judgeSingleStationPortStatus(inString: json[0]["summaries"][0]["port_status"]["outlet_1"]["status"].stringValue, index: ind)
                            availablePortnum_temp+=self.stationList[ind].availablePortNumber
                            self.stationList[ind].availablePortNumber = availablePortnum_temp
                            
                            self.judgeSingleStationPortStatus(inString: json[0]["summaries"][0]["port_status"]["outlet_2"]["status"].stringValue, index: ind)
                            availablePortnum_temp+=self.stationList[ind].availablePortNumber
                            
                            self.stationList[ind].availablePortNumber = availablePortnum_temp
                            print("availalbe ports : \(availablePortnum_temp)")
                            if(availablePortnum_temp>=1){
                                self.stationList[ind].Status = .OK
                                self.reloadSingleCell(myindex: ind)
                            }
                            
                        }
//                        print(json[0]["summaries"][0]["port_status"]["outlet_1"]["status"].stringValue)
                    }
                    
                }
                
            }
            
        }
    }
    
    //use html response
    func getStationInfo() -> Void {
        
        let header = [
            "origin":" https://na.chargepoint.com",
            "x-requested-with":" XMLHttpRequest"
            , "accept-language":" en,zh-CN;q=0.8,zh;q=0.6"
            , "user-agent":" Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"
            , "content-type":" application/x-www-form-urlencoded; charset=UTF-8"
            , "accept":" */*"
            , "referer":" https://na.chargepoint.com/charge_point"
            , "authority":" na.chargepoint.com"
            , "cookie":" showLocationError=true; _ga=GA1.3.693960171.1497043239; _gid=GA1.3.1102542595.1497043239; ci_ui_session="+self.ci_ui_session] as [String:String]
        
        for ind in 0..<self.stationList.count{
            let st=["deviceId":self.stationList[ind].stationNumber] as [String:Any]
            self.sessionMgr.request("https://na.chargepoint.com/dashboard/getStationInfo", method: .post, parameters: st, headers: header).responseString { response in
                //                debugPrint(response.result)
                
                
                guard response.result.isSuccess else {
                    print("Alarm!!!, http response is error!" )
                    print(response.result.error!)
                    return
                }
                //split the string into 1 or 2 array item to tell which port
                let resultString = response.result.value
                let strArray:[String]=(resultString?.components(separatedBy: "<hr"))!
                let sn=self.stationList[ind].stationNumber as String
                let ccc=self.handiCapList[sn]
                //if it's handicaped
                if(ccc != nil){
                    if( ccc==0){
                        //print("\(sn)+++++++++\(ccc)")
                        // if port 0 is handicanped, we check the port 1 to tell the availability of the station
                        self.judgeStationPortStatus(inString: strArray[1], index: ind)
                        
                    }else if( ccc == 1) {
                        // if port 1 is handicanped, we check the port 0 to tell the availability of the station
                        self.judgeStationPortStatus(inString: strArray[0], index: ind)
                    }
                }
                //Not handicaped
                else{
                    self.judgeStationPortStatus(inString: resultString!, index: ind)
                }
            }
            
        }
    }
    
    /*
     function to reload the single cell with input index
     */
    func reloadSingleCell(myindex:Int)->Void{
        let rowNumber: Int = myindex
        let sectionNumber: Int = 0
        let indexPath = IndexPath(item: rowNumber, section: sectionNumber)
        self.externalTableView?.reloadRows(at: [indexPath], with: .middle)
        print("refreshing cell")
    }
    
    //function to determine the port status, based on json response
    func judgeSingleStationPortStatus(inString:String,index:Int)->Void{
        if (inString=="available"){
            print("$$$" + self.stationList[index].stationNumber + " is available")
            self.stationList[index].Status = .OK
            self.stationList[index].availablePortNumber = 1
            self.reloadSingleCell(myindex: index)
        }
        else if (inString=="in_use"){
            print("$$$" + self.stationList[index].stationNumber + " is available")
            self.stationList[index].Status = .NotOK
            self.stationList[index].availablePortNumber = 0
            self.reloadSingleCell(myindex: index)
        }else if (inString=="unknown"){
            print("$$$" + self.stationList[index].stationNumber + " is available")
            self.stationList[index].Status = .Unknown
            self.stationList[index].availablePortNumber = 0
            self.reloadSingleCell(myindex: index)
        }
    }
    
    
    //function to determine the port status, based on html response
    func judgeStationPortStatus(inString:String,index:Int)->Void{
        if (inString.contains("availableStatusRing")){
            print("$$$" + self.stationList[index].stationNumber + " is available")
            self.stationList[index].Status = .OK
            self.reloadSingleCell(myindex: index)
        }
        else if(inString.contains("occupiedStatusRing")){
            print("$$$" + self.stationList[index].stationNumber + " is available")
            self.stationList[index].Status = .NotOK
            self.stationList[index].availablePortNumber = 0
            self.reloadSingleCell(myindex: index)
        }
        else if(inString.contains("unknownStatusRing")){
            print("$$$" + self.stationList[index].stationNumber + " is available")
            self.stationList[index].Status = .Unknown
            self.stationList[index].availablePortNumber = 0
            self.reloadSingleCell(myindex: index)
        }
    }
}


