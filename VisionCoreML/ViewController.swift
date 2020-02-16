import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()
    let output: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    var previewLayer:AVCaptureVideoPreviewLayer!

    public var segOption: UISegmentedControl!
    public var segFontSize: UISegmentedControl!
    public var segOnOff: UISegmentedControl!
    
    public var myImageView: UIImageView!
    public var coremlAd = CoreMLAdapter()
    public var visionAd = VisionAdapter()
    var detecting:Bool = false
    var timer:Timer!
 
    enum OptionType {
        case coreml
        case vision
        case face
    }
    public var fOption:OptionType = .coreml
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector:#selector(self.changedDeviceOrientation(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)

        // Image
        let w1:CGFloat = self.view.bounds.height/9*16
        let h1:CGFloat = self.view.bounds.height
        let x1:CGFloat = (w1 - self.view.bounds.width)/2 * -1
        let y1:CGFloat = 0
        
        let myImage:UIImage = clearImage(size: CGSize(width:w1, height:h1))!
        self.myImageView = UIImageView(image: myImage)
        myImageView.frame = CGRect(x:x1, y:y1, width:w1, height:h1)
        self.view.addSubview(myImageView)
        
        // Segment
        let params1 = ["CoreML","Vision","Face"]
        self.segOption = UISegmentedControl(items: params1)
        self.segOption.tintColor = UIColor.white
        self.segOption.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        self.segOption.selectedSegmentIndex = 0
        self.segOption.addTarget(self, action: #selector(onOptionChanged(_:)), for: UIControl.Event.valueChanged)
        self.view.addSubview(self.segOption)

        let params2 = ["Play","Stop"]
        self.segOnOff = UISegmentedControl(items: params2)
        self.segOnOff.tintColor = UIColor.white
        self.segOnOff.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        self.segOnOff.selectedSegmentIndex = 0
        self.view.addSubview(self.segOnOff)

        self.setPosition()
        
        // Start camera capture
        self.startCapture()
        
        // Timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector:#selector(self.onTimer(_:)), userInfo: nil, repeats: true)
        timer.fire()
    }

    /// Camera rotation
    @objc func changedDeviceOrientation(_ notification :Notification) {
        previewLayer!.frame = view.bounds

        var vori:AVCaptureVideoOrientation = .portrait
        switch UIDevice.current.orientation {
        case .portrait:           vori = .portrait
        case .portraitUpsideDown: vori = .portraitUpsideDown
        case .landscapeLeft:      vori = .landscapeRight
        case .landscapeRight:     vori = .landscapeLeft
        default: break
        }
        previewLayer.connection!.videoOrientation = vori
        self.setPosition()
    }
    
    /// Align UI
    private func setPosition() {
        let w:CGFloat = UIScreen.main.bounds.size.width
        let h:CGFloat = UIScreen.main.bounds.size.height

        let w1:CGFloat = h/9*16
        let h1:CGFloat = h
        let x1:CGFloat = (w1-w)/2 * -1
        let y1:CGFloat = 0

        let w2:CGFloat = w
        let h2:CGFloat = w/9*16
        let x2:CGFloat = 0
        let y2:CGFloat = (h2-h)/2 * -1
        
        if isLandscape() {
            self.myImageView.frame = CGRect.init(x:x1, y:y1, width:w1, height:h1)
        } else {
            self.myImageView.frame = CGRect.init(x:x2, y:y2, width:w2, height:h2)
        }

        self.segOption.frame = CGRect(x: 20, y: h-90, width: 240, height: 32)
        self.segOnOff.frame = CGRect(x: 20, y: h-50, width: 160, height: 32)
    }
  
    /// Start camera capture
    private func startCapture() {
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        
        // Input setting
        let captureDevice = AVCaptureDevice.default(for: .video)!
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard captureSession.canAddInput(input) else { return }
        captureSession.addInput(input)
        
        // Output setting
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        guard captureSession.canAddOutput(output) else { return }
        captureSession.addOutput(output)
        
        // Preview settings
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        // Start capture
        captureSession.startRunning()
    }

    /// Called every second
    @objc func onTimer(_ tm: Timer) {
        if isLandscape() {
            UIGraphicsBeginImageContext(CGSize(width:1280, height:720))
        } else {
            UIGraphicsBeginImageContext(CGSize(width:720, height:1280))
        }
        
        let font = UIFont.systemFont(ofSize: self.fontsize())
        let attrs = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: UIColor.green
        ]
        
        if fOption == .coreml {
            // CoreML
            var text:String = ""
            let clss = self.coremlAd.result.clss.sorted{ $0.value > $1.value }
            for (key,val) in clss.prefix(3) {
                let key2 = key.components(separatedBy: ", ")[0]
                text += String(NSString(format: "%02d", val)) + " " + key2 + "\n"
            }
            
            let w:CGFloat = UIScreen.main.bounds.size.width
            let h:CGFloat = UIScreen.main.bounds.size.height
            if isLandscape() {
                let x1:CGFloat = (h/9*16-w)/2
                text.draw(at: CGPoint(x:x1+20, y:50), withAttributes: attrs)
            } else {
                let y2:CGFloat = (w/9*16-h)/2
                text.draw(at: CGPoint(x:20, y:y2+50), withAttributes: attrs)
            }
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            self.myImageView.image = image
            
        } else if fOption == .vision {
            // Vision
            for r in self.visionAd.results {
                UIColor.green.setStroke()
                r.bzFaceContour.stroke()
                r.bzLeftEye.stroke()
                r.bzRightEye.stroke()
                r.bzInnerLips.stroke()
                r.bzNose.stroke()
                r.bzLeftEyebrow.stroke()
                r.bzRightEyebrow.stroke()
                //r.bzNoseCrest.stroke()
                r.bzOuterLips.stroke()
                //r.bzMedianLine.stroke()
                r.bzLeftPupil.stroke()
                r.bzRightPupil.stroke()
            }
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            self.myImageView.image = image
      
        } else if fOption == .face {
            // Face
            for r in self.visionAd.results {
                UIColor.green.setStroke()
                let bzRect = UIBezierPath(rect: r.bounds)
                bzRect.lineWidth = 4
                bzRect.stroke()
                /*
                UIColor.green.setStroke()
                let bzRect = UIBezierPath(rect: r.bounds)
                bzRect.stroke()
                
                let clss = r.clss.sorted{ $0.value > $1.value }
                var text:String = ""
                for (key,val) in clss.prefix(1) {
                    text += (NSString(format:"%02d ",val) as String) + key + "\n"
                }
                text.draw(at: CGPoint(x:r.bounds.minX, y:r.bounds.maxY), withAttributes: attrs)
                */
            }
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            self.myImageView.image = image
        }
    }
    
    /// Called every 1 frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Inherit AVCaptureVideoDataOutputSampleBufferDelegate
        if self.myImageView == nil {
            return
        }
        guard var buffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        
        if fOption == .coreml {
            if (self.detecting == false && onoff()) {
                self.detecting = true
                DispatchQueue(label:"detecting.queue").async {
                    let ciImage:CIImage = CIImage(cvPixelBuffer: buffer)
                    let ciCopyImage = ciImage.copyImage()
                    self.coremlAd.recognize(ciImage: ciCopyImage)
                    
                    usleep(1000*1000)
                    self.detecting = false
                }
            }
        } else if fOption == .vision || fOption == .face {
            if (self.detecting == false && onoff()) {
                self.detecting = true
                DispatchQueue(label:"detecting.queue").async {
                    let ciImage:CIImage = CIImage(cvPixelBuffer: buffer)
                    let ciCopyImage = ciImage.copyImage()
                    var uiImage:UIImage! = UIImage(ciImage: ciCopyImage)
                    
                    switch UIDevice.current.orientation {
                    case .portrait: uiImage = uiImage.rotated(90.0)
                    case .portraitUpsideDown: uiImage = uiImage.rotated(270.0)
                    case .landscapeLeft: break
                    case .landscapeRight: uiImage = uiImage.rotated(180.0)
                    default: break
                    }
                    self.visionAd.recognizeFace(on: uiImage.safeCiImage!)
                    
                    usleep(1000*1000) 
                    self.detecting = false
                }
            }
        }
    }

    @objc func onOptionChanged(_ sender: UISegmentedControl) {
        if self.segOption.selectedSegmentIndex == 0 { fOption = .coreml }
        else if self.segOption.selectedSegmentIndex == 1 { fOption = .vision }
        else { fOption = .face }
    }
    
    func fontsize() -> CGFloat {
        return 50
    }

    func onoff() -> Bool {
        if self.segOnOff.selectedSegmentIndex == 0 { return true }
        else { return false }
    }
    
    /// Whether the screen is sideways
    private func isLandscape() -> Bool {
        if UIDevice.current.orientation == .landscapeLeft ||
           UIDevice.current.orientation == .landscapeRight {
            return true
        } else {
            return false
        }
    }

    /// Transparent image
    private func clearImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(UIColor.clear.cgColor)
        let rect = CGRect(origin: .zero, size: size)
        context.fill(rect)
        let toumeiImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = toumeiImage else {
            return nil
        }
        return image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }    
}

