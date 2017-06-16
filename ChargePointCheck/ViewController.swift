//
//  ViewController.swift
//  ChargePointCheck
//
//  Created by Chen Fu on 6/9/17.
//  Copyright © 2017 Chen Fu. All rights reserved.
//

import UIKit



class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    @IBOutlet weak var myTableview: UITableView!
    
    //data list
    var DA7StationList:[String] = ["103031","104205","104103","104191"]
    var BA3StationList:[String] = ["124387","136903"]
    var GymStationList:[String] = ["91073","91087","91037","91053","91055"]
    var DA12StationList:[String] = ["126473","88869","88577","88527"]
    var HandiStationList:[String:Int] = ["103031":1,"91055":0,"126473":0]
    var myChargePointNH=ChargePointHandler()
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.myChargePointNH.craeteStationList(inputSL: DA7StationList, inputbuilding: "DA7")
        self.myChargePointNH.craeteStationList(inputSL: BA3StationList, inputbuilding: "BA3")
        self.myChargePointNH.craeteStationList(inputSL: DA12StationList, inputbuilding: "DA12")
        self.myChargePointNH.craeteStationList(inputSL: GymStationList, inputbuilding: "Gym")
        
        //send tableView to chargepointNH object
        myChargePointNH.externalTableView=self.myTableview
        myChargePointNH.handiCapList=HandiStationList
        
        // tableview delegate and datasource
        myTableview.delegate = self
        myTableview.dataSource = self
        myChargePointNH.updateListStatus()
    }
    
    //implement the table view function
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.myChargePointNH.stationList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let myCell = tableView.dequeueReusableCell(withIdentifier: "myCell") as! myTableViewCell
        let StaNum:String = self.myChargePointNH.stationList[indexPath.row].stationNumber
        let isHandiport=HandiStationList[StaNum] != nil
        if(isHandiport){
            myCell.buildingNum.text=self.myChargePointNH.stationList[indexPath.row].building+"*"
            } else {
            myCell.buildingNum.text=self.myChargePointNH.stationList[indexPath.row].building
            }
        myCell.stationNum.text=self.myChargePointNH.stationList[indexPath.row].stationNumber
        myCell.availablePortNumLabel.text=String(self.myChargePointNH.stationList[indexPath.row].availablePortNumber)
        
        switch self.myChargePointNH.stationList[indexPath.row].Status {
        case StationStatus.OK :
            myCell.myImageView.image = UIImage(named:"greenplug.png")
        case StationStatus.NotOK:
            myCell.myImageView.image = UIImage(named:"orangeplug.png")
        case StationStatus.Unknown:
            myCell.myImageView.image = UIImage(named:"greyquestionmark.png")
        default:
            myCell.myImageView.image=nil
        }
        
        return myCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(self.myChargePointNH.stationList[indexPath.row].stationNumber+"***")
        myChargePointNH.reloadSingleCell(myindex: indexPath.row)
    }
    
    @IBAction func refreshCell(_ sender: Any) {
        myChargePointNH.updateListStatus()
    }
    
}

