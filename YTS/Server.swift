//
//  Server.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import Swifter

protocol ServerDelegate {
    func serverStateDidUpdate(running: Bool)
    func serverFailure(error: ServerError)
}

enum ServerError: Error {
    case OSNotSupported, NoStart
    
    var localizedDescription: String {
        switch self {
        case .OSNotSupported:
            return "OS not supported"
        case .NoStart:
            return "Server could not be started"
        }
    }
}

class Server {
    
    static let sharedInstance: Server = {
        let instance = Server()
        return instance
    }()
    
    var delegate: ServerDelegate?
    
    private let server = HttpServer()
    private let moviesAPI = MoviesAPI()
    
    private let settings = UserDefaults.standard
    
    public func start() {
        if #available(OSXApplicationExtension 10.10, *) {
            do {
                try self.server.start(UInt16(settings.integer(forKey: "serverPort")), forceIPv4: true)
                self.afterStart()
            } catch {
                self.delegate?.serverFailure(error: ServerError.NoStart)
            }
        } else {
            self.delegate?.serverFailure(error: ServerError.OSNotSupported)
        }
    }
    
    private func afterStart() {
        if self.server.state != .running {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
                self.afterStart()
            })
        } else {
            self.delegate?.serverStateDidUpdate(running: true)
            self.startMoviesAPI()
            self.startShowsAPI()
        }
    }
    
    public func stop() {
        self.server.stop()
        self.afterStop()
    }
    
    private func afterStop() {
        if server.state != .stopped {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
                self.afterStop()
            })
        } else {
            delegate?.serverStateDidUpdate(running: false)
        }
    }
    
    public func restart() {
        self.stop()
        self.start()
    }
    
    private func startMoviesAPI() {
        
        // List Movies
        self.server["/api/v2/list_movies.json"] = { r in
            
            let start = Date()
            
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
            
            let data = self.moviesAPI.moviesInfo(params: params)
            
            var response = [String:Any]()
            if data.count > 0 {
                response["status"] = "ok"
                response["status_message"] = "Query was successful"
                response["data"] = data
            } else {
                response["status"] = "error"
                response["status_message"] = "Query not successful"
            }
            
            response["@meta"] = self.metaInfo(executionTime: Date().timeIntervalSince(start))
            return HttpResponse.ok(HttpResponseBody.json(response as AnyObject))
        }
        
        // Movie Details
        self.server["/api/v2/movie_details.json"] = { r in
            let start = Date()
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
            
            response["@meta"] = self.metaInfo(executionTime: Date().timeIntervalSince(start))
            return HttpResponse.ok(HttpResponseBody.json(response as AnyObject))
        }
        
    }
        
    private func startShowsAPI() {
        
    }
    
    // Meta
    func metaInfo(executionTime: Double) -> [String: Any] {
        var meta = [String: Any]()
        meta["server_time"] = Date.timeIntervalBetween1970AndReferenceDate
        meta["server_timezone"] = TimeZone.current.identifier
        meta["api_version"] = 2
        meta["execution_time"] = executionTime
        return meta
    }
}
