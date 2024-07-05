//
//  AppsViewController.swift
//  feather
//
//  Created by samara on 5/19/24.
//

import UIKit
import CoreData

class AppsViewController: UIViewController {
	let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	var tableView: UITableView!
	
	var downlaodedApps: [DownloadedApps]?
	var signedApps: [SignedApps]?

	lazy var importButton = addAddButtonToView(title: nil, image: UIImage(systemName: "folder.fill"))
	let segmentedControl: UISegmentedControl = {
		let sc = UISegmentedControl(items: ["Unsigned", "Signed"])
		sc.selectedSegmentIndex = 0
		return sc
	}()

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(false)
		fetchSources()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupViews()
		setupNavigation()
		fetchSources()
	}
	
	fileprivate func setupViews() {
		self.segmentedControl.translatesAutoresizingMaskIntoConstraints = false
		self.segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
		
		self.tableView = UITableView(frame: .zero, style: .plain)
		self.tableView.translatesAutoresizingMaskIntoConstraints = false
		self.view.backgroundColor = UIColor(named: "Background")
		self.tableView.backgroundColor = UIColor(named: "Background")
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.register(SourceAppTableViewCell.self, forCellReuseIdentifier: "RoundedBackgroundCell")
		
		let containerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 34))
		containerView.addSubview(segmentedControl)
		
		NSLayoutConstraint.activate([
			segmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor),
			segmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
			segmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
			segmentedControl.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
		])
		
		self.tableView.tableHeaderView = containerView
		
		self.view.addSubview(tableView)

		NSLayoutConstraint.activate([
			tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
		
		//		self.makImportButtonMenu()
		view.addSubview(importButton)
		NSLayoutConstraint.activate([
			importButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -20),
			importButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -10),
			importButton.widthAnchor.constraint(equalToConstant: 45),
			importButton.heightAnchor.constraint(equalToConstant: 45)
		])
		
	}

	
	fileprivate func setupNavigation() {
//		self.navigationController?.navigationBar.prefersLargeTitles = true
//		self.navigationItem.largeTitleDisplayMode = .always
		
//		var leftBarButtonItems: [UIBarButtonItem] = []
//		var rightBarButtonItems: [UIBarButtonItem] = []
//		
//		navigationItem.leftBarButtonItems = leftBarButtonItems
//		navigationItem.rightBarButtonItems = rightBarButtonItems
	}
	
	@objc func segmentChanged(_ sender: UISegmentedControl) {
		tableView.reloadData()
	}
}

extension AppsViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return nil }
	func numberOfSections(in tableView: UITableView) -> Int { return 1 }
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch segmentedControl.selectedSegmentIndex {
		case 0:
			return downlaodedApps?.count ?? 0
		case 1:
			return signedApps?.count ?? 0
		default:
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = AppsTableViewCell(style: .subtitle, reuseIdentifier: "RoundedBackgroundCell")
		cell.selectionStyle = .default
		cell.accessoryType = .none
		cell.backgroundColor = UIColor(named: "Background")
		
		let source = getApplication(row: indexPath.row)
		let size = CGSize(width: 52, height: 52)
		let radius = 12
		let filePath = getApplicationFilePath(with: source!, row: indexPath.row)
		if let iconURL = source!.value(forKey: "iconURL") as? String {
			let imagePath = filePath.appendingPathComponent(iconURL)
			
			if let image = self.loadImage(from: imagePath) {
				SectionIcons.sectionImage(to: cell, with: image, size: size, radius: radius)
			} else {
				SectionIcons.sectionImage(to: cell, with: UIImage(named: "unknown")!, size: size, radius: radius)
			}
		} else {
			SectionIcons.sectionImage(to: cell, with: UIImage(named: "unknown")!, size: size, radius: radius)
		}

		
		cell.configure(with: source!, filePath: filePath)

		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let meow = getApplication(row: indexPath.row)
//		var source: NSManagedObject?
		let filePath = getApplicationFilePath(with: meow!, row: indexPath.row)
//		showAlertWithImageAndBoldText(with: meow!, filePath: filePath)
		print(meow!)
//		switch segmentedControl.selectedSegmentIndex {
//		case 0:
//			source = self.downlaodedApps?[indexPath.row]
//			showAlertWithImageAndBoldText(with: meow!, filePath: filePath)
//		case 1:
//			source = signedApps?[indexPath.row]
//			break
//		default:
//			break
//		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		
		let source = getApplication(row: indexPath.row)
		let filePath = getApplicationFilePath(with: source!, row: indexPath.row, getuuidonly: true)
		
		
		let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completionHandler) in
			do {
				try FileManager.default.removeItem(at: filePath)
			} catch {
				print("Error deleting dir: \(error.localizedDescription)")
			}
			
			self.context.delete(source!)
			
			do {
				try self.context.save()
				
				switch self.segmentedControl.selectedSegmentIndex {
				case 0:
					self.downlaodedApps?.remove(at: indexPath.row)
				case 1:
					self.signedApps?.remove(at: indexPath.row)
				default:
					break
				}
				
				tableView.deleteRows(at: [indexPath], with: .automatic)
			} catch {
				print("Error deleting data: \(error.localizedDescription)")
			}
			
			completionHandler(true)
		}
		
		deleteAction.backgroundColor = UIColor.red
		let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
		configuration.performsFirstActionWithFullSwipe = true

		return configuration
	}
	
	func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		let source = getApplication(row: indexPath.row)
		let filePath = getApplicationFilePath(with: source!, row: indexPath.row)
		
		let configuration = UIContextMenuConfiguration(identifier: nil, actionProvider: { _ in
			return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [
				UIAction(title: "View Details", image: UIImage(systemName: "info.circle"), handler: {_ in
					

//					self.showAlertWithImageAndBoldText(with: source!, filePath: filePath)
					
					let viewController = AppsInformationViewController()
					viewController.source = source
					viewController.filePath = filePath
					let navigationController = UINavigationController(rootViewController: viewController)
					
					if #available(iOS 15.0, *) {
						if let presentationController = navigationController.presentationController as? UISheetPresentationController {
							presentationController.detents = [.medium(), .large()]
						}
					}
					
					self.present(navigationController, animated: true)
					

				}),
				
				UIAction(title: "Open in Files", image: UIImage(systemName: "folder"), handler: {_ in
					
					let path = filePath.deletingLastPathComponent()
					let path2 = path.absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
					
					UIApplication.shared.open(URL(string: path2)!, options: [:]) { success in
						if success {
							print("File opened successfully.")
						} else {
							print("Failed to open file.")
						}
					}
				})
				
			])
		})
		return configuration
	}
	
}

extension AppsViewController {
	func fetchSources() {

		do {
			
			switch segmentedControl.selectedSegmentIndex {
			case 0:
				let fetchRequest: NSFetchRequest<DownloadedApps> = DownloadedApps.fetchRequest()
				let sortDescriptor = NSSortDescriptor(key: "dateAdded", ascending: false)
				fetchRequest.sortDescriptors = [sortDescriptor]
				self.downlaodedApps = try context.fetch(fetchRequest)
			case 1:
				let fetchRequest: NSFetchRequest<SignedApps> = SignedApps.fetchRequest()
				let sortDescriptor = NSSortDescriptor(key: "dateAdded", ascending: false)
				fetchRequest.sortDescriptors = [sortDescriptor]
				self.signedApps = try context.fetch(fetchRequest)
			default:
				break
			}
						
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		} catch {
			print("Error fetching sources: \(error)")
		}
	}
}
