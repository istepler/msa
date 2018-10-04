//
//  TrainingManager.swift
//  MSA
//
//  Created by Pavlo Kharambura on 8/30/18.
//  Copyright © 2018 Pavlo Kharambura. All rights reserved.
//

import Foundation
import RealmSwift
import Firebase


@objc protocol TrainingsViewDelegate {
    func startLoading()
    func finishLoading()
    func trainingsLoaded()
    func templateCreated()
    func templatesLoaded()
    func trainingEdited()
    @objc optional func trainingDeleted()
    func errorOccurred(err: String)
    func synced()
}

protocol TrainingFlowDelegate {
    func changeTime(time: String, iterationState: IterationState)
    func higlightIteration(on: Int)
    func rewriteIterations()
}

enum TrainingState {
    case normal
    case round
}
enum IterationState {
    case work
    case rest
}

class TrainingManager {
    
    let realm = RealmManager.shared
    var dataSource: TrainingsDataSource?
    var dataSourceCopy = TrainingsDataSource()
    private var view: TrainingsViewDelegate?
    private var flowView: TrainingFlowDelegate?
    
    func initDataSource(dataSource: TrainingsDataSource) {
        self.dataSource = dataSource
    }
    
    func initView(view: TrainingsViewDelegate) {
        self.view = view
    }
    func initFlowView(view: TrainingFlowDelegate) {
        self.flowView = view
    }
    
    func getTrainings() -> [Training]? {
        return dataSource?.trainings
    }
    
    func setCurrent(day: TrainingDay?) {
        dataSource?.currentDay = day
    }
    func getCurrentday() -> TrainingDay? {
        return dataSource?.currentDay
    }
    
    func setCurrent(training: Training?) {
        dataSource?.currentTraining = training
    }
    func getCurrentTraining() -> Training? {
        return realm.getElement(ofType: Training.self, filterWith: NSPredicate(format: "id = %d", dataSource?.currentTraining?.id ?? -1))
    }
    func setCurrent(exercise: ExerciseInTraining) {
        dataSource?.currentExerciseInDay = exercise
    }
    func getCurrentExercise() -> ExerciseInTraining? {
        return realm.getElement(ofType: ExerciseInTraining.self, filterWith: NSPredicate(format: "id = %d", dataSource?.currentExerciseInDay?.id ?? -1))
    }
    func setCurrent(iteration: Iteration) {
        dataSource?.currentIteration = iteration
    }
    func getCurrentIteration() -> Iteration? {
        return dataSource?.currentIteration
    }
    func getTrainingsFromRealm() -> [Training]? {
        return realm.getArray(ofType: Training.self)
    }
    func getTemplatesFromRealm() -> [TrainingTemplate]? {
        return realm.getArray(ofType: TrainingTemplate.self)
    }
    func getDay(by id: Int) -> TrainingDay? {
        return realm.getElement(ofType: TrainingDay.self, filterWith: NSPredicate(format: "id = %d", id))
    }
    func getWeek(by id: Int) -> TrainingWeek? {
        return realm.getElement(ofType: TrainingWeek.self, filterWith: NSPredicate(format: "id = %d", id))
    }
    func getExercise(by id: Int) -> ExerciseInTraining? {
        return realm.getElement(ofType: ExerciseInTraining.self, filterWith: NSPredicate(format: "id = %d", id))
    }
    func getIteration(by id: Int) -> Iteration? {
        return realm.getElement(ofType: Iteration.self, filterWith: NSPredicate(format: "id = %d", id))
    }
    func getTemplatesby(trainer id: Int) -> [TrainingTemplate]? {
        return realm.getArray(ofType: TrainingTemplate.self, filterWith: NSPredicate(format: "trianerId = %d", id))
    }
    func saveTemplateToRealm(templates: [TrainingTemplate]) {
        realm.saveObjectsArray(templates)
    }
    func saveTrainingsToRealm(trainings: [Training]) {
        realm.saveObjectsArray(trainings)
    }
    func saveDaysToRealm(days: [TrainingDay]) {
        realm.saveObjectsArray(days)
    }
    func saveWeeksToRealm(weeks: [TrainingWeek]) {
        realm.saveObjectsArray(weeks)
    }
    func saveExersInTrainingToRealm(ex: [ExerciseInTraining]) {
        realm.saveObjectsArray(ex)
    }
    func saveIterationsToRealm(iterations: [Iteration]) {
        realm.saveObjectsArray(iterations)
    }
    
