extends Resource
class_name YatcPointsCustomReward

## = "torpedo09"
@export var broadcaster_name: String
## = "torpedo09"
@export var broadcaster_login: String
## = "274637212"
@export var broadcaster_id: String
##  = "92af127c-7326-4483-a52b-b0da0be61c01"
@export var id: String
## "image": {
## 	"url_1x": "https://static-cdn.jtvnw.net/custom-reward-images/default-1.png",
## 	"url_2x": "https://static-cdn.jtvnw.net/custom-reward-images/default-2.png",
## 	"url_4x": "https://static-cdn.jtvnw.net/custom-reward-images/default-4.png"
## }
@export var image: Dictionary
## = "#00E5CB"
@export var background_color: String
## = true
@export var is_enabled: bool
## = 50000
@export var cost: int
## = "game analysis"
@export var title: String
## = ""
@export var prompt: String
## = false
@export var is_user_input_required: bool
## "max_per_stream_setting": {
## 	"is_enabled": false,
## 	"max_per_stream": 0
## }
@export var max_per_stream_setting: Dictionary
## "max_per_user_per_stream_setting": {
## 	"is_enabled": false,
## 	"max_per_user_per_stream": 0
## }
@export var max_per_user_per_stream_setting: Dictionary
## "global_cooldown_setting": {
## 	"is_enabled": false,
## 	"global_cooldown_seconds": 0
## }
@export var global_cooldown_settin: Dictionary
## = false
@export var is_paused: bool
## = true
@export var is_in_stock: bool
## "default_image": {
## 	"url_1x": "https://static-cdn.jtvnw.net/custom-reward-images/default-1.png",
## 	"url_2x": "https://static-cdn.jtvnw.net/custom-reward-images/default-2.png",
## 	"url_4x": "https://static-cdn.jtvnw.net/custom-reward-images/default-4.png"
## }
@export var default_image: Dictionary
## = false
@export var should_redemptions_skip_request_queue: bool
@export var redemptions_redeemed_current_stream: int
@export var cooldown_expires_at: String

func _init(json: Dictionary = {}):
	for entry in self.get_script().get_script_property_list():
		if !json.has(entry.name): continue
		var value = json.get(entry.name)
		if value == null: continue
		self[entry.name] = value


func to_dictionary() -> Dictionary:
	var obj = {}

	for entry in self.get_script().get_script_property_list():
		if entry.type == TYPE_NIL: continue
		obj.set(entry.name, self[entry.name])

	return obj
