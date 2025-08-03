// created on 10/24/24 by robinsr

import JulianDayNumber
import Foundation


extension Date {
  
  func formatted(_ format: DateFormatter) {
    format.string(from: self)
  }
  
  
  static func parseDateString(_ dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    
    dateFormatter.dateFormat = "yyyy/MM/dd"
    
    if let slashDate = dateFormatter.date(from: dateString) {
      return slashDate
    }
    
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    if let shortIsoDate = dateFormatter.date(from: dateString) {
      return shortIsoDate
    }
    
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    if let isoDateAndTime = dateFormatter.date(from: dateString) {
      return isoDateAndTime
    }
    
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    if let isoDateTime = dateFormatter.date(from: dateString) {
      return isoDateTime
    }
    
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    
    if let isoDateTimeWithMillis = dateFormatter.date(from: dateString) {
      return isoDateTimeWithMillis
    }
    
    // If no formats matched, return nil
    print("Error: Unable to parse date string '\(dateString)'")
    
    return nil
  }
  
  // TODO: There is some wonky date conversion going on here. Need to investigate, likely a timezone issue
  
  /**
   Returns the Julian Day equivalent of this date as an integer. Usefeful for
   easily calculating elapsed days between two events
   
   Example:
   ```
    let date1 = Date()
    let date2 = Date(timeIntervalSinceNow: -86400)
    let elapsedDays = date1.julianDayNumber() - date2.julianDayNumber()
    print(elapsedDays) // 1
   
   let janFirst2024 = Date().julianDayNumber() // 2459243
   
    ```
   */
  func julianDayNumber() -> Double {
    let jdate = GregorianCalendar.julianDateFrom(
      year: year, month: month, day: day
    )
    
    // JulainDay == Double, FYI
    return jdate
  }
  
  
  /**
   Returns a `TimeInterval` (representing seconds) added or subtracted from the `to` date
   */
  static func offset(
    byAdding component: Calendar.Component,
    value: Int,
    to date: Date = .now
  ) -> TimeInterval {
    let adjustedDate = Calendar.current.date(
      byAdding: component,
      value: value,
      to: date
    )
    
    // TimeInterval == Double, FYI
    return adjustedDate?.timeIntervalSinceNow ?? 0
  }
  
  var time: TimeInterval {
    self.timeIntervalSince1970
  }
  
  /**
   Returns a `TimeInterval` (representing seconds) added or subtracted from this date
   */
  func offset(adding value: Int, of component: Calendar.Component) -> Date {
    if let newDate = Calendar.current.date(byAdding: component, value: value, to: self) {
      return newDate
    } else {
      print("Error: Could not calculate date offset")
      return self
    }
  }
  
  func offset(adding value: Duration) -> Date {
    offset(adding: Int(value.components.seconds), of: .second)
  }
  
  func offset(subtracting value: Int, of component: Calendar.Component) -> Date {
    offset(adding: -value, of: component)
  }
  
  func offset(subtracting value: Duration) -> Date {
    offset(adding: Int(-value.components.seconds), of: .second)
  }
}
