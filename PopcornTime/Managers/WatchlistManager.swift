//
//  WatchlistManager.swift
//  PopcornTime
//
//  Created by Yogi Bear on 3/26/16.
//  Copyright © 2016 PopcornTime. All rights reserved.
//

import Foundation

public enum ItemType: String {
    case Movie = "movie"
    case Show = "show"
}

public struct WatchItem {
    var name: String!
    var id: Int!
    var coverImage: String!
    var type: ItemType!
    
    var dictionaryRepresentation = [String : AnyObject]()
    
    init(name: String, id: Int, coverImage: String, type: String) {
        self.name = name
        self.id = id
        self.coverImage = coverImage
        self.type = ItemType(rawValue: type)
        
        self.dictionaryRepresentation = [
            "name": self.name,
            "id": self.id,
            "coverImage": self.coverImage,
            "type": self.type.rawValue
        ]
    }
    
    init(dictionary: [String : AnyObject]) {
        if let value = dictionary["name"] as? String {
            self.name = value
        }
        
        if let value = dictionary["id"] as? Int {
            self.id = value
        }
        
        if let value = dictionary["coverImage"] as? String {
            self.coverImage = value
        }
        
        if let value = dictionary["type"] as? String {
            self.type = ItemType(rawValue: value)
        }
    }
}

public class WatchlistManager {
    
    private var jsonFilePath: String! {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        if let path = paths.first {
            return String((path as NSString).stringByAppendingPathComponent("watchlist.json"))
        }
        return nil
    }
    
    class func sharedManager() -> WatchlistManager {
        struct Struct {
            static let Instance = WatchlistManager()
        }
        
        return Struct.Instance
    }
    
    init() {
        
    }
    
    // MARK: Public parts
    
    func addItemToWatchList(item: WatchItem, completion: ((added: Bool) -> Void)?) {
        self.itemExistsInWatchList(itemId: item.id, forType: item.type) { exists in
            if exists {
                completion?(added: false)
            } else {
                self.readJSONFile { json in
                    if let json = json {
                        var mutableJson = json
                        mutableJson.append(item.dictionaryRepresentation)
                        self.writeJSONFile(mutableJson)
                        completion?(added: true)
                    } else {
                        var mutableJson = [[String : AnyObject]]()
                        mutableJson.append(item.dictionaryRepresentation)
                        self.writeJSONFile(mutableJson)
                        completion?(added: true)
                    }
                }
            }
        }
    }
    
    func removeItemFromWatchList(item: WatchItem, completion: ((removed: Bool) -> Void)?) {
        self.readJSONFile { json in
            if let json = json {
                var mutableJson = json
                if let index = json.indexOf({ $0["id"] as! Int == item.id && $0["type"] as! String == item.type.rawValue }) {
                    mutableJson.removeAtIndex(index)
                    self.writeJSONFile(mutableJson)
                    completion?(removed: true)
                }
            }
        }
    }
    
    func fetchWatchListItems(forType type: ItemType, completion: (([WatchItem]) -> Void)?) {
        self.readJSONFile { json in
            if let json = json {
                var parsedItems = [WatchItem]()
                for item in json {
                    if let itemType = item["type"] as? String {
                        if itemType == type.rawValue {
                            parsedItems.append(WatchItem(dictionary: item))
                        }
                    }
                }
                completion?(parsedItems)
            }
        }
    }
    
    func itemExistsInWatchList(itemId id: Int, forType type: ItemType, completion: ((exists: Bool) -> Void)?) {
        self.readJSONFile { json in
            if let json = json {
                if let _ = json.indexOf({ $0["id"] as! Int == id && $0["type"] as! String == type.rawValue }) {
                    completion?(exists: true)
                } else {
                    completion?(exists: false)
                }
            }
        }
    }
    
    // MARK: Private parts
    
    func readJSONFile(completion: ((json: [[String : AnyObject]]?) -> Void)?) {
        if let jsonFilePath = self.jsonFilePath {
            if let data = NSData(contentsOfFile: jsonFilePath) {
                do {
                    if let response = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [[String : AnyObject]] {
                        completion?(json: response)
                    }
                } catch {
                    fatalError("Could not parse Watchlist")
                }
            } else {
                completion?(json: nil)
            }
        }
    }
    
    func writeJSONFile(json: [[String : AnyObject]]) {
        do {
            print(json)
            let json = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
            try json.writeToFile(self.jsonFilePath, options: .AtomicWrite)
        } catch {
            fatalError("Could not write Watchlist to JSON")
        }
    }
}