    func saveTemplate() {
        if let id = AuthModule.currUser.id {
            self.view?.startLoading()
            let index = dataSource?.newTemplate?.incrementID() ?? 0
            let newInfo = makeTemplateForFirebase(trainerId: id, edit: false)
            Database.database().reference().child("Templates").child(id).child("\(index)").setValue(newInfo) { (error, databaseFer) in
                self.view?.finishLoading()
                if error == nil {
                    guard let newTemplate = self.dataSource?.newTemplate else {return}
            
                    self.realm.saveObject(newTemplate, update: false)
                    self.view?.templateCreated()
                } else {
                    self.view?.errorOccurred(err: error?.localizedDescription ?? "Unknown error")
                }
            }
        }
    }
    
    func makeTemplateForFirebase(trainerId: String, edit: Bool) -> [String:Any] {
        var index = Int()
        if edit {
            index = dataSource?.newTemplate?.id ?? 0
        } else {
            index = dataSource?.newTemplate?.incrementID() ?? 0
        }
        dataSource?.newTemplate?.id = index
        return [
        "id": dataSource?.newTemplate?.id ?? 0,
        "name": dataSource?.newTemplate?.name ?? "",
        "trainerId": trainerId,
        "typeId": dataSource?.newTemplate?.typeId ?? -1,
        "days": dataSource?.newTemplate?.days ?? 0,
        "trainingId": dataSource?.newTemplate?.trainingId ?? -1
        ]
    }
    
    func editTraining(wiht id: Int, success: @escaping()->()) {
        if let userId = AuthModule.currUser.id {
//            self.view?.startLoading()
            let newInfo = makeTrainingForFirebase(id: id, or: true)
            Database.database().reference().child("Trainings").child(userId).child("\(id)").updateChildValues(newInfo) { (error, ref) in
                self.view?.finishLoading()
                self.view?.trainingEdited()
                if error == nil {
                    self.setSynced()
                    if let object = self.dataSource?.currentTraining {
                        self.realm.saveObject(object)
                    }
                    success()
                } else {
                    self.view?.errorOccurred(err: error?.localizedDescription ?? "")
                }
            }
        }
    }
    func addDay(week: TrainingWeek) {
        try! realm.performWrite {
            let newDay = TrainingDay()
            newDay.id = newDay.incrementID()
            week.days.append(newDay)
            self.editTraining(wiht: self.dataSource?.currentTraining?.id ?? -1, success: {})
        }
    }
    
    func createWeak(in training: Training) {
        try! realm.performWrite {
            let newWeek = TrainingWeek()
            newWeek.id = newWeek.incrementID()
            let newDay = TrainingDay()
            newDay.id = newDay.incrementID()
            newWeek.days.append(newDay)
            training.weeks.append(newWeek)
            dataSource?.currentTraining = training
            dataSource?.currentWeek = newWeek
            self.editTraining(wiht: training.id, success: {})
        }
    }
    
    func loadTrainings() {
        if let id = AuthModule.currUser.id {
//            self.view?.startLoading()
            Database.database().reference().child("Trainings").child(id).observeSingleEvent(of: .value) { (snapchot) in
                self.observeTrainings(snapchot: snapchot)
            }
        }
    }
    
    func loadTrainingsFromRealm() {
        let trainings = Array(realm.getArray(ofType: Training.self))
        dataSource?.set(trainings: trainings)
        dataSource?.currentTraining = trainings.first
        self.view?.trainingsLoaded()
    }
    
    func loadTemplates() {
        if let id = AuthModule.currUser.id {
//            self.view?.startLoading()
            Database.database().reference().child("Templates").child(id).observeSingleEvent(of: .value) { (snapchot) in
                self.observeTemplates(snapchot: snapchot)
            }
        }
    }
    
