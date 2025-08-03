#  Metrics README


### Creating Parent/Child Spans

```swift
  func parent() {
    let parentSpan = tracerProvider.spanBuilder(spanName: "parent span")
                        .setActive(true) // automatically sets context
                        .startSpan()
    child()
    parentSpan.end()
  }

  func child() {
    let childSpan = tracerProvider.spanBuilder(spanName: "child span")
                               .startSpan() //automatically captures `active span` as parent
    // do work
    childSpan.end()
  }
```


 ### `SpanData` dump
 
 ```json
 {
   "attributes" : {

   },
   "endTime" : "2025-02-03T17:29:35Z",
   "events" : [

   ],
   "hasEnded" : true,
   "hasRemoteParent" : false,
   "instrumentationScope" : {
     "name" : "TaggedFileBrowser",
     "version" : "semver:0.1.0"
   },
   "kind" : "internal",
   "links" : [

   ],
   "name" : "ListIndexInfoRequest",
   "resource" : {
     "attributes" : {
       "device.model.identifier" : {
         "string" : {
           "_0" : "MacBookPro18,1"
         }
       },
       "os.description" : {
         "string" : {
           "_0" : "macOS Version 15.2 (Build 24C101)"
         }
       },
       "os.name" : {
         "string" : {
           "_0" : "macOS"
         }
       },
       "os.type" : {
         "string" : {
           "_0" : "darwin"
         }
       },
       "os.version" : {
         "string" : {
           "_0" : "15.2.0"
         }
       },
       "service.name" : {
         "string" : {
           "_0" : "TaggedFileBrowser"
         }
       },
       "service.version" : {
         "string" : {
           "_0" : "0.0.1 (2)"
         }
       },
       "telemetry.sdk.language" : {
         "string" : {
           "_0" : "swift"
         }
       },
       "telemetry.sdk.name" : {
         "string" : {
           "_0" : "opentelemetry"
         }
       },
       "telemetry.sdk.version" : {
         "string" : {
           "_0" : "1.13.0"
         }
       }
     }
   },
   "spanId" : {
     "id" : 6224395909419869861
   },
   "startTime" : "2025-02-03T17:29:35Z",
   "status" : {
     "unset" : {

     }
   },
   "totalAttributeCount" : 0,
   "totalRecordedEvents" : 0,
   "totalRecordedLinks" : 0,
   "traceFlags" : {
     "options" : 1
   },
   "traceId" : {
     "idHi" : 1245352575339107557,
     "idLo" : 8105605537029945409
   },
   "traceState" : {
     "entries" : [

     ]
   }
 }
 ```
 
 
 Copy/Paste from StdoutSpanExporter:
 
 
 ```swift
 print("__________________")
 print("Span \(span.name):")
 print("TraceId: \(span.traceId.hexString)")
 print("SpanId: \(span.spanId.hexString)")
 print("Span kind: \(span.kind.rawValue)")
 print("TraceFlags: \(span.traceFlags)")
 print("TraceState: \(span.traceState)")
 print("ParentSpanId: \(span.parentSpanId?.hexString ?? SpanId.invalid.hexString)")
 print("Start: \(span.startTime.timeIntervalSince1970.toNanoseconds)")
 print("Duration: \(span.endTime.timeIntervalSince(span.startTime).toNanoseconds) nanoseconds")
 print("Attributes: \(span.attributes)")
 if !span.events.isEmpty {
     print("Events:")
     for event in span.events {
         let ts = event.timestamp.timeIntervalSince(span.startTime).toNanoseconds
         print("  \(event.name) Time: +\(ts) Attributes: \(event.attributes)")
     }
 }
 print("------------------\n")
```
