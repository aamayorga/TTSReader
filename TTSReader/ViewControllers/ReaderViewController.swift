//
//  ReaderViewController.swift
//  TTSReader
//
//  Created by Ansuke on 5/21/18.
//  Copyright © 2018 AM. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ReaderViewController: UIViewController, Storyboarded {
    
    weak var coordinator: MainCoordinator?
    var article: Article!
    var previousSelectedRange: NSRange?
    
    let speechSynthesizer = AVSpeechSynthesizer()
    let articleTimeToRead = NSDateComponents()
    
    fileprivate let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    deinit {
        activatePlaybackCommands(false)
    }
    
    @IBOutlet weak var scrollableTextView: UITextView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var timeScrubber: UISlider!
    
    @IBAction func skipBackwards(_ sender: UIButton) {
        previousTrack()
    }
    
    @IBAction func playPause(_ sender: UIButton) {
        resumeReading()
    }
    
    @IBAction func skipForward(_ sender: UIButton) {
        nextTrack()
    }
    
    func activatePlaybackCommands(_ enable: Bool) {
        if enable {
            remoteCommandCenter.playCommand.addTarget(self, action: #selector(ReaderViewController.resumeReading))
            remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(ReaderViewController.resumeReading))
            remoteCommandCenter.stopCommand.addTarget(self, action: #selector(ReaderViewController.stopCom))
            remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(ReaderViewController.resumeReading))
            remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(nextTrack))
            remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(previousTrack))
        } else {
            remoteCommandCenter.playCommand.removeTarget(self, action: #selector(ReaderViewController.resumeReading))
            remoteCommandCenter.pauseCommand.removeTarget(self, action: #selector(ReaderViewController.resumeReading))
            remoteCommandCenter.stopCommand.removeTarget(self, action: #selector(ReaderViewController.stopCom))
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(self, action: #selector(ReaderViewController.resumeReading))
            remoteCommandCenter.nextTrackCommand.removeTarget(self, action: #selector(nextTrack))
            remoteCommandCenter.previousTrackCommand.removeTarget(self, action: #selector(previousTrack))
        }
        
        remoteCommandCenter.playCommand.isEnabled = enable
        remoteCommandCenter.pauseCommand.isEnabled = enable
        remoteCommandCenter.stopCommand.isEnabled = enable
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = enable
        remoteCommandCenter.nextTrackCommand.isEnabled = enable
        remoteCommandCenter.previousTrackCommand.isEnabled = enable
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speechSynthesizer.delegate = self
        
        scrollableTextView.text = coordinator?.parseArticle(article.content!)
        
        totalTimeLabel.text = String(format: "%02i:%02i:%02i", articleTimeToRead.hour, articleTimeToRead.minute, articleTimeToRead.second)
    }
    
    @objc func resumeReading() {
        let articleText = scrollableTextView.text
        let nextSpeechUtterance = AVSpeechUtterance(string: articleText!)
        nextSpeechUtterance.rate = 0.6
        
        if speechSynthesizer.isPaused {
            speechSynthesizer.continueSpeaking()
        } else if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking(at: AVSpeechBoundary.immediate)
        } else {
            speechSynthesizer.speak(nextSpeechUtterance)
        }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback, with: [])
        } catch {
            print("Error with Audio playback")
        }
    }
    
    @objc func nextTrack() {
        print("Next Track")
        
        let articleText = scrollableTextView.text
        
        let nextSpeechUtterance = AVSpeechUtterance(string: articleText!)
        
        if speechSynthesizer.isPaused {
            speechSynthesizer.continueSpeaking()
        } else if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking(at: AVSpeechBoundary.immediate)
        } else {
            speechSynthesizer.speak(nextSpeechUtterance)
        }
    }
    
    @objc func previousTrack() {
        print("Previous Track")
    }
    
    @objc func stopCom() {
        print("Stop command")
    }
    
    fileprivate func highlightCurrentlyReadWord(_ characterRange: NSRange) {
        let rangeInTotalText = NSMakeRange(characterRange.location, characterRange.length)
        
        let currentAttributes = scrollableTextView.attributedText.attributes(at: rangeInTotalText.location, effectiveRange: nil)
        
        let attributedString = NSMutableAttributedString(string: scrollableTextView.attributedText.attributedSubstring(from: rangeInTotalText).string)
        attributedString.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.lightGray, range: NSMakeRange(0, attributedString.length))
        attributedString.addAttributes(currentAttributes, range: NSMakeRange(0, attributedString.length))
        
        scrollableTextView.scrollRangeToVisible(rangeInTotalText)
        
        scrollableTextView.textStorage.beginEditing()
        
        scrollableTextView.textStorage.replaceCharacters(in: rangeInTotalText, with: attributedString)
        
        if let previousRange = previousSelectedRange {
            let previousAttributedText = NSMutableAttributedString(string: scrollableTextView.attributedText.attributedSubstring(from: previousRange).string)
            previousAttributedText.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.clear, range: NSMakeRange(0, previousAttributedText.length))
            previousAttributedText.addAttributes(currentAttributes, range: NSMakeRange(0, previousAttributedText.length))
            
            scrollableTextView.textStorage.replaceCharacters(in: previousRange, with: previousAttributedText)
        }
        
        scrollableTextView.textStorage.endEditing()
        
        previousSelectedRange = rangeInTotalText
    }
    
    func unselectLastWord() {
        if let selectedRange = previousSelectedRange {
            // Get the attributes of the last selected attributed word.
            let currentAttributes = scrollableTextView.attributedText.attributes(at: selectedRange.location, effectiveRange: nil)
            
            // Keep the font attribute.
            let fontAttribute = currentAttributes[NSAttributedStringKey.font]
            
            // Create a new mutable attributed string using the last selected word.
            let attributedWord = NSMutableAttributedString(string: scrollableTextView.attributedText.attributedSubstring(from: selectedRange).string)
            
            // Set the previous font attribute, and make the foreground color black.
            attributedWord.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.clear, range: NSMakeRange(0, attributedWord.length))
            attributedWord.addAttribute(NSAttributedStringKey.font, value: fontAttribute!, range: NSMakeRange(0, attributedWord.length))
            
            // Update the text storage property and replace the last selected word with the new attributed string.
            scrollableTextView.textStorage.beginEditing()
            scrollableTextView.textStorage.replaceCharacters(in: selectedRange, with: attributedWord)
            scrollableTextView.textStorage.endEditing()
        }
    }
}

extension ReaderViewController: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Start")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Finish")
        unselectLastWord()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        print("Continue")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("Pause")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("Cancel")
    }
    
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        
        highlightCurrentlyReadWord(characterRange)
        
        timeScrubber.setValue(Float(Double(characterRange.location)/Double(utterance.speechString.count)), animated: true)
    }
}
