//
//  CollectionViewCell.swift
//  VirtualTourist


import UIKit

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    //Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //Get Photos
    
    func initWithPhoto(_ photo: Photo) {
        
        if photo.image != nil {
            self.imageView.image = UIImage(data: photo.image! as Data)
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            
        } else {
            
            downloadImage(photo)
        }
    }
    
    //Download Images
    
    func downloadImage(_ photo: Photo) {
        
        URLSession.shared.dataTask(with: URL(string: photo.imageURL!)!){ (data, response, error) in
                if error == nil {
                    
                    DispatchQueue.main.async {
                        
                        self.imageView.image = UIImage(data: data! as Data)
                        self.activityIndicator.stopAnimating()
                        self.saveImageDataToCoreData(photo: photo, imageData: data! as NSData)
                    }
                } else {
                    print("Could not download images to cell")
                }
            }
            
            .resume()
    }
    
    //Save Images
    func saveImageDataToCoreData(photo: Photo, imageData: NSData) {
        do {
            photo.image = imageData as Data
            try? DataController.shared.viewContext.save()
//
//        } catch {
//            print("Saving Photo imageData Failed")
        }
    }
    
}
