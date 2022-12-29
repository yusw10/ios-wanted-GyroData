//
//  ViewController.swift
//  GyroData
//
//  Created by kjs on 2022/09/16.
//

import UIKit

class ViewController: UIViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, Gyro>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Gyro>
    
    private var dataSource: DataSource?
    private var snapshot: Snapshot?
    private let gyroStore = GyroStore(dataStack: CoreDataStack())
    private var numberOfItem = 10
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(FirstTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDefaultSetting()
        configureLayout()
        configureDataSource()
        configureSnapshot(itemCount: self.numberOfItem)
    }
    
    private func configureDataSource() {
        self.dataSource = DataSource(tableView: self.tableView) { tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? FirstTableViewCell
            else {
                return UITableViewCell()
            }
            cell.setText(date: item.measurementDate!, type: item.sensorType!, time: "\(item.measurementTime)")
            
            return cell
        }
    }
    
    private func configureSnapshot(itemCount: Int) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        
        do {
            let gyroData = try gyroStore.read(limitCount: itemCount)
            snapshot.appendItems(gyroData)
        } catch {
            print("error")
        }
        
        self.snapshot = snapshot
        self.dataSource?.apply(self.snapshot!, animatingDifferences: false)
    }
    
    private func configureDefaultSetting() {
        self.view.backgroundColor = .white
        self.tableView.delegate = self
        self.navigationItem.title = "목록"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "측정",
            style: .plain,
            target: self,
            action: #selector(didTappedRightBarButton)
        )
    }

    private func configureLayout() {
        self.view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func didTappedRightBarButton(sender: UIButton) {
        let recordViewController = RecordViewController()
        recordViewController.recordViewControllerPopProtocol = self
        self.navigationController?.pushViewController(recordViewController, animated: true)
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let playAction = UIContextualAction(style: .normal, title: "Play") { (UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
            print("Play")
            success(true)
        }
        playAction.backgroundColor = .systemGreen
        
        let deleteAction = UIContextualAction(style: .normal, title: "Delete") { (UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
            let cell = tableView.cellForRow(at: indexPath) as! FirstTableViewCell
            let date = cell.getDate()
            let deleteData = try! self.gyroStore.readDetailData(measurementDate: date!)
            try! self.gyroStore.delete(measurementDate: date!)
            self.snapshot?.deleteItems(deleteData)
            self.dataSource?.apply(self.snapshot!)
            
            success(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [deleteAction, playAction])
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        let tableViewContentSize = tableView.contentSize.height
        let paginationY = tableViewContentSize * 0.8

        if contentOffsetY > tableViewContentSize - paginationY {
            guard gyroStore.getEntityCount() > numberOfItem else {
                return
            }
            
            numberOfItem += 10
            configureSnapshot(itemCount: numberOfItem)
        }
    }
}

//TODO: 뷰컨에서 넘어오는 데이터 처리 구현 해주시면됩니당

extension ViewController: RecordViewControllerPopDelegate {
    func saveMeasureData(registTime: Date, type: SensorType, samplingCount: Double) {
        let date = DateFormatterManager.shared.convertToDateString(from: registTime)
        let sensorType = type.rawValue
        let measurementTime = samplingCount
        
        let coreDataDict: [String: Any] = ["measurementDate": date, "measurementTime": measurementTime, "sensorType": sensorType]
        
        do {
            try self.gyroStore.create(by: coreDataDict)
            configureSnapshot(itemCount: numberOfItem)
        } catch {
            print(error)
        }
    }
}

//TODO: 폴더 정리 필요!!
class DateFormatterManager {
    static let shared = DateFormatterManager()
    private let formatter = DateFormatter()
    
    var dateFormatter: DateFormatter {
        self.formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter
    }
    
    func convertToDateString(from date: Date) -> String {
        return self.dateFormatter.string(from: date)
    }
}
