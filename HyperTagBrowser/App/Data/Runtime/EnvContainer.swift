// created on 4/8/25 by robinsr

import Factory
import OSLog


public final class EnvContainer: SharedContainer {
  public static let shared = EnvContainer()
  public let manager = ContainerManager()
  
  private let log = Logger.newLog(label: "EnvContainer")
}


/**
 * Example of how to override the default arguments in FactoryContext
 */
// extension FactoryContext {
//   var arguments: [String] {
//     return ["BigBootyJudy"]
//   }
// }


/**
 * A container for the broadest dependencies and values. eg BundleId, stage name/ID, etc
 */
extension EnvContainer: AutoRegistering {
  
  public func autoRegister() {
    log.emit(.debug, "Auto-Registering EnvContainer")
    
    let factoryArgs = FactoryContext.current.arguments.map { "\($0)" }
    let factoryRuntimeArgs = FactoryContext.current.runtimeArguments.map { "\($0)" }
    
    log.emit(.info, """
    Starting \(Constants.appname)...
      - EnvContainer.bundleIdentider: \(Self.shared.bundleIdentider())
      - EnvContainer.stageId: \(Self.shared.stageId())  
      - EnvContainer.stageName: \(Self.shared.stageName())
      - EnvContainer.runFlags: \(json: Self.shared.runFlags(), .compact)
      - FactoryContext.isDebug: \(FactoryContext.current.isDebug)
      - FactoryContext.isTest: \(FactoryContext.current.isTest)
      - FactoryContext.isPreview: \(FactoryContext.current.isPreview)
      - FactoryContext.isSimulator: \(FactoryContext.current.isSimulator)
      - FactoryContext.arguments: \(json: factoryArgs, .compact)
      - FactoryContext.runtimeArguments: \(json: factoryRuntimeArgs, .compact)
    """)
  }

  var runFlags: Factory<RunFlags> {
    self {
      RunFlags()
    }
    .scope(.cached)
  }
  
  var stage: Factory<AppStage> {
    self {
      #if DEBUG
      return AppStage.dev
      #elseif TEST
      return AppStage.test
      #else
      return AppStage.prod
      #endif
    }
    .onPreview {
      AppStage._preview
    }
    .scope(.cached)
  }
  
    /// The string identifier for the current stage
  var stageId: Factory<String> {
    self {
      self.stage().rawValue
    }
    .scope(.cached)
  }
  
    /// The display name for the current stage; empty string for `prod`
  var stageName: Factory<String> {
    self {
      self.stage().displayName
    }
    .scope(.cached)
  }
  
  var bundleIdentider: Factory<String> {
    self {
      Bundle.main.cfBundleIdentifier
    }
    .scope(.cached)
  }
  
  var stagedPath: Factory<DotPath> {
    self {
      let bundleId = self.bundleIdentider()
      let stageName = self.stageName()
      
      return [ bundleId, stageName ].asDotPath
    }
    .scope(.cached)
  }
  
  var logger: ParameterFactory<String, Logger> {
    self {
      Logger.newLog(label: $0)
    }
    .scope(.singleton)
  }
}
