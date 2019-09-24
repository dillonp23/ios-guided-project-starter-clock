//
//  ClockView.swift
//  Clock
//
//  Created by Ben Gohlke on 6/24/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UIKit

struct Hand {
    let width: CGFloat // in points
    // length is proportionate to size of view, so the higher the number,
    // the shorter the hand length
    let length: CGFloat
    let color: UIColor
    // 1-12 for hour, 0-60 for minutes/seconds
    var value: Int = 0
}

@IBDesignable
class ClockView: UIView {
    
    // MARK: - Properties
    
    // Used to sync timing of animation events to the refresh rate of the display
    private var animationTimer: CADisplayLink?
    
    /// Tracks the current timezone of the clock.
    /// Automatically configures the timer to run in sync with the screen
    /// and update the face each second.
    var timezone: TimeZone? {
        didSet {
            let aTimer = CADisplayLink(target: self, selector: #selector(timerFired(_:)))
            aTimer.preferredFramesPerSecond = 1
            aTimer.add(to: .current, forMode: .common)
            animationTimer = aTimer
        }
    }
    
    private var seconds = Hand(width: 1.0, length: 2.4, color: .red, value: 0)
    private var minutes = Hand(width: 3.0, length: 3.2, color: .white, value: 0)
    private var hours = Hand(width: 4.0, length: 4.6, color: .white, value: 0)
    
    private var secondHandEndPoint: CGPoint {
        let secondsAsRadians = Float(Double(seconds.value) / 60.0 * 2.0 * Double.pi - Double.pi / 2)
        let handLength = CGFloat(frame.size.width / seconds.length)
        return handEndPoint(with: secondsAsRadians, and: handLength)
    }
    
    private var minuteHandEndPoint: CGPoint {
        let minutesAsRadians = Float(Double(minutes.value) / 60.0 * 2.0 * Double.pi - Double.pi / 2)
        let handLength = CGFloat(frame.size.width / minutes.length)
        return handEndPoint(with: minutesAsRadians, and: handLength)
    }
    
    private var hourHandEndPoint: CGPoint {
        let totalHours = Double(hours.value) + Double(minutes.value) / 60.0
        let hoursAsRadians = Float(totalHours / 12.0 * 2.0 * Double.pi - Double.pi / 2)
        let handLength = CGFloat(frame.size.width / hours.length)
        return handEndPoint(with: hoursAsRadians, and: handLength)
    }
    
    private let clockBgColor = UIColor.black
    
    private let borderColor = UIColor.white
    private let borderWidth: CGFloat = 2.0
    
    private let digitColor = UIColor.white
    private let digitOffset: CGFloat = 15.0
    private var digitFont: UIFont {
        return UIFont.systemFont(ofSize: 8.0 + frame.size.width / 50.0)
    }
    
    // MARK: - View Lifecycle
    
    // gets used when creating view programatically
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    // getting used when creating view from storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) { // argumenmt gives info about width and height of view
        /// Note: elements are drawn on the the screen from back to front
        /// this is beacause the context methods (fill and stroke, etc) will stay the same until fill path is called, so continue to draw and layer like in graphic design
        /// in the order they appear below.
        
        // the context is the canvas in which we draw
        if let context = UIGraphicsGetCurrentContext() {
            // CG Context ->> we have a canvas and we want to draw. like vector drawing programmatically
            
//            example of red rectangle:
//            context.addRect(CGRect(x: 20, y: 50, width: 100, height: 5))
//            context.setFillColor(UIColor.red.cgColor)
            
            
            // clock face:
            
            // an ellipse is circle or oval
            context.addEllipse(in: rect)
            context.setFillColor(clockBgColor.cgColor)
            
            // the method that actually draws on the screen:
            context.fillPath()
            
            
            // clock's border
            // try to stay away from hard coding numbers/ use properties with minor changes in order to proportiionally and scale accordingly
            let insetCircleRect = CGRect(x: rect.origin.x + borderWidth / 2,
                                         y: rect.origin.y + borderWidth / 2,
                                         width: rect.size.width - borderWidth,
                                         height: rect.size.height - borderWidth)
            
            context.addEllipse(in: insetCircleRect) // with no insets the stroke gets cut off so must add
            context.setStrokeColor(borderColor.cgColor)
            context.setLineWidth(borderWidth)
            
            // method that will draw border:
            context.strokePath()
            
            /// pattern emerges: add some shape or line, change properties, and then draw it
            
            
            
            // numerals
            let clockCenter = CGPoint(x: rect.size.width / 2.0,
                                      y: rect.size.height / 2.0)
            let numeralDistanceFromCenter = rect.size.width / 2.0 - digitFont.lineHeight / 4.0 - digitOffset
            let offset = 3 /// offsets numerals, putting "12" at the top of the clock

            for i in 1...12 {    /// use something very efficient by drawing all numbers without having twelve labels
                let hourString: NSString
                if i < 10 {
                    hourString = " \(i)" as NSString
                } else {
                    hourString = "\(i)" as NSString
                }
                let labelX = clockCenter.x + (numeralDistanceFromCenter - digitFont.lineHeight / 2.0)
                    * CGFloat(cos((Double.pi / 180) * Double(i + offset) * 30 + Double.pi))
                let labelY = clockCenter.y - 1 * (numeralDistanceFromCenter - digitFont.lineHeight / 2.0)
                    * CGFloat(sin((Double.pi / 180) * Double(i + offset) * 30))
                hourString.draw(in: CGRect(x: labelX - digitFont.lineHeight / 2.0,
                                           y: labelY - digitFont.lineHeight / 2.0,
                                           width: digitFont.lineHeight,
                                           height: digitFont.lineHeight),
                                withAttributes: [NSAttributedString.Key.foregroundColor: digitColor,
                                                 NSAttributedString.Key.font: digitFont]) /// attributed strings allow the equivalent of rich text in MSWord
            }
            
            // minute hand
            
            context.move(to: clockCenter)
            context.addLine(to: minuteHandEndPoint)
            
            context.setLineWidth(minutes.width)
            context.setStrokeColor(minutes.color.cgColor)
            context.strokePath()
            
            
            // hour hand
            
            context.move(to: clockCenter)
            context.addLine(to: hourHandEndPoint)
            
            context.setLineWidth(hours.width)
            context.setStrokeColor(hours.color.cgColor)
            context.strokePath()
            
            
            // hour/minute's center
            
            let radius: CGFloat = 6
            let centerCircleRect = CGRect(x: rect.size.width / 2.0 - radius, y: rect.size.height / 2.0 - radius, width: radius * 2, height: radius * 2)
            
            context.addEllipse(in: centerCircleRect)
            context.setFillColor(hours.color.cgColor)
            context.fillPath()
            
            // second hand
            
            context.move(to: clockCenter)
            context.addLine(to: secondHandEndPoint)
            
            context.setStrokeColor(seconds.color.cgColor)
            context.setLineWidth(seconds.width)
            
            context.strokePath()
            
            // second's center
            
            let secondRadius: CGFloat = 3
            let secondHandCenter = CGRect(x: clockCenter.x - secondRadius,
                                          y: clockCenter.y - secondRadius,
                                          width: secondRadius * 2,
                                          height: secondRadius * 2)
            
            context.addEllipse(in: secondHandCenter)
            context.setFillColor(seconds.color.cgColor)
            context.fillPath()
            
        }
    }
    
    @objc func timerFired(_ sender: CADisplayLink) {
        // Get current time
        let currentTime = Date()
        
        // Get calendar and set timezone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone!
        
        // Extract hour, minute, second components from current time
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: currentTime)
        
        // Set above components to hours, minutes, seconds properties
        hours.value = timeComponents.hour ?? 0
        minutes.value = timeComponents.minute ?? 0
        seconds.value = timeComponents.second ?? 0
        
        // Trigger a screen refresh
        setNeedsDisplay() // when we reset soemthing and need to redraw everything
        
    }
    
    deinit {
        // Animation timer is removed from the current run loop when this view object
        // is deallocated.
        animationTimer?.remove(from: .current, forMode: .common)
    }
    
    // MARK: - Private
    
    private func handEndPoint(with radianValue: Float, and handLength: CGFloat) -> CGPoint {
        return CGPoint(x: handLength * CGFloat(cosf(radianValue)) + frame.size.width / 2.0,
                       y: handLength * CGFloat(sinf(radianValue)) + frame.size.height / 2.0)
    }
}
