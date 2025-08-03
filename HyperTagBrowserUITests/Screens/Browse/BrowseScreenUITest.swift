// Created by robinsr on 2024-11-17

import Quick
import Nimble
import XCTest

import CustomDump

@testable import TaggedFileBrowser


/*
 
TODOs to figure out
 
 - how to launch the app to a specific location
 - how to check for specific elements on the screen
 - how to interact with those elements
 - how to check for specific attributes of those elements
 - how to take a screenshot of the screen
 
 
 
 */



class BrowseScreenSpec: QuickSpec {
  override class func spec() {
  
    describe("BrowseScreen") {
      
      
      it("launches the app") {
        let app = XCUIApplication()
        app.launchArguments = [
          "-LaunchProfileName=Default",
          "-LaunchFolderPath=\(TestData.testImageDir)"
          
        ]
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        
        let imageAttributes = app.descendants(matching: .grid).descendants(matching: .image).attributeKeys
        
        customDump(imageAttributes, name: "imageAttributes")
        
        expect(imageAttributes).to(beNil())
      }

      context("if it doesn't have what you're looking for") {
        it("needs to be updated") {
          expect{true}.to(beTrue())
        }
      }
    }
  }
}
