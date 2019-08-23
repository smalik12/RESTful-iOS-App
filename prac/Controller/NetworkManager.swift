//
//  NetworkManager.swift
//  prac
//
//  Created by Saqib Malik on 8/23/19.
//  Copyright © 2019 Saqib Malik. All rights reserved.
//

import Foundation

class NetworkManager {
    // MARK: - Properties
    // Internal products array that can be modified to our desire
    private static var internalProductsArr: [Product] = []
    
    // External read-only products array that is accessible to the public
    static var products: [Product] {
        get {
            return internalProductsArr
        }
    }
    
    // MARK: - Init
    // Private constructor to conform to Singleton pattern
    private init() {}
    
    // MARK: - Methods
    // GET Request
    static func fetchProducts(completion: @escaping () -> () = {}) {
        let url = "http://localhost:3000/products/"
        guard let urlObj = URL(string: url) else { return }
        
        URLSession.shared.dataTask(with: urlObj) { (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            
            do {
                if let data = data {
                    self.internalProductsArr = try JSONDecoder().decode([Product].self, from: data)
                    completion()
                }
            } catch {
                print(error)
            }
        }.resume()
    }
    
    // POST Request
    static func createProduct(productName: String, productPrice: Int, completion: @escaping () -> () = {}) {
        let url = "http://localhost:3000/products/create"
        guard let urlObj = URL(string: url) else { return }
        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json: [String: Any] = [
            "name": productName,
            "price": productPrice
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
            if let error = error {
                print(error)
                return
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print(dataString)
                
                self.fetchProducts(completion: {
                    completion()
                })
            }
        }.resume()
    }
    
    // DELETE Request
    static func deleteProduct(productId: String, index: Int, completion: @escaping () -> () = {}) {
        let firstEndpoint: String = "http://localhost:3000/products/\(productId)"
        var firstUrlRequest = URLRequest(url: URL(string: firstEndpoint)!)
        firstUrlRequest.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: firstUrlRequest) { (data, response, error) in
            if let error = error {
                print(error)
                print("Error deleting product with product ID: \(productId)")
                return
            }
            
            if let _ = data {
                print("Successfully deleted product with product ID: \(productId)")
                self.internalProductsArr.remove(at: index)
                completion()
            }
        }.resume()
    }
    
    // PUT Request
    static func updateProduct(product: Product, index: Int, completion: @escaping () -> () = {}) {
        let url = URL(string: "http://localhost:3000/products/\(product._id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json: [String: Any] = [
            "id": product._id,
            "name": product.name,
            "price": product.price
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print(dataString)
                self.internalProductsArr[index] = product
                completion()
            }
        }.resume()
    }
}
