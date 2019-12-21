import Foundation

//let clientID = "14889474134.880645367557"
//let clientSecret = "7e2220fc0fc0aaf8d205645fd12b9024"
let clientID = "4268112882.884578806454"
let clientSecret = "00fb3fa2c9b5bd6888e7990e03697f5c"

let authURL = URL(string: "https://slack.com/oauth/authorize?client_id=\(clientID)&scope=client")!
let callbackURLScheme = "com.kishikawakatsumi.work-app"