    func deleteTraining(with id: String) {
        if let userId = AuthModule.currUser.id {
            self.view?.startLoading()
            Database.database().reference().child("Trainings").child(userId).child(id).removeValue { (error, ref) in
                self.view?.finishLoading()
                if error == nil {
                    guard let object = RealmManager.shared.getElement(ofType: Training.self, filterWith: NSPredicate(format: "id = %d", Int(id) ?? -1)) else {return}
                    RealmManager.shared.deleteObject(object)
                    self.view?.trainingDeleted!()
                } else {
                    self.view?.errorOccurred(err: error?.localizedDescription ?? "")
                }
            }
        }
    }
    
    func deleteTemplate(with id: String) {
        if let userId = AuthModule.currUser.id {
            self.view?.startLoading()
            Database.database().reference().child("Templates").child(userId).child(id).removeValue { (error, ref) in
                self.view?.finishLoading()
                if error == nil {
                    // DELETED
                } else {
                    self.view?.errorOccurred(err: error?.localizedDescription ?? "")
                }
            }
        }
    }
    
    func makeTrainingForFirebase(id: Int, or edit: Bool) -> [String:Any] {
        var newiterations = [[String:Any]]()
        var newexercises = [[String:Any]]()
        var newdays = [[String:Any]]()
        var newWeeks = [[String:Any]]()

        let training = dataSource?.currentTraining
        if let weeks = training?.weeks {
            newWeeks.removeAll()
            for week in weeks {
                newdays.removeAll()
                for day in week.days {
                    newexercises.removeAll()
                    for e in day.exercises {
                        newiterations.removeAll()
                        for i in e.iterations {
                            newiterations.append([
                                    "id": i.id,
                                    "exerciseInTrainingId": i.exerciseInTrainingId,
                                    "weight": i.weight,
                                    "counts": i.counts,
                                    "workTime": i.workTime,
                                    "restTime": i.restTime,
                                    "startTimerOnZero": i.startTimerOnZero ? 1 : 0
                                ])
                        }
                        newexercises.append([
                               "id": e.id,
                               "name": e.name.capitalizingFirstLetter(),
                               "exerciseId": e.exerciseId,
                               "iterations": newiterations
                            ])
                    }
                    newdays.append([
                           "id": day.id,
                           "name": day.name.capitalizingFirstLetter(),
                           "date": day.date,
                           "exercises": newexercises
                        ])
                }
                newWeeks.append([
                    "id": week.id,
                    "name": week.name,
                    "days": newdays
                    ])
            }
        }
        return [
            "id": dataSource?.currentTraining?.id ?? "",
            "name": (dataSource?.currentTraining?.name ?? "").capitalizingFirstLetter(),
            "trainerId": dataSource?.currentTraining?.trianerId ?? "",
            "userId": dataSource?.currentTraining?.userId ?? "",
            "weeks": newWeeks
        ]
    }
    
    func observeTemplates(snapchot: DataSnapshot) {
        self.view?.finishLoading()
        var items = [TrainingTemplate]()
        for snap in snapchot.children {
            let s = snap as! DataSnapshot
            if let _ = s.childSnapshot(forPath: "id").value as? NSNull {return}
            let template = TrainingTemplate()
            template.id = s.childSnapshot(forPath: "id").value as! Int
            template.name = s.childSnapshot(forPath: "name").value as! String
            template.trianerId = s.childSnapshot(forPath: "trainerId").value as! String
            template.trainingId = s.childSnapshot(forPath: "trainingId").value as! Int
            template.days = s.childSnapshot(forPath: "days").value as! Int
            template.typeId = s.childSnapshot(forPath: "typeId").value as! Int
            items.append(template)
        }
        self.dataSource?.templates = items
        self.saveTemplateToRealm(templates: items)
        self.view?.templatesLoaded()
    }
    
