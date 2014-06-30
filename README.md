Sample code for implementation of Amazon SNS, Parse Push, Urban Airship, and Azure Mobile Hub in an iOS client
======================================

Some sample REST code to push to both Urban Airship and Parse is below (the keys would have to be replaced to their actual values):


**Basic Push to IOS devices with an extra payload key-value pair for a url**

curl -X POST   
-H "X-Parse-Application-Id: appID"   
-H "X-Parse-REST-API-Key: RESTKey"   
-H "Content-Type: application/json"   -d '{
        "channels": [
          "iOS"
        ],
        "data": {
          "alert": "Hi TabbedOut.", "web" : "https://www.google.com/"
        }
      }' \
 https://api.parse.com/1/push

Only to Citi Push: Sends a push to all iOS devices where the citi flag is true. The alert is "hi" and the badge is set to 3

curl -X POST \
  -H "X-Parse-Application-Id: appID" \
  -H "X-Parse-REST-API-Key: RESTKey" \
  -H "Content-Type: application/json" \
  -d '{
        "where": {
          "deviceType": "ios", 
	"citi": true
        },
        "data": {
             "alert": "hi", "badge":3 }}
' \
  https://api.parse.com/1/push

Tabbedout Both Background Code: Sends a background push (invisible to user) with one extra key value pair ("extra")

curl -X POST \
  -H "X-Parse-Application-Id: AppID" \
  -H "X-Parse-REST-API-Key: RESTKey" \
  -H "Content-Type: application/json" \
  -d '{
        "channels": [
          "iOS", "android"
        ],
        "data": {
"sound": "",
"extra": "Testing",
          "content-available": "1", 
          "action": "com.tabbedout.BACKGROUND_PUSH"
        }
      }' \
  https://api.parse.com/1/push

Query for Location: Queries for the 10 devices closest to a given geo-point. 

curl -X GET \
  -H "X-Parse-Application-Id: AppID" \
  -H "X-Parse-Master-Key: MasterKey" \
 -G \
  --data-urlencode 'limit=10' \
  --data-urlencode 'where={
        "userLocation": {
          "$nearSphere": {
            "__type": "GeoPoint",
            "latitude": 30.0,
            "longitude": -90.0
          }
        }
      }' \
  https://api.parse.com/1/installations

Urban Airship Push (with extra payload): Sends a push to all iOS devices with given alert and the default sound. Sets the badge to 40 and has 3 extra key-value pairs

curl -X POST -u "MasterKey" \
   -H "Content-Type: application/json" \
   -H "Accept: application/vnd.urbanairship+json; version=3;" \
   --data '{
  "audience": "all",
   "notification": {
      "alert": "Extras example",
      "ios": { "sound": "default", "badge" : 40,
        "extra": {
            "url": "http://example.com",
            "story_id": "1234",
            "moar": {"key": "value"}
         }
      }
   },
   "device_types": ["ios"]
}' \
   https://go.urbanairship.com/api/push/
