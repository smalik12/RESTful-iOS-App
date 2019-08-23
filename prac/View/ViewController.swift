//
//  ViewController.swift
//  prac
//
//  Created by Saqib Malik on 8/15/19.
//  Copyright © 2019 Saqib Malik. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    // MARK: - Outlets
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(DetailTableViewCell.self, forCellReuseIdentifier: "cell")
        
        return tableView
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()
    
    // MARK: - Properties
    var products = [Product]()
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .groupTableViewBackground
        
        setupNavigationController()
        setupTableView()
        setupActivityIndicatorView()
        setupRefreshControl()
        
        NetworkManager.fetchProducts(completion: {
            self.completeRequest()
        })
    }
    
    // MARK: - Methods
    fileprivate func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    }

    fileprivate func setupNavigationController() {
        title = "Products"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addProduct))
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    fileprivate func setupRefreshControl() {
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Product Data...")
        refreshControl.addTarget(self, action: #selector(refreshProductData(_:)), for: .valueChanged)
    }
    
    private func completeRequest() {
        self.products = NetworkManager.products
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func setupActivityIndicatorView() {
        activityIndicatorView.startAnimating()
    }

    // MARK: - Actions
    @objc func addProduct() {
        let alertController = UIAlertController(title: "New Product", message: "Enter your product below", preferredStyle: .alert)
        
        // Here we can edit the properties of the text field within the alert
        alertController.addTextField { (textField) in
            textField.placeholder = "Write your product name here..."
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Write your product price here..."
            textField.keyboardType = .decimalPad
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { (ac) in
            if let productName = alertController.textFields?[0].text, let productPrice = alertController.textFields?[1].text {
                let prodPrice = Int(productPrice) ?? -1
                
                NetworkManager.createProduct(productName: productName, productPrice: prodPrice, completion: {
                    self.completeRequest()
                })
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }
    
    @objc private func refreshProductData(_ sender: Any) {
        NetworkManager.fetchProducts {
            self.completeRequest()
            
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.activityIndicatorView.stopAnimating()
            }
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    // Set the size of tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    // Create the cells of tableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DetailTableViewCell
        
        cell.productName.text = products[indexPath.row].name
        cell.productPrice.text = String(products[indexPath.row].price)
        
        return cell
    }
    
    // Table View Cells can be edited
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Delete tableView cell
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            NetworkManager.deleteProduct(productId: products[indexPath.row]._id, index: indexPath.row, completion: {
                self.completeRequest()
            })
        }
    }
    
    // Select tableView cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Update Product", message: "Enter your product below", preferredStyle: .alert)
        
        // Here we can edit the properties of the text field within the alert
        alertController.addTextField { (textField) in
            textField.placeholder = "Write your product name here..."
            textField.text = self.products[indexPath.row].name
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Write your product price here..."
            textField.keyboardType = .decimalPad
            textField.text = String(self.products[indexPath.row].price)
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { (ac) in
            if let productName = alertController.textFields?[0].text, let productPrice = alertController.textFields?[1].text {
                let productId = self.products[indexPath.row]._id
                let prodPrice = Int(productPrice) ?? -1
                
                let updatedProduct = Product(_id: productId, name: productName, price: prodPrice)
                NetworkManager.updateProduct(product: updatedProduct, index: indexPath.row, completion: {
                    self.completeRequest()
                })
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            tableView.deselectRow(at: indexPath, animated: true)
        })
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }
}
