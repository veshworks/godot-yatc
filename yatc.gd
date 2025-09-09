extends Node
# class_name Yatc

const BASEPATH = 'user://yatc'

var client_id: String:
	get():
		return YatcSettings.client_id
var scope: Array[String]:
	get():
		return YatcSettings.scope

signal signed_in(channel: YatcChannel)
signal signed_out()

signal chat_message_received(message: YatcChatMessage)
signal channel_points_reward_redeemed(reward: YatcPointsRedeemedReward)
signal ad_break_begin(ad: YatcAdBreak)
signal stream_status(is_online: bool)

var username: String
var broadcaster: String

var timer_revalidation: Timer

var token: String
var user: YatcChannel:
	set(value):
		user = value
		if user.is_valid():
			signed_in.emit(user)
		else:
			signed_out.emit()

var broadcaster_channel: YatcChannel

var api: YatcAPI
var event_sub: YatcEventSub
var polling: YatcPolling

const YATC:= 'Yatc'

var logger: Logger = Logger.scope(YATC)

var status:= StatusReporter.new()


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
	status.report(YATC, 'local_token_retrieved')

	if not Set.new(loaded.scope).has_all(scope):
		status.report(YATC, 'local_token_invalidated')
		return

	var is_valid = await validate_user(loaded.token)
	status.report(YATC, 'ok' if is_valid else 'local_token_invalidated')


func sign_in(username: String, broadcaster: String) -> void:
	self.username = username
	self.broadcaster = broadcaster
	await load_token()
	if status.get_status(YATC) == 'ok':
		return

	status.report(YATC, 'awaiting_user_authorization')

	var server = YatcAuthServer.new()
	self.add_child(server)

	YatcAuthServer.open_auth_url(client_id, scope)

	server.token_received.connect(func(_token):
		var valid = await validate_user(_token)
		if valid:
			status.report(YATC, 'ok')
		else:
			status.report(YATC, 'error')
		self.remove_child(server)
		server.queue_free()
	)


func sign_out() -> void:
	user = YatcChannel.new()
	status.report(YATC, 'signed_off')


func is_signed_in() -> bool:
	return user.is_valid()


func validate_user(tkn: String) -> bool:
	token = tkn
	var _user = await api.validate(token)
	if not _user.is_valid(): return false

	var query = await api.get_users([broadcaster])
	if query.size() > 0:
		broadcaster_channel = query.front()
		broadcaster_channel.download_profile_image(self)

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

	if scope_allows(['channel:read:redemptions', 'channel:manage:redemptions']):
		_status_report_async('custom_rewards', func(): user.custom_rewards = await api.get_custom_reward())
		_status_report_async('manageable_rewards', func(): user.manageable_rewards = await api.get_custom_reward(true))

	var refresh_ad_schedule = _status_report_async.bind(
		'ad_schedule',
		func(): user.ad_schedule = await api.get_ad_schedule(),
		)

	if scope_allows(['channel:read:ads']):
		refresh_ad_schedule.call()
		polling.add_callback(refresh_ad_schedule)


func _status_report_async(sub_id: String, async_callback: Callable) -> void:
	logger.info('%s loading' % sub_id)
	status.report('%s.%s' % [YATC, sub_id], 'loading')
	await async_callback.call()
	logger.info('%s loaded' % sub_id)
	status.report('%s.%s' % [YATC, sub_id], 'ok')


func _on_sign_out() -> void:
	self.remove_child(event_sub)
	polling.clear_callbacks()
	event_sub.queue_free()
	event_sub = null


func scope_allows(required_scopes_or: Array) -> bool:
	return required_scopes_or.any(func(required_scope: String) -> bool:
		return scope.has(required_scope))


func get_module_path() -> String:
	return get_script().get_path().get_base_dir()
