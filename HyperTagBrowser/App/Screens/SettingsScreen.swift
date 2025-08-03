// Created by robisnr on 2024-09-05

import SwiftUI
import Factory
import Defaults
import IdentifiedCollections
import CustomDump



struct SettingsScreen: Scene {
  var body: some Scene {
    Settings {
      SettingsScreenContent()
    }
    .windowResizability(.contentMinSize)
  }
}

struct SettingsScreenContent: View {
  var tab: SettingsTab? = nil
  
  @Injected(\EnvContainer.stage) var appStage
  @Injected(\Container.colorTheme) var colorTheme
  @Injected(\PreferencesContainer.userProfile) var userProfile
  @Injected(\PreferencesContainer.userProfileId) var profileKey
  
  @Default(.backgroundOpacity) var userPreferredBgOpacity
  @Default(.backgroundColor) var userPreferedBgColor
  @Default(.sidebarPosition) var sidebarPosition
  @Default(.devFlags) var devFlags
  @Default(.debugQueryables) var queryableFlags
  
  @State var currentTab: SettingsTab = .general
  @State var showingHelpId: String?
  
  @State var helpState = HelpPopoverState()
  
  
  enum SettingsTab {
    case general, appearance, advanced
  }
  
  var body: some View {
    TabView(selection: $currentTab) {
      
      Tab("General", systemImage: "gear", value: .general) {
        SettingsForm {
          GeneralBehavior
          ProfileScopeSettings
          
          Text("Settings for profile'\(userProfile.name)'")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      Tab("Appearance", systemImage: "paintpalette", value: .appearance) {
        SettingsForm {
          AppearenceSettings
        }
      }
      
      Tab("Advanced", systemImage: "star", value: .advanced) {
        SettingsForm {
          DevelopmentSettings
        }
      }
    }
    .frame(minWidth: 300, maxWidth: .infinity)
    .onAppear {
      currentTab = tab ?? .general
    }
    .environment(\.helpPopover, helpState)
  }


  var GeneralBehavior: some View {
    Section("Behavior") {
      ForEach(UserToggles.allCases, id: \.self) { toggle in
        Defaults.Toggle(toggle.label, key: toggle.defaultsKey)
          .withHelpPopover(toggle)
      }
      
      Defaults.SelectInput(.photoGridItemLimit)
        .withHelpPopover(UserSelectPrefs<Int>.photoGridItemLimit)
      
      Defaults.SelectInput(.thumbnailQuality)
        .withHelpPopover(UserSelectPrefs<ThumbnailQuality>.thumbnailQuality)
      
      Defaults.SelectInput(.listEditorSuggestions)
        .withHelpPopover(UserSelectPrefs<Int>.listEditorSuggestions)
      
      Defaults.SelectInput(.imageBuffFactor)
        .withHelpPopover(UserSelectPrefs<ImageBuffingFactor>.imageBuffFactor)
    }
  }
  
  var ProfileScopeSettings: some View {
    Section("Folders") {
      ForEach(UserFolderPrefs.allCases, id: \.id) { pref in
        FilePathInput(
          selected: .userDefaultURL(pref.defaultsKey),
          label: pref.label,
          allowedTypes: pref.allowedTypes
        )
        .withHelpPopover(pref)
      }
    }
  }
  

  var AppearenceSettings: some View {
    Section {
      
      Defaults.SelectInput(.preferredScheme)
        .withHelpPopover(UserSelectPrefs<ColorSchemePreference>.preferredScheme)
      
      Defaults.SelectInput(.sidebarPosition)
        .pickerStyle(.segmented)
        .withHelpPopover(UserSelectPrefs<SidebarChirality>.sidebarPosition)
      
      LabeledContent {
        Slider(
          value: $userPreferredBgOpacity,
          in: 0...100,
          label: { EmptyView() },
          minimumValueLabel: { Text("0%") },
          maximumValueLabel: { Text("100%") }
        )
      } label: {
        Text("Window Transparency")
      }
      
      ColorGridPicker(
        selected: $userPreferedBgColor
          .map { colorTheme.option(for: $0) }
          .onChange { value in
            if let selected = value {
              Defaults[.backgroundColor] = selected.value.asColor
            }
          },
        options: colorTheme.asSelectables
      ) { color in
        if let chosen = color {
          Text(verbatim: "Background Color: \(chosen.label)")
        } else {
          Text(verbatim: "Background Color")
        }
      }
    }
  }
  
  @ViewBuilder
  var DevelopmentSettings: some View {
    Section("Development Settings") {
      Defaults.SelectInput(.searchMethod)
    }
    
    Section("Dev Flags") {
      List(DevFlags.list(for: appStage), id: \.rawValue) { flag in
        Defaults.ToggleListItem(key: .devFlags, value: flag) { val in
          Text(verbatim: val.description)
            .withHelpPopover(val)
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .padding(.vertical, 4)
      }
      .listStyle(.plain)
    }
    
    Section("Database Queryable Logging") {
      List(QueryableDevFlags.allCases.sorted(by: \.description).collect(), id: \.rawValue) { queryType in
        
        Defaults.ToggleListItem(key: .debugQueryables, value: queryType) { val in
          Text(val.description)
            .help("Enable request and/or response logging for \(val.rawValue) queries")
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .padding(.vertical, 4)
      }
      .listStyle(.plain)
    }
  }
  
  func SettingsForm(@ViewBuilder content: () -> (some View)) -> some View {
    Form {
      content()
    }
    .formStyle(.grouped)
  }
}










extension SwiftUI.Binding {
  
  static func userDefault<T>(_ key: Defaults.Key<T>) -> Binding<T> {
    Binding<T>(
      get: { Defaults[key] },
      set: { val in
        Defaults[key] = val
      }
    )
  }
  
  static func userDefaultURL(_ key: Defaults.Key<URL>) -> Binding<URL?> {
    Binding<URL?>(
      get: { Defaults[key] },
      set: { val in
        if let newUrl = val {
          Defaults[key] = newUrl
        } else {
          Defaults[key] = SystemLocation.null
        }
      }
    )
  }
}



#Preview("Settings Screen", traits: .defaultViewModel, .previewSize(.prefs)) {
  SettingsScreenContent(tab: .advanced)
}
