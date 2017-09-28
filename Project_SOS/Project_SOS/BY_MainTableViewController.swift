//
//  BY_MainTableViewController.swift
//  Project_SOS
//
//  Created by Bo-Young PARK on 20/9/2017.
//  Copyright © 2017 joe. All rights reserved.
//

import UIKit
import Firebase

class BY_MainTableViewController: UITableViewController {
    /*******************************************/
    //MARK:-        Properties                 //
    /*******************************************/
    
    var questionTitleData:[String] = []
    var questionTagData:[String] = []
    var questionFavoriteCount:Int = 0
    var questionIDData:[Int] = []
    
    var questionDataForMainVC:[String:Any] = [:]
    
    //선택한 캐릭터가 있는지 확인
    var selectedCharater:String?
    
    //좋아요한 목록 표시 관련
    var isfavoriteTableView:Bool = false
    var favoriteList:[Int] = []
    
    //검색 관련
    var isSearchBarClicked:Bool = false
    
    lazy var visibleResults:[String] = self.questionTitleData
    
    var filterString:String? = nil {
        didSet {
            if filterString == nil || filterString!.isEmpty {
                visibleResults = questionTitleData
            }
            else {
                // Filter the results using a predicate based on the filter string.
                let filterPredicate = NSPredicate(format: "self contains[c] %@", argumentArray: [filterString!])
                
                visibleResults = questionTitleData.filter { filterPredicate.evaluate(with: $0) }
            }
            
            self.isSearchBarClicked = true
            self.tableView.reloadData()
            
        }
    }

    
    
    //네비게이션 바
    @IBOutlet weak var navigationBarLogoButtonOutlet: UIButton!
    
    
    /*******************************************/
    //MARK:-        LifeCycle                  //
    /*******************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Database.database().reference().child(Constants.question).observe(.value, with: { (snapshot) in
            guard let data = snapshot.value as? [[String:Any]] else { return }
            let tempArray = data.map({ (dic) -> String in
                return dic[Constants.question_QuestionTitle] as! String
            })
            let tempTagArray = data.map({ (dic) -> String in
                return dic[Constants.question_Tag] as! String
            }) 
            let tempIDArray = data.map({ (dic) -> Int in
                return dic[Constants.question_QuestionId] as! Int
            })
            
            let tempQuestionData = Dictionary.init(keys:tempArray ,values:tempIDArray)
            
            print("이거시되는거시요잉 \(tempQuestionData)")
            
            self.questionTagData = tempTagArray
            self.questionTitleData = tempArray
            self.questionDataForMainVC = tempQuestionData

            self.tableView.reloadData()
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        guard let realNavigationBarLogoButtonOutlet = self.navigationBarLogoButtonOutlet else {return}
        realNavigationBarLogoButtonOutlet.isUserInteractionEnabled = false
        
        //테이블뷰 백그라운드 이미지
        let tableViewBackgroundImage:UIImage = #imageLiteral(resourceName: "background")
        let imageView:UIImageView = UIImageView(image: tableViewBackgroundImage)
        self.tableView.backgroundView = imageView
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        //셀라인 삭제
        self.tableView.separatorStyle = .none
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.tableView.reloadData()
        
        tableView.register(UINib.init(nibName: "BY_MainTableViewCell", bundle: nil), forCellReuseIdentifier: "MainTableViewCell")
        awakeFromNib()
        
        if UserDefaults.standard.object(forKey: "SelectedCharacter") != nil {
            self.selectedCharater = UserDefaults.standard.object(forKey: "SelectedCharacter") as! String
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /*******************************************/
    //MARK:-         Functions                 //
    /*******************************************/
    
    //테이블뷰 설정 부분
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.isSearchBarClicked == false {
            if self.isfavoriteTableView {
                print("좋아요 개수 \(DataCenter.standard.favoriteQuestions.count)")
                return DataCenter.standard.favoriteQuestions.count
            }else{
                print("전체 개수 \(self.questionTitleData.count)")
                return self.questionTitleData.count
            }
        }else if self.isSearchBarClicked == true {
            print("검색 개수 \(self.visibleResults.count)")
            return self.visibleResults.count
        }else{
            print("셀개수에러")
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:BY_MainTableViewCell = tableView.dequeueReusableCell(withIdentifier: "MainTableViewCell", for: indexPath) as! BY_MainTableViewCell

        cell.selectionStyle = .none

        cell.titleQuestionLabel.text = self.questionTitleData[indexPath.row]
        cell.tagLabel?.text = self.questionTagData[indexPath.row]
        cell.getLikeCount(question: indexPath.row)
        
        if self.isSearchBarClicked == false {
            if self.isfavoriteTableView {
                cell.titleQuestionLabel.text = ""
                cell.getLikeCount(question: indexPath.row)
            }else{
                cell.titleQuestionLabel.text = self.questionTitleData[indexPath.row]
                cell.tagLabel?.text = self.questionTagData[indexPath.row]
                cell.getLikeCount(question: indexPath.row)
            }
        }else if self.isSearchBarClicked == true {
            cell.titleQuestionLabel.text = self.visibleResults[indexPath.row]
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 97
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextViewController:BY_DetailViewController = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! BY_DetailViewController
        
        if self.isfavoriteTableView != true {
            nextViewController.questionID = indexPath.row
        }else{
            print("이게모양?\(self.questionTitleData[indexPath.row])")
            nextViewController.questionID = self.questionDataForMainVC[self.questionTitleData[indexPath.row]] as! Int
        }
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }

}

//가져온 QuestionTitle 어레이와 QuetionID 어레이를 [QuetionTitle:QuestionID] 딕셔너리로 만들도록 해주는 Extension
extension Dictionary {
    public init(keys:[Key], values:[Value]) {
        precondition(keys.count == values.count)
        
        self.init()
        for (index, key) in keys.enumerated() {
            self[key] = values[index]
        }
    }
}
