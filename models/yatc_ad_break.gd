extends Resource
## "event": {
##   "duration_seconds": "60",
##   "started_at": "2019-11-16T10:11:12.634234626Z",
##   "is_automatic": false,
##   "broadcaster_user_id": "1337",
##   "broadcaster_user_login": "cool_user",
##   "broadcaster_user_name": "Cool_User",
##   "requester_user_id": "1337",
##   "requester_user_login": "cool_user",
##   "requester_user_name": "Cool_User",
## }
class_name YatcAdBreak

@export
var duration_seconds: float
@export
var started_at: float
@export
var is_automatic: bool
@export
var broadcaster_user_id: String
@export
var broadcaster_user_login: String
@export
var broadcaster_user_name: String
@export
var requester_user_id: String
@export
var requester_user_login: String
@export
var requester_user_name: String




func _init(json: Dictionary):
	## key: String -> local variable name
	## value: Array[String] -> possible json keys that match the local information
	const MAPPING = {
		# 'display_name': ['chatter_user_name'],
	}
	for entry in self.get_property_list():
		var keys = MAPPING.get(entry.name, [entry.name])
		for key in keys:
			if !json.has(key): continue
			var value = json.get(key)
			if value == null: continue
			self[entry.name] = value
