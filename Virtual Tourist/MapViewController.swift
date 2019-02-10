//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Malak Sadik on 23/01/2019.
//  Copyright © 2019 Malak Sadik. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController:DataController = DataController.shared ////////
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!//takes managed obj ,implicitly unwrapped, instaintiated at viewDidLoad and ended at viewDid
    
    //reload saved pins
    fileprivate func setupFetchedResultsController() {
        //request data and loads this data from the persistent store to its context where we can access it.
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        //to configure the fetch request criteria
        //let sortDescriptor = NSSortDescriptor(key: "longitude", ascending: true)
        fetchRequest.sortDescriptors = []//accepts an array of sortDescriptors
        
        //to update the views/UI: observe notifications when managed obj changes or coredata context is saved
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        //class conforms to NSFetchedResultsControllerDelegate implemented at class extension below
        fetchedResultsController.delegate = self

        //start to load data and start tracking
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setupMap() {
        let gestureReconizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
        mapView.addGestureRecognizer(gestureReconizer)
        
        if let mapRegion = UserDefaults.standard.dictionary(forKey: "mapRegion") {
            let center = CLLocationCoordinate2DMake(mapRegion["lat"] as! Double, mapRegion["long"] as! Double)
            let span = MKCoordinateSpan(latitudeDelta: mapRegion["latDelta"] as! Double, longitudeDelta: mapRegion["longDelta"] as! Double)
            
            let region = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(region, animated: true)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.title = "Virtual Tourist"
        
        setupFetchedResultsController()
        
        setupMap()//gesture, center and zoom level
        
        mapView.delegate = self
        
        //fetch saved pins
        guard let pins = fetchedResultsController.fetchedObjects as? [Pin] else {
            return
        }
        
        //put all pins on the map
        for pin in pins {// 0..< pinCount
            let pointAnnotation = MKPointAnnotation()
            pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            pointAnnotation.title = pin.title

            self.mapView.addAnnotation(pointAnnotation)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    @objc func handleTap(gestureRecognizer: UIGestureRecognizer) {
        //print("long tap")
        if gestureRecognizer.state == .began {//long press
            let locationInView = gestureRecognizer.location(in: mapView)
            let coordinateOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            
            ///// Adding annotation:////
            let annotation = MKPointAnnotation()
            //get coords
            annotation.coordinate = coordinateOnMap //as! CLLocationCoordinate2D
            // get title from alert and add pin to core data
            let pinTitle = presentNewPinAlert(coordinate: annotation.coordinate)
            //annotation.title = pinTitle
            
        }
    }
    
    func presentNewPinAlert(coordinate : CLLocationCoordinate2D) -> String {
        let alert = UIAlertController(title: "New Pin", message: "Enter a title for this Pin", preferredStyle: .alert)
        var text : String = ""
        // Create actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] action in
            if let title = alert.textFields?.first?.text {
                //creat a new Pin
                self?.addPin(title: title, longitude: coordinate.longitude, latitude: coordinate.latitude )
                text = title
            }
        }
        saveAction.isEnabled = false
        
        // Add a text field
        alert.addTextField { textField in
            textField.placeholder = "Pin Title"
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { notif in
                if let text = textField.text, !text.isEmpty {
                    saveAction.isEnabled = true
                } else {
                    saveAction.isEnabled = false
                }
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
        
        return text
    }
    /// creats a new pin and save it
    func addPin(title : String, longitude: Double, latitude : Double) {
        //since Pin is a manged obj, will be initialied/associated with context
        let pin = Pin(context: dataController.viewContext)
        pin.longitude = longitude
        pin.latitude = latitude
        pin.title = title
        try? dataController.viewContext.save() //context try to save to persistent store
    }
    // fetch pin from coreData
    func getPin(latitude: Double, longitude: Double) -> Pin? {
        // create fetch request
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        // predicate
        let predicate = NSPredicate(format: "latitude == %lf AND longitude == %lf", latitude, longitude)
        fetchRequest.predicate = predicate
        
        // search for the pin
        guard let pin = (try? DataController.shared.viewContext.fetch(fetchRequest))!.first else {
            return nil
        }
        
        return pin
    }
}

extension MapViewController : NSFetchedResultsControllerDelegate {
    //didchange an obj called whenver the fetchResults receives a notification when obj has been added, removed or updated.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        let pin = anObject as! Pin
    
        let pointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        pointAnnotation.title = pin.title
        
        switch type {
        case .insert:
            mapView.addAnnotation(pointAnnotation)
            
        case .delete:
            mapView.removeAnnotation(pointAnnotation)
            
        case .update:
            mapView.removeAnnotation(pointAnnotation)
            mapView.addAnnotation(pointAnnotation)
            
        case .move:
            // N.B. The fetched results controller was set up with a single sort descriptor that produced a consistent ordering for its fetched Pin instances.
            fatalError("How did we move a Pin? We have a stable sort.")
        }
        
    }
    //when a pin is tapped once
    @objc func pinTapped(_ gesture: UITapGestureRecognizer) {
        //print("tap gesture")
        let pinView = gesture.view as! MKPinAnnotationView
        
        guard let pin = getPin(latitude: (pinView.annotation?.coordinate.latitude)!, longitude: (pinView.annotation?.coordinate.longitude)!) else {
            print("Pin not found in db")
            return
        }
        if isEditing {
            DataController.shared.viewContext.delete(pin)
            try? dataController.viewContext.save()
            mapView.removeAnnotation(pinView.annotation!)
        } else {
            performSegue(withIdentifier: "ShowPhotos", sender: pinView)
        }
        
    }
    
}


extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        // Add a tap gesture, when tapping a pin
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pinTapped(_:)))
        pinView!.addGestureRecognizer(tapGesture)
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        /////////// Save the map center and zoom level b/4 leaving
        let locationData = ["lat":mapView.centerCoordinate.latitude
            , "long":mapView.centerCoordinate.longitude
            , "latDelta":mapView.region.span.latitudeDelta
            , "longDelta":mapView.region.span.longitudeDelta]
        UserDefaults.standard.set(locationData, forKey: "mapRegion")//Persisting Latest Map Location
        //print("coords saved")
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Set the back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: .plain, target: nil, action: nil)
        
        if segue.identifier == "ShowPhotos" {
            // Get the senders coordinates
            let coordinate = (sender as! MKPinAnnotationView).annotation!.coordinate
            
            // Destination
            let destination = segue.destination as! PhotosViewController
            
            destination.tappedCoordinate = coordinate
            
            // Get the pin associated with the coordinate
            let allPins = fetchedResultsController.fetchedObjects as! [Pin]
            guard let index = allPins.index(where: { (pin) -> Bool in
                pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude
            }) else { return }
            
            let pin = allPins[index]
            destination.tappedPin = pin
            
            destination.fetchedPins = allPins
            //print ("pin title \(pin.title)")
        }
        
    }

    
}
