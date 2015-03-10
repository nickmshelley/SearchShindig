//
//  ViewController.swift
//  SearchShindig
//
//  Created by Heather Shelley on 3/10/15.
//  Copyright (c) 2015 Mine. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    var images: [(thumbURL: String, largeURL: String)] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.becomeFirstResponder()
    }
    
    // MARK: - UICollectionView Data Source
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    // MARK: - UICollectionView Delegate
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as ThumbnailCell
        if let url = NSURL(string: images[indexPath.row].thumbURL) {
            cell.thumbnailImageView.setImageWithURL(url)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let item = images[indexPath.row]
        performSegueWithIdentifier("ImageSegue", sender: item.largeURL)
    }
    
    // MARK: - UISearchBar Delegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let searchText = searchBar.text
        let manager = AFHTTPRequestOperationManager()
        manager.responseSerializer = AFHTTPResponseSerializer()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            manager.GET("https://api.flickr.com/services/rest/", parameters: ["format": "json", "api_key": "1dd17dde0fed7286935d83875fcc17dd", "method": "flickr.photos.search", "text": searchText], success: { (operation, response) -> Void in
                if let stringResponse = NSString(data: response as NSData, encoding: NSUTF8StringEncoding) {
                    if let json: [[String: AnyObject]] = self.processFlickrResponse(stringResponse) {
                        self.images = json.take(25).map { photoDict in
                            // I'm excited to start using Swift 1.2 to avoid the pyramid of doom
                            if let farmInt = photoDict["farm"] as? Int {
                                let farm = String(farmInt)
                                if let server = photoDict["server"] as? String {
                                    if let id = photoDict["id"] as? String {
                                        if let secret = photoDict["secret"] as? String {
                                            let base = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_"
                                            return (base + "t.jpg", base + "b.jpg")
                                        }
                                    }
                                }
                            }
                            return ("", "")
                        }
                        println(self.images)
                    }
                    
                    searchBar.resignFirstResponder()
                }
                }) { (operation, error) -> Void in
                    println("failed with error: \(error)")
                    searchBar.resignFirstResponder()
            }
            
            return Void()
        })
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let imageController = segue.destinationViewController as? ImageViewController {
            if let urlString = sender as? String {
                imageController.urlString = urlString
            }
        }
    }
    
    // MARK: - Private Methods
    
    // This is hacky, but the response seems to be a valid javascript object, and a quick google search didn't give me anything better
    private func processFlickrResponse(response: String) -> [[String: AnyObject]]? {
        let beginningRemoved = response.stringByReplacingOccurrencesOfString("jsonFlickrApi(", withString: "")
        let validJsonString: String = beginningRemoved.substringToIndex(beginningRemoved.endIndex.predecessor())
        if let data = validJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            if let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [String: AnyObject] {
                if let photos = json["photos"] as? [String: AnyObject] {
                    return photos["photo"] as? [[String: AnyObject]]
                }
            }
        }
        
        return nil
    }
    
}

