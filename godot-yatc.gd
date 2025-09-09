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


func _enable_plugin() -> void:
	for autoload in autoload_singletons:
		add_autoload_singleton.call(autoload[0], autoload[1])

	for custom_type in custom_types:
		add_custom_type.callv(custom_type)

	YatcSettings.setup_settings()

func _disable_plugin():
	for autoload in autoload_singletons:
		remove_autoload_singleton(autoload[0])

	for custom_type in custom_types:
		remove_custom_type(custom_type[0])


func _enter_tree() -> void:
	YatcSettings.setup_settings()
