//
//  ViewController.swift
//  Pitch Recogniser
//
//  Created by Rui Luo on 2018/7/4.

import UIKit
import Beethoven
import Pitchy
import Hue
import Cartography
import AVFoundation

final class ViewController: UIViewController {
	var player: AVAudioPlayer?
	
	@IBOutlet weak var noteLabel: UILabel!
	@IBOutlet weak var frequencyLabel: UILabel!
	@IBOutlet weak var offsetLabel: UILabel!
	@IBOutlet weak var actionButton: UIButton!
	
	lazy var pitchEngine: PitchEngine = { [weak self] in
		let config = Config(estimationStrategy: .yin)
		let pitchEngine = PitchEngine(config: config, delegate: self)
		pitchEngine.levelThreshold = -30.0
		return pitchEngine
		}()
	
	// MARK: - View Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = "Tuner".uppercased()
		view.backgroundColor = UIColor(hex: "111011")
		
		[noteLabel, actionButton, offsetLabel].forEach {
			view.addSubview($0)
		}
		
		setupLayout()
	}
	
	// MARK: - Action methods
	
	@objc func actionButtonDidPress(_ button: UIButton) {
		let text = pitchEngine.active
			? NSLocalizedString("Start", comment: "").uppercased()
			: NSLocalizedString("Stop", comment: "").uppercased()
		
		button.setTitle(text, for: .normal)
		button.backgroundColor = pitchEngine.active
			? UIColor(hex: "3DAFAE")
			: UIColor(hex: "E13C6C")
		
		noteLabel.text = "--"
		frequencyLabel.text = "-- Hz"
		pitchEngine.active ? pitchEngine.stop() : pitchEngine.start()
		offsetLabel.isHidden = !pitchEngine.active
	}
	
	// MARK: - Play music
	func playSound(_ sourceName: String) {
		guard let url = Bundle.main.url(forResource: "/mp3/FlavorPaintingL", withExtension: "mp3") else { return }
		
		do {
			try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
			try AVAudioSession.sharedInstance().setActive(true)
			
			/* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
			player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
			
			/* iOS 10 and earlier require the following line:
			player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
			
			guard let player = player else { return }
			player.delegate = self
			
			player.play()
			
		} catch let error {
			print(error.localizedDescription)
		}
	}
	
	// MARK: - Layout
	
	func setupLayout() {
		
		noteLabel.text = "--"
		noteLabel.font = UIFont.boldSystemFont(ofSize: 65)
		noteLabel.textColor = UIColor(hex: "DCD9DB")
		noteLabel.textAlignment = .center
		noteLabel.numberOfLines = 0
		noteLabel.sizeToFit()
		
		frequencyLabel.text = "-- Hz"
		frequencyLabel.font = UIFont.boldSystemFont(ofSize: 45)
		frequencyLabel.textColor = UIColor(hex: "FF5733")
		frequencyLabel.textAlignment = .center
		frequencyLabel.numberOfLines = 0
		frequencyLabel.sizeToFit()
		
		offsetLabel.font = UIFont.systemFont(ofSize: 28)
		offsetLabel.textColor = UIColor.white
		offsetLabel.textAlignment = .center
		offsetLabel.numberOfLines = 0
		offsetLabel.sizeToFit()
		
		actionButton.layer.cornerRadius = 20
		actionButton.backgroundColor = UIColor(hex: "3DAFAE")
		actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
		actionButton.setTitleColor(UIColor.white, for: UIControlState())
		
		actionButton.addTarget(self, action: #selector(ViewController.actionButtonDidPress(_:)),
						 for: .touchUpInside)
		actionButton.setTitle("Start".uppercased(), for: UIControlState())
	}
	
	// MARK: - UI
	
	private func offsetColor(_ offsetPercentage: Double) -> UIColor {
		let color: UIColor
		
		switch abs(offsetPercentage) {
		case 0...5:
			color = UIColor(hex: "3DAFAE")
		case 6...25:
			color = UIColor(hex: "FDFFB1")
		default:
			color = UIColor(hex: "E13C6C")
		}
		
		return color
	}
}

// MARK: - PitchEngineDelegate

extension ViewController: PitchEngineDelegate {
	func pitchEngine(_ pitchEngine: PitchEngine, didReceivePitch pitch: Pitch) {
		noteLabel.text = pitch.note.string
		
		let offsetPercentage = pitch.closestOffset.percentage
		let absOffsetPercentage = abs(offsetPercentage)
		
		print("pitch : \(pitch.note.string) - percentage : \(offsetPercentage)")
		print("frequency: \(pitch.frequency)")
		
		frequencyLabel.text = "\(pitch.frequency.rounded()) Hz"
		
		guard absOffsetPercentage > 1.0 else {
			return
		}
		
		let prefix = offsetPercentage > 0 ? "+" : "-"
		let color = offsetColor(offsetPercentage)
		
		offsetLabel.text = "\(prefix)" + String(format:"%.2f", absOffsetPercentage) + "%"
		offsetLabel.textColor = color
		offsetLabel.isHidden = false
		
		if (shouldPlayMusic(note: pitch.note.string)) {
			pitchEngine.stop()
			playSound("")
		}
	}
	
	func shouldPlayMusic(note: String) -> Bool {
		if (note == "E4") {
			return true
		}
		return false
	}
	
	func pitchEngine(_ pitchEngine: PitchEngine, didReceiveError error: Error) {
		print(error)
	}
	
	public func pitchEngineWentBelowLevelThreshold(_ pitchEngine: PitchEngine) {
		print("Below level threshold")
	}
}


extension ViewController: AVAudioPlayerDelegate {
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		print ("Finished playing")
		pitchEngine.start()
	}
}

