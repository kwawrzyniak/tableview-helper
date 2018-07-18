//
//  TableViewManager.swift
//  tableview_ribbon
//
//  Created by Karol Wawrzyniak on 18/07/2018.
//  Copyright © 2018 Fivedottwelve. All rights reserved.
//
import UIKit

public protocol ListProviderDelegate: class {
    
    func didStartFetching(_ data: [TableViewData]?)
    
    func didFinishFetching(_ data: [TableViewData]?)
    
    func didFinishFetchingWithError(_ error: NSError?)
    
}

public protocol ListProviderProtocol: class {
    
    var delegate: ListProviderDelegate? { get set }
    
    func requestData()
    
}

//TODO add assosiated type
public protocol TableViewData {
    
    var context: Any? { get set }
    
    func reuseID() -> String
    
    func height() -> CGFloat
    
    func canEdit() -> Bool
    
    func actions() -> [UITableViewRowAction]?
}


open class SectionTableData {
    
    open var data = [TableViewData]()
    
    open var headerReuseId: String?
    
    open var height: CGFloat?
    
    public init() {}
}

public extension TableViewData {
    
    func height() -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func canEdit() -> Bool {
        return false
    }
    
    func actions() -> [UITableViewRowAction]? {
        return nil
    }
    
}

public protocol UITableViewCellLoadableProtocol {
    
    func loadData(_ data: TableViewData, tableview: UITableView)
    
}

public protocol UITableViewHeaderLoadableProtocol {
    
    func loadData(_ data: SectionTableData, tableview: UITableView)
    
}

public protocol TableViewManagerDelegate: class {
    
    func didSelect(_ item: TableViewData)
    
    func pinDelegate(_ item: TableViewData)
    
}

public class TableViewManager: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    weak var tableView: UITableView!
    
    public weak var delegate: TableViewManagerDelegate?
    
    public private(set) var data = [SectionTableData]()
    
    public func reloadItem(item: TableViewData) {
        let array = self.data as NSArray
        let index = array.index(of: item)
        let indexPath = IndexPath(row: index, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    public func removeAllData() {
        self.data = [SectionTableData]()
    }
    
    func removeItem(item: TableViewData) {
        let array = self.data as NSArray
        let index = array.index(of: item)
        self.data.remove(at: index)
        tableView.reloadData()
    }
    
    public func removeItemAt(index: Int, section: Int = 0) {
        self.tableView?.beginUpdates()
        data[section].data.remove(at: index)
        let indexPath = IndexPath(row: index, section: section)
        tableView?.deleteRows(at: [indexPath], with: .fade)
        self.tableView.endUpdates()
    }
    
    public func insertData(items: [TableViewData], firstIndex: Int, section: Int = 0) {
        
        guard items.count > 0 else {
            return
        }
        
        items.forEach { (data) in
            self.registerItem(item: data)
        }
        
        self.tableView.beginUpdates()
        
        var index = firstIndex
        var indexPaths = [IndexPath]()
        let sectionItem = self.data[section]
        
        items.forEach { (data) in
            sectionItem.data.insert(data, at: index)
            let indexPath = IndexPath(row: index, section: section)
            indexPaths.append(indexPath)
            index = index + 1
        }
        
        self.tableView.insertRows(at: indexPaths, with: .fade)
        self.tableView.endUpdates()
        
    }
    
    public func add(section: SectionTableData) {
        
        guard let rId = section.headerReuseId else {
            return
        }
        
        guard let className = NSClassFromString(rId) else {
            return
        }
        
        let bundle = Bundle(for: className)
        let nibName = rId.components(separatedBy: ".")[1]
        let nib = UINib(nibName: nibName, bundle: bundle)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: rId)
        
        for item in section.data {
            self.registerItem(item: item)
        }
        
        self.data.append(section)
        self.tableView.reloadData()
        
    }
    
    public func addData(_ items: [TableViewData]?) {
        
        guard let items = items else {
            return
        }
        
        guard items.count > 0 else {
            return
        }
        
        let count = self.data.count
        var indexPaths = [IndexPath]()
        
        if count == 0 {
            let section = SectionTableData()
            section.data.append(contentsOf: items)
            
            for data in section.data {
                self.registerItem(item: data)
            }
            self.data.append(section)
            self.tableView.reloadData()
            return
        }
        
        guard let sectionData = self.data.last else {
            return
        }
        
        CATransaction.begin()
        
        self.tableView.beginUpdates()
        
        sectionData.data.append(contentsOf: items)
        
        for (index, item) in items.enumerated() {
            registerItem(item: item)
            let indexPath = IndexPath(row: count + index, section: 0)
            indexPaths.append(indexPath)
        }
        
        self.tableView?.insertRows(at: indexPaths, with: .automatic)
        self.tableView?.endUpdates()
        
        CATransaction.commit()
        
    }
    
    func registerItem(reuseID: String) {
        if let className = NSClassFromString(reuseID) {
            let bundle = Bundle(for: className)
            let nibName = reuseID.components(separatedBy: ".")[1]
            
            self.tableView?.register(UINib(nibName: nibName, bundle: bundle), forCellReuseIdentifier: reuseID)
        }
    }
    
    func registerItem(item: TableViewData) {
        let reuseID = item.reuseID()
        self.registerItem(reuseID: reuseID)
    }
    
    public init(tableView: UITableView) {
        super.init()
        self.tableView = tableView
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 100
        self.tableView.separatorColor = UIColor.clear
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.separatorStyle = .none
        self.data = [SectionTableData]()
    }
    
    public convenience init(tableView: UITableView, reuseIDs: [String]) {
        self.init(tableView: tableView)
        
        for reuseID in reuseIDs {
            self.registerItem(reuseID: reuseID)
        }
    }
    
    @objc public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data[section].data.count
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.data.count
    }
    
    @objc public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = self.data[indexPath.section]
        let dataItem = section.data[indexPath.row]
        
        let reuseID = dataItem.reuseID()
        let tableCell = tableView.dequeueReusableCell(withIdentifier: reuseID)
        
        if let loadableCell = tableCell as? UITableViewCellLoadableProtocol {
            loadableCell.loadData(dataItem, tableview: tableView)
        }
        
        self.delegate?.pinDelegate(dataItem)
        
        return tableCell!
        
    }
    
    @objc public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let sectionData = data[section]
        
        guard let rId = sectionData.headerReuseId else {
            return nil
        }
        
        let header = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: rId)
        
        if let loadableHeader = header as? UITableViewHeaderLoadableProtocol {
            loadableHeader.loadData(sectionData, tableview: tableView)
        }
        
        return header
        
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let sectionData = data[indexPath.section]
        let dataItem = sectionData.data[indexPath.row]
        return dataItem.canEdit()
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let sectionData = data[indexPath.section]
        let dataItem = sectionData.data[indexPath.row]
        return dataItem.actions()
    }
    
    
    
    @objc public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.data[indexPath.section].data[indexPath.row]
        self.delegate?.didSelect(data)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionData = data[section]
        return sectionData.height ?? 0
    }
    
    @objc public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let data = self.data[indexPath.section].data[indexPath.row]
        
        return data.height()
    }
}
