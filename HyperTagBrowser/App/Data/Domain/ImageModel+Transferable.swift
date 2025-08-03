// created on 2/18/25 by robinsr

import CoreTransferable
import Foundation
import UniformTypeIdentifiers


/**
  ImageModel can be transferred between apps
 */
//extension ImageModel: Transferable {
//  static var transferRepresentation: some TransferRepresentation {
//    DataRepresentation(contentType: .png) { image in
//      try! image.pngData()
//    } importing: { data in
//      let image = try TransferedImage(data: data, contentType: .png)
//
//      return ImageModel(imageURL: image.url)
//    }
//    
//    /**
//     Allows the image to be dragged to apps accepting PNG data
//     */
//    DataRepresentation(exportedContentType: .png) { image in
//      try! image.pngData()
//    }
//    
//    /**
//     Allows the image to be dragged to apps accepting file URLs
//     */
//    DataRepresentation(exportedContentType: .fileURL) { image in
//      image.imageURL.dataRepresentation
//    }
//  }
//  
//  struct TransferedImage {
//    let url: URL
//    let pointer: ContentPointer
//    
//    init(data: Data, contentType uttype: UTType) throws {
//      let id = String.randomIdentifier(32)
//      let ext = uttype.filenameExtensions[0]
//      
//      self.url = URL.temporaryDirectory
//        .appendingPathComponent("\(id).\(ext)", conformingTo: uttype)
//
//      self.pointer = ContentPointer(fileURL: self.url)
//      
//      try data.write(to: self.url)
//    }
//  }
//}
