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

    
    
    var userInputLocation =  CLLocationCoordinate2D(latitude: 40.7484405, longitude: -73.9856644)
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
                    self.tourLabel.text = "Can't find this place"
                    self.userInputLocation = CLLocationCoordinate2D(latitude: 15.3229, longitude: 38.9251)
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
        self.tourMapKit.mapType = .satelliteFlyover
        self.tourMapKit.showsBuildings = true
        self.tourMapKit.isZoomEnabled = true
        self.tourMapKit.isScrollEnabled = true

        let camera = FlyoverCamera(mapView: self.tourMapKit, configuration:FlyoverCamera.Configuration(duration: 20.0, altitude: 600, pitch: 45.0, headingStep: 40.0))
        camera.start(flyover: self.userInputLocation)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(9), execute: {camera.stop()})
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
        "Kabul" :    CLLocationCoordinate2D(latitude: 34.28, longitude: 69.11),
        "Buenos Aires":  CLLocationCoordinate2D(latitude: 36.30, longitude: -60.00),
        "Brussels" :  CLLocationCoordinate2D(latitude: 50.51, longitude: 04.21),
        //Brasilia    15.47S    47.55W
        //Santiago    33.24S    70.40W
        //Beijing    39.55N    116.20E
        //Havana    23.08N    82.22W
        //Copenhagen    55.41N    12.34E
        //Djibouti    11.08N    42.20E
        "Addis Ababa" :    CLLocationCoordinate2D(latitude: 09.02, longitude: 38.42)
        //Paris    48.50N    02.20E
        //Athens    37.58N    23.46E
        //Rome    41.54N    12.29E
        //Mexico    19.20N    99.10W
        //Berlin    52.30N    13.25E
        //Madrid    40.25N    03.45W
        //Washington DC    39.91N    77.02W
        //Khartoum    15.31N    32.35E
        //Riyadh    24.41N    46.42E
    ]
    
}

