extends Resource
class_name YatcAdSchedule

## The number of snoozes available for the broadcaster.
@export var snooze_count: int
## The UTC timestamp when the broadcaster will gain an additional snooze, in RFC3339 format.
@export var snooze_refresh_at: float
## The UTC timestamp of the broadcaster’s next scheduled ad, in RFC3339 format. Empty if the channel has no ad scheduled or is not live.
@export var next_ad_at: float
## The length in seconds of the scheduled upcoming ad break.
@export var duration: int
## The UTC timestamp of the broadcaster’s last ad-break, in RFC3339 format. Empty if the channel has not run an ad or is not live.
@export var last_ad_at: float
## The amount of pre-roll free time remaining for the channel in seconds. Returns 0 if they are currently not pre-roll free.
@export var preroll_free_time: int


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
