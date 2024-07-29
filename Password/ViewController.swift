//
//  ViewController.swift
//  Password
//
//  Created by student on 7/18/24.
//
import UIKit

class ViewController: UIViewController {
    
    var services: [Service] = []
    var selectedRowIndex: Int?
    var isDeleteModeOn = false // Track if delete mode is on or off
    
    @IBOutlet weak var userID: UITextField!
    @IBOutlet weak var serviceName: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var adminPassword: String? {
        get {
            return UserDefaults.standard.string(forKey: "admin password")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "admin password")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadServicesFromUserDefaults()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if adminPassword == nil {
            presentAlert(title: "Welcome", message: "Set your admin password", textFieldPlaceholder: "Enter password", defaultButtonTitle: "Submit") { [weak self] textFieldText in
                self?.adminPassword = textFieldText
            }
        }
    }
    
    @IBAction func deleteModeOn(_ sender: Any) {
        // Toggle delete mode on or off
        isDeleteModeOn.toggle()
        
        if isDeleteModeOn {
            // If delete mode is turned on, ask for admin password
            presentAdminPasswordAlert { [weak self] isAdmin in
                if isAdmin {
                    // Admin password correct, show delete mode active alert
                    self?.presentAlert(title: "Delete Mode", message: "Delete mode is now active. Tap on a service to delete it.", titleOftheButton: "OK")
                } else {
                    // Admin password incorrect, toggle delete mode off
                    self?.isDeleteModeOn = false
                    self?.presentAlert(title: "Unauthorized", message: "Incorrect admin password.", titleOftheButton: "OK")
                }
            }
        }
    }
    
