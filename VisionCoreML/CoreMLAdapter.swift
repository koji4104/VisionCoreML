import UIKit
import AVFoundation
import Vision
import CoreML

class FaceModel : CoreMLAdapter {
    override func model() -> MLModel { return Face().model }
}

class CoreMLAdapter {
    func model() -> MLModel { return Inceptionv3().model }

    /// Result
    public var result:Result = Result()
    class Result {
        public var clss = [String:Int]()
    }
    
    /// Execution of image recognition
    func recognize(ciImage: CIImage) {
        self.result.clss = [String:Int]()
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([self.requestMymodel])
        } catch {
            print(error)
        }
    }
    
    /// Learning model request
    lazy var requestMymodel: VNCoreMLRequest = {
        do {
            var model: VNCoreMLModel? = nil
            model = try VNCoreMLModel(for: self.model())
            return VNCoreMLRequest(model: model!, completionHandler: self.completeModel)
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }
    }()

    /// Learning model result
    func completeModel(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else { 
            return 
        }
        // Change the top 3 to 100%
        for observation in results.prefix(3) {
            self.result.clss[observation.identifier] = (Int)(observation.confidence * 100.0)
        }
    }    
}
