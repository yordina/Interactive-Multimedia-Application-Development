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

    
    
    var userInputLocation = FlyoverAwesomePlace.parisEiffelTower
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
                    self.userInputLocation = FlyoverAwesomePlace.newYorkStatueOfLiberty
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
        let camera = FlyoverCamera(mapView: self.tourMapKit, configuration:FlyoverCamera.Configuration(duration: 6.0, altitude: 300, pitch: 45.0, headingStep: 20.0))
        camera.start(flyover: self.userInputLocation)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(9), execute: {camera.stop()})
    }
    let locationDictionary = ["Statue of Liberty": FlyoverAwesomePlace.newYorkStatueOfLiberty,
                              "Golden gate bridge" : FlyoverAwesomePlace.sanFranciscoGoldenGateBridge,
                              "Big ben":FlyoverAwesomePlace.londonBigBen,
                              "Eiffel Tower":FlyoverAwesomePlace.parisEiffelTower,
                              "Sydney Opera house": FlyoverAwesomePlace.sydneyOperaHouse,
                              "Rome": FlyoverAwesomePlace.romeColosseum,
                              "Apple": FlyoverAwesomePlace.appleHeadquarter]
    
}

