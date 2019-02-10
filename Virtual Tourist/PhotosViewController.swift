//
//  PhotosViewController.swift
//  Virtual Tourist
//
//  Created by Malak Sadik on 25/01/2019.
//  Copyright © 2019 Malak Sadik. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet weak var noImageFoundLabel: UILabel!
    
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    let totalCellCount:Int = 18
    
    var fetchedPins : [Pin]!
    var tappedCoordinate: CLLocationCoordinate2D!
    var tappedPin: Pin!
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
         navigationItem.rightBarButtonItem = editButtonItem

        //put all pins on the map
        for pin in fetchedPins {// 0..< pinCount
            let pointAnnotation = MKPointAnnotation()
            pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            pointAnnotation.title = pin.title
            
            self.mapView.addAnnotation(pointAnnotation)
        }
        mapView.setCenter(tappedCoordinate, animated: true)
        
        let space:CGFloat = 3.0
        let width = (view.frame.size.width - (2 * space)) / 3.0
        let height = width //ratio
        
        flowLayout.minimumInteritemSpacing = space //the space between items within a row or column
        flowLayout.minimumLineSpacing = space //the space between rows or columns
        flowLayout.itemSize = CGSize(width: width, height: height) //cell size
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupFetchedResultController()
        if (fetchedResultsController.fetchedObjects?.count)! < 1  {
            showNoImageLabel(show: false)
            newCollectionButtonEnabled(isEnabled: false)
            getFlickerImages()
        }
        
        collectionView.reloadData()
    
    }
    //MARK: Setup FetchedResultController
    fileprivate func setupFetchedResultController() {
        // create fetch request
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        // predicate
        let predicate = NSPredicate(format: "pin == %@", tappedPin)
        fetchRequest.predicate = predicate
        
        // sort descriptor
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // set delegate
        fetchedResultsController.delegate = self
        
        // fetch data
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        //print("fetchedResults \(fetchedResultsController.fetchedObjects?.count)")
    }
    
    // MARK: no image label
    fileprivate func showNoImageLabel(show: Bool) {
        DispatchQueue.main.async {
            self.noImageFoundLabel.isHidden = !show
        }
    }
    // Mark: Handle reload Collection button state
    fileprivate func newCollectionButtonEnabled(isEnabled: Bool) {
        DispatchQueue.main.async {
            self.newCollectionButton.isEnabled = isEnabled
        }
    }
    
    @IBAction func reloadNewCollectionFlickerImages(_ sender: Any) {
        deletePhotos()
        
        showNoImageLabel(show: false)
        newCollectionButtonEnabled(isEnabled: false)
        
        getFlickerImages()
        //print ("finsh")
    }
    
    fileprivate func deletePhotos() {
        for photo in (fetchedResultsController!.fetchedObjects)! {
            DataController.shared.viewContext.delete(photo)
            try? DataController.shared.viewContext.save()
        }
    }
    
    fileprivate func getFlickerImages() {
        //check Internet Connection
        let reachability = Reachability()!
        if reachability.connection == .none {
            self.showAlertMessage(title: "No Internet Connection!", message: "Make sure your device is connected to the internet.")
        }
        
        //print ("start")
        Flickr.shared.getFlickrImagesByLatLon(pin: tappedPin, coordinate: tappedCoordinate) { (success, msg, flickrImages) in //flickrImages:array of photos dictionaries
//            print ("flickrImages.count \(flickrImages!.count)")
            if success {
                //  print ("progress")
                for _ in 1...self.totalCellCount {//18
                    let randomPhotoIndex = Int(arc4random_uniform(UInt32(flickrImages!.count)))
                    let photo = Photo(context: DataController.shared.viewContext)
                    let dic : [String:Any] = flickrImages![randomPhotoIndex]
                    photo.imageURL = dic["urlString"] as! String
                    photo.title = dic["title"] as! String
                    photo.pin = self.tappedPin
                    try? DataController.shared.viewContext.save()
                    
//                    print("flicker imgs saved")
                    self.newCollectionButtonEnabled(isEnabled: true)
                }
                
            } else {
                self.showAlertMessage(title: "Error!", message: msg)
                self.showNoImageLabel(show: true)
                self.newCollectionButtonEnabled(isEnabled: true)
            }
        }
    }
    
    
    
    //MARK
    
    // number of cells to be generated
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! CollectionViewCell// casting to the cell view controller . needs to be entered in two places:as the class name in the identity inspector and as the reuseIdentifier in the attributes inspector.
        
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
    
        cell.initWithPhoto(fetchedResultsController.object(at: indexPath))
//        cell.initWithPhoto(fetchedResultsController.object(at: indexPath)) { data,error in
//            if error == nil {
//                cell.imageView.image = UIImage(data)
//                cell.activityIndicator.stopAnimating() //Exactly at the point the download finishes!
//            }
//        }
        return cell
    }
    
   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {

        if isEditing {
            let photo = fetchedResultsController.object(at: indexPath)
            DataController.shared.viewContext.delete(photo)
            try? DataController.shared.viewContext.save()
        } else {
            let detailsController = self.storyboard!.instantiateViewController(withIdentifier: "DetailsViewController") as! DetailsViewController
            detailsController.photo = fetchedResultsController.object(at: indexPath)
            self.navigationController!.pushViewController(detailsController, animated: true)
    }

    }
}
// MARK: fetchedResultController Delegate
extension PhotosViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
            break
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        default:
            break
        }
    }
}
