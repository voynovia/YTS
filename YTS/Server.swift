//
//  Server.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import Swifter

class Server {
    
    static let sharedInstance: Server = {
        let instance = Server()
        return instance
    }()
    
    private let server = HttpServer()
    private let moviesAPI = MoviesAPI()
    
    private let settings = UserDefaults.standard
        
    public func start() {
        self.startServer()
        self.startAPI()
    }
    
    private func startAPI() {
        while server.state != .running {
            print("Waiting for the server start")
            Timer.scheduledTimer(withTimeInterval: TimeInterval(0.5), repeats: false, block: { _ in self.startAPI() })
        }
        self.startMovieAPI()
        self.startShowAPI()
    }
    
    private func startServer() {
        if #available(OSXApplicationExtension 10.10, *) {
            do {
                try server.start(UInt16(settings.integer(forKey: "serverPort")), forceIPv4: true)
                print("Server has started ( port = \(try server.port()) ). Try to connect now...")
            } catch {
                print("Server start error: \(error)")
            }

        } else {
            print("OS not supported")
        }
    }
    
    public func stop() {
        server.stop()
    }
    
    public func restart() {
        server.stop()
        while server.state != .stopped {
            print("Waiting for the server stop")
            Timer.scheduledTimer(withTimeInterval: TimeInterval(0.5), repeats: false, block: { _ in self.restart() })
        }
        self.start()
    }
    
    private func startMovieAPI() {
        
        // List Movies
        self.server["/api/v2/list_movies.json"] = { r in
            
            var params = self.moviesAPI.params
            
            if let genreParam = r.queryParams.first(where: {$0.0 == "genre" }) {
                params.genre = genreParam.1
            }
            if let pageParam = r.queryParams.first(where: {$0.0 == "page" }) {
                params.page = Int(pageParam.1)! // проверка на ошибку преобразования в цифру
            }
            if let limitParam = r.queryParams.first(where: {$0.0 == "limit" }) {
                params.limit = Int(limitParam.1)! // проверка на ошибку преобразования в цифру
            }
            if let queryParam = r.queryParams.first(where: {$0.0 == "query_term" }) {
                params.query_term = queryParam.1.lowercased().trim()
            }
            if let sortParam = r.queryParams.first(where: {$0.0 == "sort_by" }) {
                params.sort_by = sortParam.1.lowercased().trim()
            }
            
            var response = [String:Any]()
            let data = self.moviesAPI.moviesInfo(params: params)
            if data.count > 0 {
                response["status"] = "ok"
                response["status_message"] = "Query was successful"
                response["data"] = data
            } else {
                response["status"] = "error"
                response["status_message"] = "Query not successful"
            }
            response["meta"] = self.moviesAPI.metaInfo()
            return HttpResponse.ok(HttpResponseBody.json(response as AnyObject))
        }
        
        // Movie Details
        self.server["/api/v2/movie_details.json"] = { r in
            var response = [String:Any]()
            if let idParam = r.queryParams.first(where: {$0.0 == "movie_id" }), let id = Int(idParam.1) {
                let data = self.moviesAPI.detailInfo(id: id)
                if data.count > 0 {
                    response["status"] = "ok"
                    response["status_message"] = "Query was successful"
                    response["data"] = data
                } else {
                    response["status"] = "error"
                    response["status_message"] = "movie_id does not exist"
                }
            }
            response["meta"] = self.moviesAPI.metaInfo()
            return HttpResponse.ok(HttpResponseBody.json(response as AnyObject))
        }
    }
    
    private func startShowAPI() {
        
    }
}
