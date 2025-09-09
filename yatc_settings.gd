class_name YatcSettings
extends RefCounted

const ROOT = 'yatc'
static var CONFIG:= {
	'client_id': {
		'category': 'config',
		'basic': true,
		'default': '',
		'type': TYPE_STRING,
		'hint': PROPERTY_HINT_PLACEHOLDER_TEXT,
		'hint_string': 'e.g.: a3ds1d4ccndv3mx7nui0ssdf42wld',
	},
	'scope': {
		'category': 'config',
		'basic': true,
		'default': [
			'user:read:chat',
			'user:write:chat',
			'channel:read:redemptions',
			'channel:read:ads',
			'channel:manage:redemptions',
			'moderator:manage:announcements',
			],
		'type': TYPE_ARRAY,
		'hint': PROPERTY_HINT_ARRAY_TYPE,
		'hint_string': '%d/%d:%s' % [TYPE_STRING, PROPERTY_HINT_PLACEHOLDER_TEXT, 'e.g.: user:read:chat'],
	},
}


static func _get_key(name: String) -> String:
	return '%s/%s/%s' % [
		ROOT,
		CONFIG[name].category,
		name]


static func setup_settings() -> void:
	for name: String in CONFIG.keys():
		var config = CONFIG[name]
		var key = _get_key(name)
		ProjectSettings.set_setting(key, _get_config(name))
		ProjectSettings.set_initial_value(key, config.default)
		ProjectSettings.set_as_basic(key, config.basic)
		ProjectSettings.add_property_info({
			"name": key,
			"type": config.type,
			"hint": config.hint,
			"hint_string": config.hint_string,
		})


static func _get_config(name: String) -> Variant:
	var key = _get_key(name)
	if ProjectSettings.has_setting(key):
		return ProjectSettings.get_setting_with_override(key)
	else:
		return CONFIG[name].default


static var client_id: String:
	get(): return _get_config('client_id')


static var scope: Array:
	get(): return _get_config('scope')
