//
//  ViewController.swift
//  DigitalTour
//
//  Created by Yordanos Mogos on 4/27/19.
//  Copyright © 2019 Yordanos Mogos. All rights reserved.
//

import UIKit
import FlyoverKit
import MapKit
import Speech

class ViewController: UIViewController, MKMapViewDelegate,SFSpeechRecognizerDelegate {

    
    
    var userInputLocation =  CLLocationCoordinate2D(latitude: 15.3370, longitude: 38.9379)
    let speechRec: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier : "en-us"))
    var recognitionRequest:SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRec?.delegate = self
        SFSpeechRecognizer.requestAuthorization{
            status in
            var buttonState = false
            switch status{
            case .authorized:
                buttonState = true
                print("Permission Received")
            case .denied:
                buttonState = false
                print("User didn't grant permission for speech")
            case .notDetermined:
                buttonState = false
                print("Speech recognition not allowed by user")
            case .restricted:
                buttonState = false
                print("Speech recognition not supported")
            }
            DispatchQueue.main.async{
                self.tourButton.isEnabled = buttonState
            }
        }
        self.mapSetup()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func startRecording(){
        if recognitionTask != nil{
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch{
            print("Failed to setup audio session")
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else{
            fatalError("Couldn't create instance")
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRec?.recognitionTask(with: recognitionRequest){
            result , error in
            var isLast = false
            if result != nil{
                isLast = (result?.isFinal)!
            }
            
            if error != nil || isLast{
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.tourButton.isEnabled = true
                let bestTrans = result?.bestTranscription.formattedString
               
                var dictionary =  self.locationDictionary.contains{ $0.key == bestTrans}
                
                if dictionary{
                    self.tourLabel.text = bestTrans
                    self.userInputLocation = self.locationDictionary[bestTrans!]!
                } else{
                    self.tourLabel.text = "Not found.Let's visit the PYRAMIDS"
                    self.userInputLocation = CLLocationCoordinate2D(latitude: 29.9792, longitude: 31.1342)
                }
                  self.mapSetup()
                }
            }
        
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format){
            buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        
        do{
            try audioEngine.start()

        } catch {
            print("Can't start the engine")
        }
        
        
    }
    
    
    
    
    
    
    
  
    
    
    var camera: MKMapCamera?

    @IBOutlet weak var tourMapKit: MKMapView!
    
    @IBOutlet weak var tourButton: UIButton!
    @IBOutlet weak var tourLabel: UILabel!
    @IBAction func tourButtonClicked(_ sender: Any) {
        if audioEngine.isRunning{
            audioEngine.stop()
            recognitionRequest?.endAudio()
            tourButton.isEnabled = false
            tourButton.setTitle("Record", for: .normal)
        } else {
    
            startRecording()
            tourButton.setTitle("Stop", for: .normal)
            
        }
    }
    
    func mapSetup()
    {
        let distance: CLLocationDistance = 1200
        let pitch: CGFloat = 65.0
        let heading = 20.0
       
        
        //let distance: CLLocationDistance = 650
        //let pitch: CGFloat = 30
        // let heading = 90.0
        
        self.tourMapKit.mapType = .satelliteFlyover
        
        let coordinate =  CLLocationCoordinate2D(latitude: 15.3370 , longitude: 38.9379)
        
        camera = MKMapCamera(lookingAtCenter: userInputLocation,
                             fromDistance: distance,
                             pitch: pitch,
                             heading: heading)
        
        tourMapKit.camera = camera!
        
        UIView.animate(withDuration: 20.0, animations: {
            self.camera!.heading += 180
            self.camera!.pitch = 25
            self.tourMapKit.camera = self.camera!
        })
//        let distance: CLLocationDistance = 600
//        let pitch: CGFloat = 65.0
//        let heading = 20.0
        
        //let distance: CLLocationDistance = 650
        //let pitch: CGFloat = 30
        // let heading = 90.0
        
        self.tourMapKit.mapType = .satelliteFlyover
        
    
        //tourMapKit.camera = camera2!
        self.tourMapKit.mapType = .satelliteFlyover
        self.tourMapKit.showsBuildings = true
        self.tourMapKit.isZoomEnabled = true
        self.tourMapKit.isScrollEnabled = true
        

//        let camera = FlyoverCamera(mapView: self.tourMapKit, configuration:FlyoverCamera.Configuration(duration: 6.0, altitude: 600, pitch: 45.0, headingStep: 40.0))
//
//        camera.start(flyover: self.userInputLocation)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(9), execute: {})
    }
//    let locationDictionary = ["Statue of Liberty": FlyoverAwesomePlace.newYorkStatueOfLiberty,
//                              "Golden gate bridge" : FlyoverAwesomePlace.sanFranciscoGoldenGateBridge,
//                              "Big ben":FlyoverAwesomePlace.londonBigBen,
//                              "Eiffel Tower":FlyoverAwesomePlace.parisEiffelTower,
//                              "Sydney Opera house": FlyoverAwesomePlace.sydneyOperaHouse,
//                              "Rome": FlyoverAwesomePlace.romeColosseum,
//                              "Apple": FlyoverAwesomePlace.appleHeadquarter]
    let locationDictionary = ["New York": CLLocationCoordinate2D(latitude: 40.7484405, longitude: -73.9856644),
                              "Asmara": CLLocationCoordinate2D(latitude: 15.3229, longitude: 38.9251),
                              "Kabul" :    CLLocationCoordinate2D(latitude: 34.5553, longitude: 69.2075),
                              "Buenos Aires":  CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
                              "Brussels" :  CLLocationCoordinate2D(latitude: 50.8514, longitude: 4.3505),
                              "Brasilia" :    CLLocationCoordinate2D(latitude: -15.8267, longitude: -47.9218),
                              "Santiago" : CLLocationCoordinate2D(latitude: 33.24, longitude: -70.40),
                              "Beijing" :   CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
                              "Havana" :  CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666),
                              "Copenhagen" :  CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683),
                              "Massawa" :  CLLocationCoordinate2D(latitude: 15.6079, longitude: 39.4554),
        
                              "Djibouti" :  CLLocationCoordinate2D(latitude: 11.8251, longitude: 42.5903),
                              "Addis Ababa" :    CLLocationCoordinate2D(latitude: 8.9806, longitude: 38.7578),
                              "Paris" :  CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
                              "Athens" :  CLLocationCoordinate2D(latitude: 37.9726, longitude: 23.7303),

                         "Rome" : CLLocationCoordinate2D(latitude: 41.8902, longitude: 12.4922),
                     "Berlin" : CLLocationCoordinate2D(latitude: 52.5163, longitude: 13.3777),
                    "San Francisco" : CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783),
                    "London" :CLLocationCoordinate2D(latitude: 51.5007, longitude: -0.1246),
                    "Cairo" :CLLocationCoordinate2D(latitude: 29.9792, longitude: 31.1342),
                    
        
        
    ]
    
}

