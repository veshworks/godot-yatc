extends Resource
class_name YatcPointsRedeemedReward

@export var user_id: String = "9001"
@export var user_login: String = "cooler_user"
@export var user_name: String = "Cooler_User"
@export var user_input: String = "pogchamp"

@export_enum("unfulfilled", "cancelled", "fulfilled")
var status: String = "unfulfilled"

@export var reward_id: String = "92af127c-7326-4483-a52b-b0da0be61c01"
@export var reward_title: String = "title"
@export var reward_cost: int = 100
@export var reward_prompt: String = "reward prompt"

@export var redeemed_at: String = "2020-07-15T17:16:03.17106713Z"

func _init(json: Dictionary):
	user_id = json['user_id']
	user_login = json['user_login']
	user_name = json['user_name']
	user_input = json['user_input']
	status = json['status']

	reward_id = json['reward']['id']
	reward_title = json['reward']['title']
	reward_cost = json['reward']['cost']
	reward_prompt = json['reward']['prompt']

	redeemed_at = json['redeemed_at']