    func observeTrainings(snapchot: DataSnapshot) {
        self.view?.finishLoading()
        var items = [Training]()
        for snap in snapchot.children {
            let s = snap as! DataSnapshot
            if let _ = s.childSnapshot(forPath: "id").value as? NSNull {
                return
            }
            let training = Training()
            training.id = s.childSnapshot(forPath: "id").value as! Int
            training.name = s.childSnapshot(forPath: "name").value as! String
            training.trianerId = s.childSnapshot(forPath: "trainerId").value as! String
            training.userId = s.childSnapshot(forPath: "userId").value as! Int

            if let weeks = s.childSnapshot(forPath: "weeks").value as? NSArray {
                for w in (weeks as! [[String:Any]]) {
                    let week = TrainingWeek()
                    week.id = w["id"] as! Int
                    week.name = w["name"] as? String ?? ""
                    let daysInWeek = List<TrainingDay>()
                    if let days = w["days"] as? [[String:Any]] {
                        for d in days {
                            let day = TrainingDay()
                            day.id = d["id"] as! Int
                            day.name = d["name"] as! String
                            day.date = d["date"] as! String
                            let exercisesInDay = List<ExerciseInTraining>()
                            if let exercises = d["exercises"] as? [[String:Any]] {
                                for e in exercises {
                                    let exercise = ExerciseInTraining()
                                    exercise.id = e["id"] as! Int
                                    exercise.name = e["name"] as! String
                                    exercise.exerciseId = e["exerciseId"] as! Int
                                    let exerciseIterations = List<Iteration>()
                                    if let iterations = e["iterations"] as? [[String:Any]] {
                                        for i in iterations {
                                            let iteration = Iteration()
                                            iteration.id = i["id"] as! Int
                                            iteration.exerciseInTrainingId = i["exerciseInTrainingId"] as! Int
                                            iteration.counts = i["counts"] as! Int
                                            iteration.weight = i["weight"] as! Int
                                            iteration.restTime = i["restTime"] as! Int
                                            iteration.workTime = i["workTime"] as! Int
                                            iteration.startTimerOnZero = (i["startTimerOnZero"] as? Int ?? 0) == 1 ? true : false
                                            exerciseIterations.append(iteration)
                                        }
                                    }
                                    exercise.iterations = exerciseIterations
                                    exercisesInDay.append(exercise)
                                }
                            }
                            day.exercises = exercisesInDay
                            daysInWeek.append(day)
                        }
                    }
                    week.days = daysInWeek
                    training.weeks.append(week)
                }
            }
            items.append(training)
        }
        if items.isEmpty {
            let objects = realm.getArray(ofType: Training.self)
            realm.deleteObjectsArray(objects)
        }
        dataSource?.set(trainings: items)
        dataSource?.currentTraining = items.first
        setSynced()
        self.saveTrainingsToRealm(trainings: items)
        self.view?.trainingsLoaded()
    }
    
    func syncUnsyncedTrainings() {
        let trainings = realm.getArray(ofType: Training.self, filterWith: NSPredicate(format: "wasSync = %@", NSNumber(booleanLiteral: false)))
        let weeks = realm.getArray(ofType: TrainingWeek.self, filterWith: NSPredicate(format: "wasSync = %@", NSNumber(booleanLiteral: false)))
        let days = realm.getArray(ofType: TrainingDay.self, filterWith: NSPredicate(format: "wasSync = %@", NSNumber(booleanLiteral: false)))
        let ex = realm.getArray(ofType: ExerciseInTraining.self, filterWith: NSPredicate(format: "wasSync = %@", NSNumber(booleanLiteral: false)))
        let iterations = realm.getArray(ofType: Iteration.self, filterWith: NSPredicate(format: "wasSync = %@", NSNumber(booleanLiteral: false)))

        let dispatch = DispatchGroup()
        
        if trainings.contains(where: {$0.wasSync == false}) || weeks.contains(where: {$0.wasSync == false}) || days.contains(where: {$0.wasSync == false}) || ex.contains(where: {$0.wasSync == false}) || iterations.contains(where: {$0.wasSync == false}) {
            for training in trainings {
                dispatch.enter()
                dataSource?.currentTraining = training
                self.editTraining(wiht: training.id, success: {
                    dispatch.leave()
                })
            }
            dispatch.notify(queue: .main) {
               self.setSynced()
            }
        }
        self.view?.synced()
    }
    
