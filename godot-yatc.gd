@tool
extends EditorPlugin


const autoload_singletons = [
	['Yatc', "res://addons/godot-yatc/yatc.gd"],
]

# name, base class, path, icon
const custom_types = [
# [
# 	'GlobalBGMRemote',
# 	'AudioStreamPlayer',
# 	"res://addons/godot-devkit/Audio/global_bgm_remote.gd",
# ],
]


@export var client_id: String
@export var username: String
@export var scope: Array[String] = [
	'user:read:chat',
	'user:write:chat',
	'channel:read:redemptions',
	'channel:read:ads',
	'moderator:manage:announcements',
	]
@export var persist: bool = true


func _enable_plugin() -> void:
	for autoload in autoload_singletons:
		add_autoload_singleton.call(autoload[0], autoload[1])

	for custom_type in custom_types:
		add_custom_type.callv(custom_type)

	ProjectSettings.add_property_info({
		"name": "yatc/client_id",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
		"hint_string": "t84x861v4hnvv3mxq7nui0u30r8w1p"
	})


func _disable_plugin():
	for autoload in autoload_singletons:
		remove_autoload_singleton(autoload[0])

	for custom_type in custom_types:
		remove_custom_type(custom_type[0])
