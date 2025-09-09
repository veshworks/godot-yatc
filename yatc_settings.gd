class_name YatcSettings
extends RefCounted

const CLIENT_ID:= 'yatc/config/client_id'
const SCOPE:= 'yatc/config/scope'
const SCOPE_DEFAULT: Array[String] = [
	'user:read:chat',
	'user:write:chat',
	'channel:read:redemptions',
	'channel:read:ads',
	'channel:manage:redemptions',
	'moderator:manage:announcements',
	]


static func setup_settings() -> void:
	ProjectSettings.set_setting(CLIENT_ID, '')
	ProjectSettings.set_initial_value(CLIENT_ID, '')
	ProjectSettings.set_as_basic(CLIENT_ID, true)
	ProjectSettings.add_property_info({
		"name": CLIENT_ID,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
		"hint_string": "e.g.: a3ds1d4ccndv3mx7nui0ssdf42wld"
	})

	ProjectSettings.set_setting(SCOPE, SCOPE_DEFAULT)
	ProjectSettings.set_initial_value(SCOPE, SCOPE_DEFAULT)
	ProjectSettings.set_as_basic(SCOPE, true)
	ProjectSettings.add_property_info({
		"name": SCOPE,
		"type": TYPE_ARRAY,
		"hint": PROPERTY_HINT_ARRAY_TYPE,
		"hint_string": "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, 'e.g.: user:read:chat'],
	})


static func get_config(id: String) -> Variant:
	assert(id in ['client_id', 'scope'], '[Yatc] Error: unexpected config id')
	return ProjectSettings.get_setting_with_override("yatc/config/%s" % id)
