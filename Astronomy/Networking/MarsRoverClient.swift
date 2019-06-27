//
//  MarsRoverClient.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation

class MarsRoverClient {
    
    func fetchMarsRover(named name: String,
                        using session: URLSession = URLSession.shared,
                        completion: @escaping (MarsRover?, Error?) -> Void) {
        
        if isUITesting {
            localMarsRover(completion: completion)
            return
        }
        
        let url = self.url(forInfoForRover: name)
        fetch(from: url, using: session) { (dictionary: [String : MarsRover]?, error: Error?) in

            guard let rover = dictionary?["photo_manifest"] else {
                completion(nil, error)
                return
            }
            completion(rover, nil)
        }
    }
    
    func localMarsRover(completion: @escaping (MarsRover?, Error?) -> Void) {
        
        guard let roverURL = Bundle.main.url(forResource: "MarsRover", withExtension: "json", subdirectory: nil) else { fatalError("URL to local Rover JSON is nil") }
        
        do {
            let data = try Data(contentsOf: roverURL)
            
            let jsonDecoder = MarsPhotoReference.jsonDecoder
            
            let rover = try jsonDecoder.decode([String: MarsRover].self, from: data)["photo_manifest"]
            
            completion(rover, nil)
            
        } catch {
            NSLog("Error loading local Mars Rover: \(error)")
            completion(nil, error)
        }
        
    }
    
    func fetchPhotos(from rover: MarsRover,
                     onSol sol: Int,
                     using session: URLSession = URLSession.shared,
                     completion: @escaping ([MarsPhotoReference]?, Error?) -> Void) {
        
        if isUITesting {
            fetchLocalPhotos(from: rover, onSol: sol, completion: completion)
            return
        }

        let url = self.url(forPhotosfromRover: rover.name, on: sol)
        fetch(from: url, using: session) { (dictionary: [String : [MarsPhotoReference]]?, error: Error?) in
            guard let photos = dictionary?["photos"] else {
                completion(nil, error)
                return
            }
            completion(photos, nil)
        }
    }
    
    func fetchLocalPhotos(from rover: MarsRover,
                          onSol sol: Int,
                          completion: @escaping ([MarsPhotoReference]?, Error?) -> Void) {
        
        guard let localPhotosURL = Bundle.main.url(forResource: "PhotoReferences", withExtension: "json") else { fatalError("PhotoReferences.json URL is nil") }
        
        do {
            let data = try Data(contentsOf: localPhotosURL)
            
            let jsonDecoder = MarsPhotoReference.jsonDecoder
            
            let references = try jsonDecoder.decode([String: [String: [MarsPhotoReference]]].self, from: data)
            
            let photos = references["\(sol)"]?["photos"]
            
            completion(photos, nil)
        } catch {
            NSLog("Unable to fetch local photos for sol \(sol): \(error)")
            completion(nil, error)
        }
    }
    
    // MARK: - Private
    
    private func fetch<T: Codable>(from url: URL,
                           using session: URLSession = URLSession.shared,
                           completion: @escaping (T?, Error?) -> Void) {
        session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "com.LambdaSchool.Astronomy.ErrorDomain", code: -1, userInfo: nil))
                return
            }
            
            do {
                let jsonDecoder = MarsPhotoReference.jsonDecoder
                let decodedObject = try jsonDecoder.decode(T.self, from: data)
                completion(decodedObject, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    private let baseURL = URL(string: "https://api.nasa.gov/mars-photos/api/v1")!
    private let apiKey = "qzGsj0zsKk6CA9JZP1UjAbpQHabBfaPg2M5dGMB7"

    private func url(forInfoForRover roverName: String) -> URL {
        var url = baseURL
        url.appendPathComponent("manifests")
        url.appendPathComponent(roverName)
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        return urlComponents.url!
    }
    
    private func url(forPhotosfromRover roverName: String, on sol: Int) -> URL {
        var url = baseURL
        url.appendPathComponent("rovers")
        url.appendPathComponent(roverName)
        url.appendPathComponent("photos")
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "sol", value: String(sol)),
                                    URLQueryItem(name: "api_key", value: apiKey)]
        return urlComponents.url!
    }
}
