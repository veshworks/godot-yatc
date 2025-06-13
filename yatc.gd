extends Node
# class_name Yatc

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

signal signed_in(channel: YatcChannel)
signal signed_out()

signal chat_message_received(message: YatcChatMessage)
signal channel_points_reward_redeemed(reward: YatcPointsRedeemedReward)
signal ad_break_begin(ad: YatcAdBreak)
signal stream_status(is_online: bool)

var timer_revalidation: Timer

var token: String
var user: YatcChannel:
	set(value):
		user = value
		if user.is_valid():
			signed_in.emit(user)
		else:
			signed_out.emit()
var api: YatcAPI
var event_sub: YatcEventSub
var polling: YatcPolling

var logger: Logger = Logger.scope('Yatc')

enum Status {
	signed_off,
	local_token_retrieved,
	local_token_invalidated,
	awaiting_user_authorization,
	token_acquired,
	error,
	ok,
}

var status: Status = Status.signed_off

func _ready() -> void:
	signed_in.connect(_on_sign_in)
	signed_out.connect(_on_sign_out)

	timer_revalidation = Timer.new()
	timer_revalidation.name = 'timer_revalidation'
	self.add_child(timer_revalidation)
	timer_revalidation.wait_time = 360 # 1 hour
	timer_revalidation.timeout.connect(revalidate_user)

	api = YatcAPI.new()
	self.add_child(api)

	polling = YatcPolling.new()
	self.add_child(polling)


func load_token() -> void:
	var loaded: YatcChannel = YatcChannel.load(username)
	status = Status.local_token_retrieved

	if not Set.new(loaded.scope).has_all(scope):
		status = Status.local_token_invalidated
		return

	var is_valid = await validate_user(loaded.token)
	status = Status.ok if is_valid else Status.local_token_invalidated


func sign_in() -> void:
	await load_token()
	if status == Status.ok:
		return

	status = Status.awaiting_user_authorization

	var server = YatcAuthServer.new()
	self.add_child(server)

	YatcAuthServer.open_auth_url(client_id, scope)

	server.token_received.connect(func(_token):
		var valid = await validate_user(_token)
		if valid:
			status = Status.ok
		else:
			status = Status.error
		self.remove_child(server)
		server.queue_free()
	)


func sign_out() -> void:
	user = YatcChannel.new()
	status = Status.signed_off


func get_status() -> String:
	return Status.find_key(status)


func is_signed_in() -> bool:
	return user.is_valid()


func validate_user(tkn: String) -> bool:
	token = tkn
	var _user = await api.validate(token)
	if not _user.is_valid(): return false

	if persist:
		_user.scope = scope
		_user.save()
	self.user = _user
	return true


func revalidate_user() -> void:
	user = await api.validate(token)


func _on_sign_in(_user: YatcChannel) -> void:
	event_sub = YatcEventSub.new()
	event_sub.chat_message_received.connect(chat_message_received.emit)
	event_sub.channel_points_reward_redeemed.connect(channel_points_reward_redeemed.emit)
	event_sub.ad_break_begin.connect(ad_break_begin.emit)
	event_sub.stream_status.connect(stream_status.emit)
	event_sub.subscription_revoked.connect(sign_out)
	self.add_child(event_sub)

	(func(): user.custom_rewards = await api.get_custom_reward()).call()
	(func(): user.manageable_rewards = await api.get_custom_reward(true)).call()

	var refresh_ad_schedule = func():
		logger.info('ad_schedule refreshing')
		user.ad_schedule = await api.get_ad_schedule()
		logger.info('ad_schedule refreshed')
	refresh_ad_schedule.call()
	polling.add_callback(refresh_ad_schedule)


func _on_sign_out() -> void:
	self.remove_child(event_sub)
	event_sub.queue_free()
	event_sub = null


func get_module_path() -> String:
	return get_script().get_path().get_base_dir()