    func setSynced() {
        try! self.realm.performWrite {
            let trainings = realm.getArray(ofType: Training.self, filterWith: NSPredicate(format: "wasSync = %@", NSNumber(booleanLiteral: false)))
            let weeks = realm.getArray(ofType: TrainingWeek.self, filterWith: NSPredicate(format: "wasSync = %@", NSNumber(booleanLiteral: false)))
            let days = realm.getArray(ofType: TrainingDay.self, filterWith: NSPredicate(format: "wasSync = %@", NSNumber(booleanLiteral: false)))
            let ex = realm.getArray(ofType: ExerciseInTraining.self, filterWith: NSPredicate(format: "wasSync = %@", NSNumber(booleanLiteral: false)))
            let iterations = realm.getArray(ofType: Iteration.self, filterWith: NSPredicate(format: "wasSync = %@", NSNumber(booleanLiteral: false)))
            for training in trainings {
                training.wasSync = true
            }
            for week in weeks {
                week.wasSync = true
            }
            for day in days {
                day.wasSync = true
            }
            for e in ex {
                e.wasSync = true
            }
            for i in iterations {
                i.wasSync = true
            }
        }
    }
    
    func setWeekFromDay(day: TrainingDay) {
        if let weeks = getCurrentTraining()?.weeks {
            for week in weeks {
                if week.days.contains(day) {
                    dataSource?.currentWeek = week
                    return
                }
            }
        }
    }
    
    func getWeekNumber() -> Int {
        var i = 0
        if let weeks = getCurrentTraining()?.weeks {
            for week_ in weeks {
                if dataSource?.currentWeek?.id == week_.id {
                    return i
                } else {
                    i += 1
                }
            }
        }
        return i
    }
    
    func renameWeek(name: String?) {
        try! realm.performWrite {
            self.dataSource?.currentWeek?.name = name ?? ""
            self.dataSource?.currentWeek?.wasSync = false
        }
        guard let id = dataSource?.currentTraining?.id else {return}
        editTraining(wiht: id, success: {})
    }
    
    func numberOfDay() -> Int {
        guard let day = dataSource?.currentDay else {return 1}
        return (dataSource?.currentWeek?.days.index(of: day) ?? 0) + 1
    }
    func exercisesCount() -> Int {
        return getCurrentday()?.exercises.count ?? 0
    }
    
    // TRAINING FLOW
    
    private var timer = Timer()
    private var secondomer = Timer()
    
    private var iterationState: IterationState = .work
    private var trainingState: TrainingState = .normal
    private var trainingStarted: Bool = false
    private var trainingInProgress: Bool = false
    private var secondomerStarted: Bool = false
    private var iterations: [Iteration]?
    private var currentIteration: Iteration?
    
    private var currentIterationNumber = 0
    private var currentRestTime = 0
    private var currentWorkTime = 0
    private var secondomerTime = 0

    
    private func createExerciseCopy(i: Int) {
        iterations = Array(dataSource?.currentExerciseInDay?.iterations ?? List<Iteration>())
        currentIteration = iterations?[i]
        currentWorkTime = currentIteration?.workTime ?? 0
        currentRestTime = currentIteration?.restTime ?? 0
    }
    
