//
//  ConfigureTranningExersViewController.swift
//  MSA
//
//  Created by Pavlo Kharambura on 8/16/18.
//  Copyright © 2018 Pavlo Kharambura. All rights reserved.
//

import UIKit

class ConfigureTranningExersViewController: UIViewController {
    
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var numbersViewHeight: NSLayoutConstraint!
    @IBOutlet weak var weightOne: NumberButtonView!
    @IBOutlet weak var weightTwo: NumberButtonView!
    @IBOutlet weak var weightThree: NumberButtonView!
    @IBOutlet weak var weightFour: NumberButtonView!
    @IBOutlet weak var weightFive: NumberButtonView!
    @IBOutlet weak var weightSix: NumberButtonView!
    @IBOutlet weak var weightSeven: NumberButtonView!
    @IBOutlet weak var weightEight: NumberButtonView!
    @IBOutlet weak var weightNine: NumberButtonView!
    @IBOutlet weak var weightZero: NumberButtonView!
    @IBOutlet weak var weightDelete: NumberButtonView!
    
    @IBOutlet weak var countsLabel: UILabel!
    @IBOutlet weak var heightOne: NumberButtonView!
    @IBOutlet weak var heightTwo: NumberButtonView!
    @IBOutlet weak var heightThree: NumberButtonView!
    @IBOutlet weak var heightFour: NumberButtonView!
    @IBOutlet weak var heightFive: NumberButtonView!
    @IBOutlet weak var heightSix: NumberButtonView!
    @IBOutlet weak var heightSeven: NumberButtonView!
    @IBOutlet weak var heightEight: NumberButtonView!
    @IBOutlet weak var heightNine: NumberButtonView!
    @IBOutlet weak var heightZero: NumberButtonView!
    @IBOutlet weak var heightDelete: NumberButtonView!
    @IBOutlet weak var timeView: TimeView!
    
    @IBOutlet weak var timePicker: UIPickerView!
    @IBOutlet weak var timePickerBottom: NSLayoutConstraint!
    @IBOutlet weak var timePickerTop: NSLayoutConstraint!
    
    var workTime: (Int, Int) = (0, 0)
    var restTime: (Int, Int) = (0, 0)
    var weight: Int = 0
    var counts: Int = 0
    var workActive: Bool = true
    var buttonsW: [NumberButtonView] = []
    var buttonsH: [NumberButtonView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
    }