    func presentDeleteConfirmation(service: Service, at rowIndex: Int) {
        let alertController = UIAlertController(title: "Confirm Deletion", message: "Are you sure you want to delete this service?", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            // Remove the service from the array
            self?.services.remove(at: rowIndex)
            
            // Update table view and save to UserDefaults
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
            self?.saveServicesToUserDefaults()
            
            // Turn off delete mode after deletion
            self?.isDeleteModeOn = false
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func viewButtonClick(_ sender: UIButton) {
        guard let selectedRow = selectedRowIndex else {
            print("Error: selectedRowIndex is nil")
            return
        }
        
        let service = services[selectedRow]
        
        if isDeleteModeOn {
            // If delete mode is on, present delete confirmation
            presentDeleteConfirmation(service: service, at: selectedRow)
        } else {
            // Otherwise, ask for admin password before showing service details
            presentAdminPasswordAlert { [weak self] isAdmin in
                if isAdmin {
                    self?.presentViewAlert(service: service, at: selectedRow)
                } else {
                    self?.presentAlert(title: "Unauthorized", message: "Incorrect admin password.", titleOftheButton: "OK")
                }
            }
        }
    }
    
    @IBAction func editButtonClick(_ sender: Any) {
        guard let selectedRow = selectedRowIndex else {
            print("Error: selectedRowIndex is nil")
            return
        }
        
        if isDeleteModeOn {
            // If delete mode is on, present delete confirmation
            presentDeleteConfirmation(service: services[selectedRow], at: selectedRow)
        } else {
            // Otherwise, ask for admin password before presenting edit alert
            presentAdminPasswordAlert { [weak self] isAdmin in
                if isAdmin {
                    self?.presentEditAlert(service: self?.services[selectedRow] ?? Service(name: "", userName: "", password: ""), at: selectedRow)
                } else {
                    self?.presentAlert(title: "Unauthorized", message: "Incorrect admin password.", titleOftheButton: "OK")
                }
            }
        }
    }
    
    func presentViewAlert(service: Service, at rowIndex: Int) {
        let alertController = UIAlertController(title: "View Service", message: "View service details", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Service Name"
            textField.text = service.name
            textField.isEnabled = false
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "User ID"
            textField.text = service.userName
            textField.isEnabled = false
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Password"
            textField.text = service.password
            textField.isEnabled = false
        }
        
        let cancelAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func presentEditAlert(service: Service, at rowIndex: Int) {
        let alertController = UIAlertController(title: "Edit Service", message: "Enter new details", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Service Name"
            textField.text = service.name
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "User ID"
            textField.text = service.userName
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Password"
            textField.text = service.password
            textField.isSecureTextEntry = true
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let serviceName = alertController.textFields?[0].text, !serviceName.isEmpty,
                  let userID = alertController.textFields?[1].text, !userID.isEmpty,
                  let password = alertController.textFields?[2].text, !password.isEmpty else {
                self?.presentAlert(title: "Error", message: "All fields are required.", titleOftheButton: "OK")
                return
            }
            
            // Update the service in the array
            self?.services[rowIndex].name = serviceName
            self?.services[rowIndex].userName = userID
            self?.services[rowIndex].password = password
            
            // Update table view and save to UserDefaults
            DispatchQueue.main.async {
                self?.tableView.reloadRows(at: [IndexPath(row: rowIndex, section: 0)], with: .automatic)
            }
            self?.saveServicesToUserDefaults()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func addButtonClick(_ sender: Any) {
        guard let serviceName = serviceName.text, !serviceName.isEmpty,
              let userIDText = userID.text, !userIDText.isEmpty,
              let passwordText = password.text, !passwordText.isEmpty else {
            presentAlert(title: "Error", message: "Require service name, UserID, and Password.", titleOftheButton: "OK")
            return
        }
        
        // Check if service name already exists
        if services.contains(where: { $0.name == serviceName }) {
            presentAlert(title: "Error", message: "Service name already exists", titleOftheButton: "OK")
            return
        }
        
        // Add new service
        let newService = Service(name: serviceName, userName: userIDText, password: passwordText)
        services.append(newService)
        
        // Update table view and save to UserDefaults
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        saveServicesToUserDefaults()
    }
    
    func saveServicesToUserDefaults() {
        do {
            let encodedData = try JSONEncoder().encode(services)
            UserDefaults.standard.set(encodedData, forKey: "services")
        } catch {
            print("Error encoding services: \(error.localizedDescription)")
        }
    }
    
    func loadServicesFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "services") {
            do {
                services = try JSONDecoder().decode([Service].self, from: data)
            } catch {
                print("Error decoding services: \(error.localizedDescription)")
            }
        }
    }
    
    func presentAlert(title: String,
                      message: String,
                      titleOftheButton: String? = nil,
                      textFieldPlaceholder: String? = nil,
                      defaultButtonTitle: String? = nil,
                      defaultButtonAction: ((_ textFieldText: String?) -> Void)? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let textFieldPlaceholder = textFieldPlaceholder {
            alertController.addTextField { textField in
                textField.placeholder = textFieldPlaceholder
            }
        }
        
        if let defaultButtonTitle = defaultButtonTitle {
            let defaultAction = UIAlertAction(title: defaultButtonTitle, style: .default) { _ in
                let textFieldText = alertController.textFields?.first?.text
                defaultButtonAction?(textFieldText)
            }
            alertController.addAction(defaultAction)
        }
        
        if let titleOftheButton = titleOftheButton {
            let cancelAction = UIAlertAction(title: titleOftheButton, style: .cancel) { _ in
                print("\(titleOftheButton) tapped")
            }
            alertController.addAction(cancelAction)
        }
        
        present(alertController, animated: true, completion: nil)
    }
}

struct Service: Codable {
    var name: String
    var userName: String
    var password: String
    var showPassword: Bool = false // Default to false
    
    mutating func togglePasswordVisibility() {
        showPassword.toggle()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceCell", for: indexPath)
        let service = services[indexPath.row]
        
        // Configure the cell with serviceName and userID
        cell.textLabel?.text = "\(service.name) - \(service.userName)"
        
        if service.showPassword {
            cell.detailTextLabel?.text = service.password
        } else {
            cell.detailTextLabel?.text = "********" // Placeholder for password
        }
        
        // Add view button with action
        let viewButton = UIButton(type: .system)
        viewButton.setTitle("View", for: .normal)
        viewButton.addTarget(self, action: #selector(viewButtonClick(_:)), for: .touchUpInside)
        cell.accessoryView = viewButton
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Set selectedRowIndex for editButtonClick
        selectedRowIndex = indexPath.row
        
        if isDeleteModeOn {
            // If delete mode is on, directly present delete confirmation
            presentDeleteConfirmation(service: services[indexPath.row], at: indexPath.row)
        } else {
            // Otherwise, ask for admin password before showing service details
            presentAdminPasswordAlert { [weak self] isAdmin in
                if isAdmin {
                    self?.presentViewAlert(service: self?.services[indexPath.row] ?? Service(name: "", userName: "", password: ""), at: indexPath.row)
                } else {
                    self?.presentAlert(title: "Unauthorized", message: "Incorrect admin password.", titleOftheButton: "OK")
                }
            }
        }
    }
    
    func presentAdminPasswordAlert(completion: @escaping (_ isAdmin: Bool) -> Void) {
        let alertController = UIAlertController(title: "Admin Password Required", message: "Enter your admin password to continue", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Admin Password"
            textField.isSecureTextEntry = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            guard let passwordTextField = alertController.textFields?.first,
                  let enteredPassword = passwordTextField.text,
                  let adminPassword = self?.adminPassword,
                  enteredPassword == adminPassword else {
                completion(false)
                return
            }
            
            completion(true)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(submitAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
