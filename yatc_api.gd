extends Node
class_name YatcAPI


func _init() -> void:
	self.name = 'YatcAPI'


const URL_VALIDATE = 'https://id.twitch.tv/oauth2/validate'

func validate(token: String) -> YatcChannel:
	var http = HTTPRequest.new()
	self.add_child(http)

	http.request(URL_VALIDATE, [
		'Authorization: OAuth ' + token
	])

	var result = await http.request_completed
	var body = (result[3] as PackedByteArray).get_string_from_utf8()

	var status = result[1]
	match status:
		401:
			var json = JSON.parse_string(body)
			Logger.scope('Yatc').info(json['message'])
			return YatcChannel.new()
		200:
			var json = JSON.parse_string(body)
			var channel = YatcChannel.new()
			channel.id = json['user_id']
			channel.username = json['login']
			channel.expires_in = json['expires_in']
			channel.token = token

			http.queue_free()
			return channel
		_:
			assert(false, 'Error: no can connect to twitch, sorry')
			return YatcChannel.new()


const URL_GET_USERS = 'https://api.twitch.tv/helix/users'

## Gets information about one or more users.
##
## You may look up users using their user ID, login name, or both but the sum total of the number of users you may look up is 100. For example, you may specify 50 IDs and 50 names or 100 IDs or names, but you cannot specify 100 IDs and 100 names.
##
## If you don’t specify IDs or login names, the request returns information about the user in the access token if you specify a user access token.
##
## To include the user’s verified email address in the response, you must use a user access token that includes the user:read:email scope.
func get_users(usernames: Array[String]) -> Array[YatcChannel]:
	var http = HTTPRequest.new()
	self.add_child(http)

	var url = URL.new(URL_VALIDATE)
	url.query['login'] = usernames

	http.request(url.href, [
		'Authorization: Bearer %s' % Yatc.singleton.token,
		'Client-Id: %s' % Yatc.singleton.client_id,
	])

	var result = await http.request_completed
	var body = (result[3] as PackedByteArray).get_string_from_utf8()

	var status = result[1]
	match status:
		200:
			var json = JSON.parse_string(body)
			http.queue_free()
			return json['data'].map(func(user):
				var channel = YatcChannel.new()
				channel.id = user['user_id']
				channel.username = user['login']
				return channel
				)
		400, 401:
			var json = JSON.parse_string(body)
			Logger.scope('Yatc').info(json['message'])
			return []
		_:
			assert(false, 'Error: wtf? I also donno what happened')
			return []


## Gets a list of custom rewards that the specified broadcaster created.
## https://dev.twitch.tv/docs/api/reference/#get-custom-reward
func get_custom_reward(only_manageable:= false) -> Array[YatcPointsCustomReward]:
	_has_needed_scope(['channel:read:redemptions', 'channel:manage:redemptions'])

	var url = URL.new('https://api.twitch.tv/helix/channel_points/custom_rewards')
	url.query['broadcaster_id'] = Yatc.singleton.user.id
	url.query['only_manageable_rewards'] = only_manageable

	var result = await _request(url)

	match result.status:
		200:
			Logger.scope('Yatc.get_custom_reward').info('Retrieved the following:')
			Logger.scope('Yatc.get_custom_reward').info(JSON.stringify(result.to_json.call()))
			var reward_list: Array[YatcPointsCustomReward] = []

			for json in result.to_json.call('data'):
				reward_list.push_back(YatcPointsCustomReward.new(json))

			return reward_list
		400, 401, 403, 404:
			Logger.scope('Yatc.get_custom_reward').warn(result.to_json.call('message'))
			var empty = YatcPointsCustomReward.new()
			empty.title = 'No manageable rewards' if only_manageable else 'No rewards available'
			empty.id = '-1'
			return [empty]
		_:
			assert(false, 'Error: wtf? I also donno what happened')
			return []


## Updates a custom reward. The app used to create the reward is the only app that may update the reward.
## https://dev.twitch.tv/docs/api/reference/#update-custom-reward
func patch_custom_reward(reward: YatcPointsCustomReward, fields_to_update: Array[String]) -> void:
	_has_needed_scope(['channel:manage:redemptions'])

	var url = URL.new('https://api.twitch.tv/helix/channel_points/custom_rewards')
	url.query['broadcaster_id'] = Yatc.singleton.user.id
	url.query['id'] = reward.id

	var body = {}
	for field: String in fields_to_update:
		body.set(field, reward.get(field))
	var body_json = JSON.stringify(body)

	var result = await _request(url, body_json, HTTPClient.METHOD_PATCH)

	match result.status:
		200:
			Logger.scope('Yatc.patch_custom_reward').info('successfully updated custom reward')
			Logger.scope('Yatc.patch_custom_reward').info(JSON.stringify(result.to_json.call()))
		400, 401, 403, 404:
			Logger.scope('Yatc.patch_custom_reward').error(result.to_json.call('message'))
		_:
			assert(false, 'Error: wtf? I also donno what happened')