    private func configureUI() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        let button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "back_"), for: .normal)
        button.setTitle(" Отмена", for: .normal)
        let font = UIFont(name: "Rubik-Regular", size: 17)
        button.titleLabel?.font = font
        button.setTitleColor(.black, for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(back), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        self.navigationItem.title = "Настройки"
        let attrs = [NSAttributedStringKey.foregroundColor: UIColor.black,
            NSAttributedStringKey.font: UIFont(name: "Rubik-Medium", size: 17)!]
        self.navigationController?.navigationBar.titleTextAttributes = attrs
        self.numbersViewHeight.constant = self.view.frame.size.width*308.0/375
        configureWeightButtons()
        configureCountsButtons()
        configurePicker()
        
        timeView.restButton.addTarget(self, action: #selector(showPicker), for: .touchUpInside)
        timeView.workButton.addTarget(self, action: #selector(showPicker), for: .touchUpInside)
        timeView.restButton.addTarget(self, action: #selector(tapRest), for: .touchUpInside)
        timeView.workButton.addTarget(self, action: #selector(tapWork), for: .touchUpInside)
    }
    
    private func configurePicker() {
        timePicker.delegate = self
        timePicker.dataSource = self
        self.timePickerBottom.constant -= timePicker.frame.size.height
        self.timePickerTop.constant += timePicker.frame.size.height
    }
    
    private func reloadPicker() {
        if workActive {
            timePicker.selectRow(workTime.0, inComponent: 0, animated: true)
            timePicker.selectRow(workTime.1, inComponent: 1, animated: true)
        } else {
            timePicker.selectRow(restTime.0, inComponent: 0, animated: true)
            timePicker.selectRow(restTime.1, inComponent: 1, animated: true)
        }
    }
    
    private func configureWeightButtons() {
        weightLabel.text = "\(weight)"
        buttonsW = [weightZero,weightOne,weightTwo,weightThree,weightFour,weightFive,weightSix,weightSeven,weightEight,weightNine]
        for (index,button) in buttonsW.enumerated() {
            button.numberButton.tag = index
            button.numberButton.setTitle("\(index)", for: .normal)
            button.numberButton.addTarget(self, action: #selector(addWeight(sender:)), for: .touchUpInside)
        }
        weightDelete.numberButton.setImage(#imageLiteral(resourceName: "delete"), for: .normal)
        weightDelete.numberButton.addTarget(self, action: #selector(deleteWeight), for: .touchUpInside)
    }
    
    private func configureCountsButtons() {
        countsLabel.text = "\(counts)"
        buttonsH = [heightZero,heightOne,heightTwo,heightThree,heightFour,heightFive,heightSix,heightSeven,heightEight,heightNine]
        for (index,button) in buttonsH.enumerated() {
            button.numberButton.tag = index + 10
            button.numberButton.setTitle("\(index)", for: .normal)
            button.numberButton.addTarget(self, action: #selector(addCounts(sender:)), for: .touchUpInside)
        }
        heightDelete.numberButton.setImage(#imageLiteral(resourceName: "delete"), for: .normal)
        heightDelete.numberButton.addTarget(self, action: #selector(deleteCounts), for: .touchUpInside)
    }

    @objc
    func back() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc
    private func addWeight(sender: UIButton) {
        if !checklengh(text: weightLabel.text!) {
            return
        }
        if weightLabel.text == "0" {
            weightLabel.text = ""
        }
        weightLabel.text = (weightLabel.text ?? "") + "\(sender.tag)"
    }
    
    @objc
    private func addCounts(sender: UIButton) {
        if !checklengh(text: countsLabel.text!) {
            return
        }
        if countsLabel.text == "0" {
            countsLabel.text = ""
        }
        countsLabel.text = (countsLabel.text ?? "") + "\(sender.tag-10)"
    }
    
    @objc
    private func deleteCounts() {
        if let c = countsLabel.text?.count, c != 1 {
            countsLabel.text?.removeLast()
        } else {
            countsLabel.text = "0"
        }
    }
    @objc
    private func deleteWeight() {
        if let c = weightLabel.text?.count, c != 1 {
            weightLabel.text?.removeLast()
        } else {
            weightLabel.text = "0"
        }
    }
    @objc
    private func hidePicker() {
        if self.timePickerBottom.constant == 0 {
            UIView.animate(withDuration: 1) {
                self.timePickerBottom.constant -= self.view.frame.size.height*113/667
                self.timePickerTop.constant += self.view.frame.size.height*113/667
            }
        }
    }

    private func checklengh(text: String) -> Bool {
        if text.count < 3 {
            return true
        } else {
            return false
        }
    }
    
    @objc
    private func showPicker() {
        if self.timePickerBottom.constant != 0 {
            UIView.animate(withDuration: 1) {
                self.timePickerBottom.constant += self.view.frame.size.height*113/667
                self.timePickerTop.constant -= self.view.frame.size.height*113/667
            }
        }
    }
    
    @objc
    private func tapWork() {
        workActive = true
        reloadPicker()
    }
    
    @objc
    private func tapRest() {
        workActive = false
        reloadPicker()
    }
}

extension ConfigureTranningExersViewController: UIPickerViewDelegate, UIPickerViewDataSource {
   
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return 61
        case 1:
            return 60
        default:
            return 60
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return "\(row) min"
        case 1:
            return "\(row) sec"
        default:
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            if !workActive {
                if row < 10 {
                    timeView.restMinutes.text = "0\(row)"
                } else {
                    timeView.restMinutes.text = "\(row)"
                }
                restTime.0 = row
            } else {
                if row < 10 {
                    timeView.workMinutes.text = "0\(row)"
                } else {
                    timeView.workMinutes.text = "\(row)"
                }
                workTime.0 = row
            }
        default:
            if !workActive {
                if row < 10 {
                    timeView.restSeconds.text = "0\(row)"
                } else {
                    timeView.restSeconds.text = "\(row)"
                }
                restTime.1 = row
            } else {
                if row < 10 {
                    timeView.workSeconds.text = "0\(row)"
                } else {
                    timeView.workSeconds.text = "\(row)"
                }
                workTime.1 = row
            }
        }
    }
    
}