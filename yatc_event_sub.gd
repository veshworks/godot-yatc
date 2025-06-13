extends Node
class_name YatcEventSub

signal chat_message_received(message: YatcChatMessage)
signal channel_points_reward_redeemed(reward: YatcPointsRedeemedReward)
signal ad_break_begin(ad: YatcAdBreak)
signal subscription_revoked(reason: String)
signal stream_status(is_online: bool)

const URL_TWITCH_EVENT_SUB = 'wss://eventsub.wss.twitch.tv/ws'
const URL_TWITCH_SUBSCRIPTIONS = 'https://api.twitch.tv/helix/eventsub/subscriptions'

var socket:= WebSocketPeer.new()

var session_id: String
var connected_at: String

var keepalive_timeout_seconds: int
var keepalive_timer: Timer


func _init() -> void:
	self.name = 'YatcEventSub'


func _ready():
	socket.connect_to_url(URL_TWITCH_EVENT_SUB)
	keepalive_timer = Timer.new()
	keepalive_timer.name = 'keepalive_timer'
	self.add_child(keepalive_timer)
	keepalive_timer.timeout.connect(_on_keepalive_timer_timeout)

func _process(_delta: float) -> void:
	socket.poll()
	var state = socket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			while socket.get_available_packet_count():
				var data = socket.get_packet()
				var json = JSON.parse_string(data.get_string_from_utf8())
				Logger.scope('Yatc').debug("Packet type %s received" % json['metadata']['message_type'])
				match json['metadata']['message_type']:
					'session_welcome':
						setup_subscriptions(json)
					'session_keepalive':
						keep_session_alive(json)
					'session_reconnect':
						reconnect(json)
					'notification':
						handle_notification(json)
					'revocation':
						revoke_subscription(json)
					_:
						Logger.scope('Yatc').info("Unhandled Packet: " + JSON.stringify(json, '  '))
		WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			Logger.scope('Yatc').info("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			set_process(false) # Stop processing.


# {
# 	"metadata": {
# 		"message_id": "6WGeiue34GgzoIVxEbmLXD9lYJH0XLaUoUho0C-R_T8=",
# 		"message_timestamp": "2025-02-15T04:50:06.31917311Z",
# 		"message_type": "notification",
# 		"subscription_type": "channel.chat.message",
# 		"subscription_version": "1"
# 	},
# 	"payload": {
# 		"event": {
# 			"badges": [
# 				{
# 					"id": "1",
# 					"info": "",
# 					"set_id": "broadcaster"
# 				}
# 			],
# 			"broadcaster_user_id": "158012270",
# 			"broadcaster_user_login": "vhoyer",
# 			"broadcaster_user_name": "vhoyer",
# 			"channel_points_animation_id": null,
# 			"channel_points_custom_reward_id": null,
# 			"chatter_user_id": "158012270",
# 			"chatter_user_login": "vhoyer",
# 			"chatter_user_name": "vhoyer",
# 			"cheer": null,
# 			"color": "#FF7F50",
# 			"message": {
# 				"fragments": [
# 					{
# 						"cheermote": null,
# 						"emote": null,
# 						"mention": null,
# 						"text": "s",
# 						"type": "text"
# 					}
# 				],
# 				"text": "s"
# 			},
# 			"message_id": "1bc66cfd-dace-4315-b3ed-e418937a4f20",
# 			"message_type": "text",
# 			"reply": null,
# 			"source_badges": null,
# 			"source_broadcaster_user_id": null,
# 			"source_broadcaster_user_login": null,
# 			"source_broadcaster_user_name": null,
# 			"source_message_id": null
# 		},
# 		"subscription": {
# 			"condition": {
# 				"broadcaster_user_id": "158012270",
# 				"user_id": "158012270"
# 			},
# 			"cost": 0,
# 			"created_at": "2025-02-15T04:49:59.339284652Z",
# 			"id": "6cc77a00-38f6-4017-8dd8-92904e1a51a8",
# 			"status": "enabled",
# 			"transport": {
# 				"method": "websocket",
# 				"session_id": "AgoQa4YCgJPkSXqTM5Hngr0z-RIGY2VsbC1i"
# 			},
# 			"type": "channel.chat.message",
# 			"version": "1"
# 		}
# 	}
# }
func handle_notification(packet: Dictionary) -> void:
	match packet['metadata']['subscription_type']:
		'channel.chat.message':
			chat_message_received.emit(YatcChatMessage.new(packet['payload']['event']))
		'channel.channel_points_custom_reward_redemption.add':
			Logger.scope('Yatc').debug('reward added: %s' % JSON.stringify(packet['payload']['event']))
			channel_points_reward_redeemed.emit(YatcPointsRedeemedReward.new(packet['payload']['event']))
		'channel.ad_break.begin':
			ad_break_begin.emit(YatcAdBreak.new(packet['payload']['event']))
		'stream.online':
			stream_status.emit(true)
		'stream.offline':
			stream_status.emit(false)
		_:
			Logger.scope('Yatc').info("Unhandled subscription_type on notification: " + JSON.stringify(packet, '  '))


# {
#   "metadata":{"message_id":"9b34b242-9ee0-4665-b498-7724cca79773","message_type":"session_welcome","message_timestamp":"2025-02-15T03:17:37.732785836Z"},
#   "payload":{"session":{"id":"AgoQTeZwdw_hSKeJk8RlD5wB5RIGY2VsbC1i","status":"connected","connected_at":"2025-02-15T03:17:37.72563402Z","keepalive_timeout_seconds":10,"reconnect_url":null,"recovery_url":null}}
# }
func setup_subscriptions(packet: Dictionary) -> void:
	session_id = packet['payload']['session']['id']
	connected_at = packet['payload']['session']['connected_at']
	keepalive_timeout_seconds = 2 * packet['payload']['session']['keepalive_timeout_seconds']
	keepalive_timer.start(keepalive_timeout_seconds)

	request_sub('channel.chat.message', '1', {
		'broadcaster_user_id': str(Yatc.singleton.user.id),
		'user_id': str(Yatc.singleton.user.id),
	})

	request_sub('channel.channel_points_custom_reward_redemption.add', '1', {
		'broadcaster_user_id': str(Yatc.singleton.user.id),
	})

	request_sub('channel.ad_break.begin', '1', {
		'broadcaster_user_id': str(Yatc.singleton.user.id),
	})

	request_sub('stream.online', '1', {
		'broadcaster_user_id': str(Yatc.singleton.user.id),
	})

	request_sub('stream.offline', '1', {
		'broadcaster_user_id': str(Yatc.singleton.user.id),
	})

func request_sub(type: String, version: String, condition: Dictionary) -> void:
	var http = HTTPRequest.new()
	self.add_child(http)

	http.request(
		URL_TWITCH_SUBSCRIPTIONS,
		[
			'Authorization: Bearer %s' % Yatc.singleton.user.token,
			'Client-Id: %s' % Yatc.singleton.client_id,
			'Content-Type: application/json'
		],
		HTTPClient.METHOD_POST,
		JSON.stringify({
			'type': type,
			'version': version,
			'condition': condition,
			'transport': {
				'method': 'websocket',
				'session_id': session_id,
				'connected_at': connected_at,
			},
		}))

	await http.request_completed
	http.queue_free()

# {
#   "metadata":{"message_id":"2210385f-0acf-461d-8d42-59c6c957a6b1","message_type":"session_keepalive","message_timestamp":"2025-02-15T04:20:04.125529953Z"},
#   "payload":{}
# }
func keep_session_alive(_packet: Dictionary) -> void:
	keepalive_timer.start(keepalive_timeout_seconds)
	pass


# {
# 	"metadata": {
# 		"message_id": "84c1e79a-2a4b-4c13-ba0b-4312293e9308",
# 		"message_type": "session_reconnect",
# 		"message_timestamp": "2022-11-18T09:10:11.634234626Z"
# 	},
# 	"payload": {
# 		"session": {
# 			"id": "AQoQexAWVYKSTIu4ec_2VAxyuhAB",
# 			"status": "reconnecting",
# 			"keepalive_timeout_seconds": null,
# 			"reconnect_url": "wss://eventsub.wss.twitch.tv?...",
# 			"connected_at": "2022-11-16T10:11:12.634234626Z"
# 		}
# 	}
# }
func reconnect(packet: Dictionary) -> void:
	socket.connect_to_url(packet['payload']['session']['reconnect_url'])
	pass


# {
# 	"metadata": {
# 		"message_id": "84c1e79a-2a4b-4c13-ba0b-4312293e9308",
# 		"message_type": "revocation",
# 		"message_timestamp": "2022-11-16T10:11:12.464757833Z",
# 		"subscription_type": "channel.follow",
# 		"subscription_version": "1"
# 	},
# 	"payload": {
# 		"subscription": {
# 			"id": "f1c2a387-161a-49f9-a165-0f21d7a4e1c4",
# 			"status": "authorization_revoked",
# 			"type": "channel.follow",
# 			"version": "1",
# 			"cost": 1,
# 			"condition": {
# 				"broadcaster_user_id": "12826"
# 			},
# 			"transport": {
# 				"method": "websocket",
# 				"session_id": "AQoQexAWVYKSTIu4ec_2VAxyuhAB"
# 			},
# 			"created_at": "2022-11-16T10:11:12.464757833Z"
# 		}
# 	}
# }
func revoke_subscription(packet: Dictionary) -> void:
	subscription_revoked.emit(packet['payload']['subscription']['status'])
	Logger.scope('Yatc').error("Subscription revoked: " + JSON.stringify(packet, '  '))
	pass


func _on_keepalive_timer_timeout() -> void:
	socket.close(1000, "keepalive timeout")
	socket.connect_to_url(URL_TWITCH_EVENT_SUB)
	pass