## Updates a custom reward. The app used to create the reward is the only app that may update the reward.
## https://dev.twitch.tv/docs/api/reference/#create-custom-rewards
func create_custom_reward(reward: YatcPointsCustomReward) -> void:
	_has_needed_scope(['channel:manage:redemptions'])

	var url = URL.new('https://api.twitch.tv/helix/channel_points/custom_rewards')
	url.query['broadcaster_id'] = Yatc.singleton.user.id

	var body = {}
	var allowed_props = [
		'title',
		'cost',
		'prompt',
		'is_enabled',
		'background_color',
		'is_user_input_required',
		'is_max_per_stream_enabled',
		'max_per_stream',
		'is_max_per_user_per_stream_enabled',
		'max_per_user_per_stream',
		'is_global_cooldown_enabled',
		'global_cooldown_seconds',
		'should_redemptions_skip_request_queue',
	]
	for key in allowed_props:
		body[key] = reward.get(key)
	var result = await _request(url, JSON.stringify(body))

	match result.status:
		200:
			Logger.scope('Yatc.create_custom_reward').info('successfully updated custom reward')
			Logger.scope('Yatc.create_custom_reward').info(JSON.stringify(result.to_json.call()))
		400, 401, 403, 404:
			Logger.scope('Yatc.create_custom_reward').error(result.to_json.call('message'))
		_:
			assert(false, 'Error: wtf? I also donno what happened')


## Send Chat Announcement
## https://dev.twitch.tv/docs/api/reference/#send-chat-announcement
func send_chat_announce(message: String, color: String = '') -> Error:
	_has_needed_scope(['moderator:manage:announcements'])

	var url = URL.new('https://api.twitch.tv/helix/chat/announcements')
	url.query['broadcaster_id'] = Yatc.singleton.user.id
	url.query['moderator_id'] = Yatc.singleton.user.id

	var request_body = {}
	request_body['message'] = message
	if color:
		request_body['color'] = color

	var result = await _request(url, JSON.stringify(request_body))

	match result.status:
		204:
			Logger.scope('Yatc.send_chat_announce').info('Successfully sent the announcement')
			return OK
		400:
			Logger.scope('Yatc.send_chat_message').warn('bad request')
			return ERR_INVALID_DATA
		401:
			Logger.scope('Yatc.send_chat_message').warn('unauthorized')
			return ERR_UNAUTHORIZED
		429:
			Logger.scope('Yatc.send_chat_message').warn('too many requests')
			return ERR_BUSY
		_:
			assert(false, 'Error: wtf? I also donno what happened')
			return FAILED


## Send Chat Message
## https://dev.twitch.tv/docs/api/reference/#send-chat-message
func send_chat_message(message: String, reply_parent_message_id: String = '') -> YatcChatMessage:
	_has_needed_scope(['user:write:chat'])

	var url = URL.new('https://api.twitch.tv/helix/chat/messages')

	var request_body = {}
	request_body['broadcaster_id'] = Yatc.singleton.user.id
	request_body['sender_id'] = Yatc.singleton.user.id
	request_body['message'] = message
	if reply_parent_message_id:
		request_body['reply_parent_message_id'] = reply_parent_message_id

	var result = await _request(url, JSON.stringify(request_body))

	match result.status:
		200:
			Logger.scope('Yatc.send_chat_message').info('Retrieved the following:')
			Logger.scope('Yatc.send_chat_message').info(JSON.stringify(result.to_json.call()))
			return YatcChatMessage.new(result.to_json.call('data')[0])
		400, 401, 403, 404, 422:
			Logger.scope('Yatc.send_chat_message').warn(result.to_json.call('message'))
			return null
		_:
			assert(false, 'Error: wtf? I also donno what happened')
			return null


## Get Ad Schedule
## https://dev.twitch.tv/docs/api/reference/#get-ad-schedule
func get_ad_schedule() -> YatcAdSchedule:
	_has_needed_scope(['channel:read:ads'])

	var url = URL.new('https://api.twitch.tv/helix/channels/ads')
	url.query['broadcaster_id'] = Yatc.singleton.user.id

	var result = await _request(url)

	match result.status:
		200:
			Logger.scope('Yatc.get_ad_schedule').info('Retrieved the following:')
			Logger.scope('Yatc.get_ad_schedule').info(JSON.stringify(result.to_json.call()))
			return YatcAdSchedule.new(result.to_json.call('data').front())
		400:
			Logger.scope('Yatc.get_ad_schedule').warn(result.to_json.call('message'))
			return null
		_:
			assert(false, 'Error: wtf? I also donno what happened')
			return null


func _request(url: URL, request_body: String = '', method: HTTPClient.Method = -1) -> Dictionary:
	var http = HTTPRequest.new()
	self.add_child(http)
	http.request_completed.connect(
		func(_result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
			self.remove_child(http)
			http.queue_free())

	if method == -1:
		method = HTTPClient.METHOD_POST if request_body else HTTPClient.METHOD_GET

	http.request(url.href, [
		'Authorization: Bearer %s' % Yatc.singleton.token,
		'Client-Id: %s' % Yatc.singleton.client_id,
		'Content-Type: application/json',
	], method, request_body)

	var result = await http.request_completed
	var body = (result[3] as PackedByteArray).get_string_from_utf8()

	return {
		'status': result[1],
		'body': body,
		'to_json': func(key: String = ''):
			var json = JSON.parse_string(body)
			if key:
				return json[key]
			else:
				return json,
	}


func _has_needed_scope(required_scopes: Array[String]) -> void:
	assert(Yatc.singleton.scope.any(func(scope):
		return required_scopes.has(scope)),
		'Error: to call this function you need to have one of the following scopes authorized: ' + ', '.join(required_scopes))