    private func startTimer() {
        trainingInProgress = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
            if self.iterationState == .work {
                if self.currentWorkTime != 0 {
                    self.currentWorkTime -= 1
                    self.eventWithTimer(time: self.currentWorkTime)
                } else {
                    if (self.currentIteration?.startTimerOnZero)! && self.currentIteration?.workTime == 0 {
                        self.stopIteration()
                        self.startSecondomer()
                    } else if !(self.currentIteration?.startTimerOnZero)! && self.currentIteration?.workTime == 0 {
                        self.stopIteration()
                        self.eventWithTimer(time: self.currentWorkTime)
                    } else {
                        self.nextIterationState()
                    }
                }
            } else {
                if self.currentRestTime != 0 {
                    self.currentRestTime -= 1
                    self.eventWithTimer(time: self.currentRestTime)
                } else {
                    self.nextIterationState()
                    self.iterationsSwitcher()
                }
            }
        }
    }
    
    private func startSecondomer() {
        secondomerStarted = true
        secondomer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
            self.secondomerTime += 1
            self.eventWithTimer(time: self.secondomerTime)
        }
    }
    private func pauseSecondomer() {
        secondomer.invalidate()
    }
    private func stopSecondomer() {
        pauseSecondomer()
        secondomerStarted = false
        secondomerTime = 0
    }
    
    func startExercise() {
        createExerciseCopy(i: currentIterationNumber)
        trainingStarted = true
        trainingInProgress = true
        startTimer()
        self.flowView?.higlightIteration(on: currentIterationNumber)
    }
    
    func finish() {
        trainingStarted = false
        trainingInProgress = false
        secondomerStarted = false
        currentIterationNumber = 0
        currentRestTime = 0
        currentWorkTime = 0
        secondomerTime = 0
    }
    
    func iterationsSwitcher() {
        if currentIterationNumber == (iterations?.count ?? 0) - 1 {
            stopIteration()
            currentIterationNumber = 0
            trainingStarted = false
            trainingInProgress = false
        } else {
            currentIterationNumber += 1
            currentIteration = iterations?[currentIterationNumber]
            currentWorkTime = currentIteration?.workTime ?? 0
            currentRestTime = currentIteration?.restTime ?? 0
        }
    }
    
    func eventWithTimer(time: Int) {
        var min = 0
        var sec = 0
        var minStr = ""
        var secStr = ""
        min = Int(time/60)
        sec = time - min*60
        minStr = min<10 ? "0\(min)" : "\(min)"
        secStr = sec<10 ? "0\(sec)" : "\(sec)"
        var timeString = "-"+minStr+":"+secStr
        if iterationState == .rest || secondomerStarted {
            timeString.removeFirst()
        }
        self.flowView?.changeTime(time: timeString, iterationState: iterationState)
    }
    
    func startExercise(from i: Int) {
        if trainingInProgress && trainingStarted {
            self.stopIteration()
            currentIterationNumber = 0
            trainingStarted = false
            trainingInProgress = false
        }
        currentIterationNumber = i
        startExercise()
    }
    
    func pauseIteration() {
        timer.invalidate()
        pauseSecondomer()
        trainingInProgress = false
        trainingStarted = true
    }
    
    func startOrContineIteration() {
        if !trainingInProgress {
            trainingInProgress = true
            if trainingStarted {
                if secondomerStarted {
                    startSecondomer()
                } else {
                    startTimer()
                }
            } else {
                startExercise()
            }
        }
    }
    
    private func nextIterationState() {
        switch iterationState {
            case .work: iterationState = .rest
            case .rest: iterationState = .work
        }
    }
    
    func nextStateOrIteration() {
        saveIterationsInfo()
        if trainingStarted {
            nextIterationState()
            var time = Int()
            if iterationState == .work {
                self.iterationsSwitcher()
                time = currentWorkTime
            } else {
                time = currentRestTime
            }
            if secondomerStarted {
                stopSecondomer()
                startTimer()
            }
            if trainingInProgress {
                eventWithTimer(time: time)
                if !timer.isValid {
                    startTimer()
                }
            } else {
                eventWithTimer(time: 0)
                startExercise()
            }
        }
    }
    
    func stopIteration() {
        timer.invalidate()
        stopSecondomer()
        iterationState = .work
    }
    
    func fullStop() {
        saveIterationsInfo()
        stopIteration()
        currentIterationNumber = 0
        trainingStarted = false
        trainingInProgress = false
        self.flowView?.changeTime(time: "--:--", iterationState: iterationState)
        editTraining(wiht: dataSource?.currentTraining?.id ?? 0, success: {})
    }
    
    func saveIterationsInfo() {
        try! realm.performWrite {
            switch iterationState {
            case .work:
                if secondomerStarted {
                    currentIteration?.workTime = secondomerTime
                } else {
                    currentIteration?.workTime = (currentIteration?.workTime ?? 0) - currentWorkTime
                }
            case .rest:
                currentIteration?.restTime = (currentIteration?.restTime ?? 0) - currentRestTime
            }
            currentIteration?.wasSync = false
        }
        self.flowView?.rewriteIterations()
    }
    
}
