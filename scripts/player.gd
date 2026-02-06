extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const RUN_SPEED = 8.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var animation_player = $AnimationPlayer
@onready var gun_sound_player = $GunShotSound
@onready var reload_sound_player = $ReloadSound

var gunshot_sounds = []
var reload_sounds = []

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Load sounds dynamically
	for i in range(1, 4):
		var path = "res://assets/audio/gunshot_0" + str(i) + ".mp3"
		if FileAccess.file_exists(path):
			gunshot_sounds.append(load(path))
			print("Loaded " + path)

		path = "res://assets/audio/reload_0" + str(i) + ".mp3"
		if FileAccess.file_exists(path):
			reload_sounds.append(load(path))
			print("Loaded " + path)

func _physics_process(delta):
	# Add gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		play_anim("Jump")

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var current_speed = SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = RUN_SPEED

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		if is_on_floor() and not is_action_playing():
			if Input.is_key_pressed(KEY_SHIFT):
				play_anim("Run")
			else:
				play_anim("Walk")
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

		if is_on_floor() and not is_action_playing():
			play_anim("Idle")

	move_and_slide()

	# Combat Actions
	if Input.is_action_just_pressed("fire"):
		shoot()

	if Input.is_action_just_pressed("reload"):
		reload()

	# Escape to free mouse (useful for testing)
	if Input.is_key_pressed(KEY_ESCAPE):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.005)

func play_anim(anim_name):
	if not animation_player:
		return

	if animation_player.has_animation(anim_name):
		# Only switch if not already playing or to force restart specific actions
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name, 0.2)

func is_action_playing():
	if not animation_player: return false
	var cur = animation_player.current_animation
	# These animations should generally finish before walking/idling takes over
	# But we allow movement logic to run, just not animation override
	if (cur == "Shoot" or cur == "Reload" or cur == "Jump") and animation_player.is_playing():
		return true
	return false

func shoot():
	play_anim("Shoot")
	if gunshot_sounds.size() > 0 and gun_sound_player:
		gun_sound_player.stream = gunshot_sounds[randi() % gunshot_sounds.size()]
		gun_sound_player.play()

func reload():
	play_anim("Reload")
	if reload_sounds.size() > 0 and reload_sound_player:
		reload_sound_player.stream = reload_sounds[randi() % reload_sounds.size()]
		reload_sound_player.play()
