extends Resource
class_name YatcChatMessage

@export var message_id: String

@export_group('receiving only')
## { id: String, info: String, set_id: String }[]
@export var badges: Array
@export var broadcaster_user_id: String
## all lower case
@export var broadcaster_user_login: String
## user display name, equal to login except on casing
@export var broadcaster_user_name: String
@export var channel_points_animation_id = null
@export var channel_points_custom_reward_id = null
@export var chatter_user_id: String
@export var chatter_user_login: String
@export var chatter_user_name: String
@export var cheer = null
@export var color: String
## {
##   "fragments": [{
##     "cheermote" = null,
##     "emote" = null,
##     "mention" = null,
##     "text": "s",
##     "type": "text",
##   }],
##   "text": "s",
## }
@export var message: Dictionary
@export var message_type: String
@export var reply = null
@export var source_badges = null
@export var source_broadcaster_user_id = null
@export var source_broadcaster_user_login = null
@export var source_broadcaster_user_name = null
@export var source_message_id = null

@export_group('sending only')
## If the message passed all checks and was sent.
@export var is_sent: bool
## The reason the message was dropped, if any.
## {
##   "code": "Code for why the message was dropped.",
##   "message": "Message for why the message was dropped.",
## }
@export var drop_reason: Dictionary

var raw_text: String:
	get():
		return message.text

var is_broadcaster: bool:
	get(): return has_badge('broadcaster')
var is_moderator: bool:
	get(): return has_badge('moderator')
var is_subscriber: bool:
	get(): return has_badge('subscriber')


func _init(json: Dictionary):
	## key: String -> local variable name
	## value: Array[String] -> possible json keys that match the local information
	const mapping = {
		# 'display_name': ['chatter_user_name'],
	}
	for entry in self.get_property_list():
		var keys = mapping.get(entry.name, [entry.name])
		for key in keys:
			if !json.has(key): continue
			var value = json.get(key)
			if value == null: continue
			self[entry.name] = value


func has_badge(set_id: String) -> bool:
	return -1 != badges.find_custom(func(badge):
		return badge.set_id == set_id)
