F1reBahnAPIManager
==================

Manager for handling request to the Deutsche Bahn Service pages, requesting stations and connections

** Initialization **

let bahnManager = F1reBahnAPIManager()

** Retrieving Stations**

let stationName = "Hauptbahnhof München"
bahnManager.getStation(stationName, callback: { (success, result) -> () in
    if success {
      // Example JSON Output
          suggestions =     (
                {
            extId = 008000261;
            id = "A=1@O=M\U00fcnchen Hbf@X=11558338@Y=48140228@U=80@L=008000261@B=1@p=1428442724@";
            prodClass = 31;
            state = id;
            type = 1;
            typeStr = "[Bhf/Hst]";
            value = "M\U00fcnchen Hbf";
            weight = 25532;
            xcoord = 11558338;
            ycoord = 48140228;
        },
                {
            extId = 000626375;
            id = "A=1@O=M\U00fcnchen Hauptbahnhof@X=11561134@Y=48140399@U=80@L=000626375@B=1@p=1428442724@";
            prodClass = 416;
            state = id;
            type = 1;
            typeStr = "[Bhf/Hst]";
            value = "M\U00fcnchen Hauptbahnhof";
            weight = 4840;
            xcoord = 11561134;
            ycoord = 48140399;
    );
    }
})

** Retrieving Connections **

let start = "München Hbf"
let destination = "Hamburg Hbf"
let date = "10.04.15"
let time = "15:00"
bahnManager.getConnections(start, destination: destination, date: date, time: time, callback: { (success, result) -> () int
  if success {
    // result contains dictionary with departure = arrival time
    "05:05" = "10:55";
    "05:51" = "11:55";
    "06:53" = "12:53";
    "07:52" = "13:54";
    "09:05" = "14:54";
    }
})
