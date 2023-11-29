extends CharacterBody2D

@export var img_jump := CompressedTexture2D.new()
@export var img_walk := CompressedTexture2D.new()
@export var img_sit := CompressedTexture2D.new()
@export var img_stand := CompressedTexture2D.new()

enum actions { JUMP, WALK, SIT, STAND}

var player_sprite_size = 90

var speed = 300.0
var jump_speed = -400.0

# Get the gravity from the project settings so you can sync with rigid body nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var was_last_right = true
var is_jumping = false
var last_action = actions.SIT

var images: Dictionary
var sitting_hitbox_x = 0

var jump_floor_detection_cooldown = 0
var frame_cooldown = 5

func _ready():
	images = {
		actions.JUMP: img_jump,
		actions.WALK: img_walk,
		actions.SIT: img_sit,
		actions.STAND: img_stand
	}

func _physics_process(delta):
	# Get the input direction.
	var direction = Input.get_axis("left", "right") #-1 if left, 1 if right
	var is_curr_right = direction > 0
	var is_curr_left = direction < 0

	velocity.y += gravity * delta
	
	if is_jumping:
		jump_floor_detection_cooldown += 1

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			jump(is_curr_left)
		elif is_jumping and jump_floor_detection_cooldown > frame_cooldown:
			jump_floor_detection_cooldown = 0
			is_jumping = false


	#Turning
	if (was_last_right and is_curr_left) or (not was_last_right and is_curr_right):
		turn(is_curr_left)
	
	if direction != 0:
		walk(is_curr_left)
		was_last_right = is_curr_right
	else:
		sit(is_curr_left)

	velocity.x = direction * speed

	var has_collided = move_and_slide()


func jump(is_left):
	velocity.y = jump_speed
	is_jumping = true
	$Sprite2D.texture = images[actions.JUMP]
	$CollisionShape2D.position.x = player_sprite_size / 2
	$CollisionShape2D.rotation_degrees = 0
	$CollisionShape2D.scale = Vector2(1, 1)
	last_action = actions.JUMP


func turn(is_turning):
	var hitbox_displacement_x = (1 if is_turning else -1) * player_sprite_size
	$Sprite2D.set_flip_h(is_turning)
	if last_action == actions.SIT:
		$CollisionShape2D.position.x += hitbox_displacement_x
	sitting_hitbox_x += hitbox_displacement_x

func walk(is_left):
	if not is_jumping and last_action != actions.WALK:
		$Sprite2D.texture = images[actions.WALK]
		$CollisionShape2D.rotation_degrees = 90
		$CollisionShape2D.scale = Vector2(1, 1.3)
		$CollisionShape2D.position.x = 0 if is_left else player_sprite_size
		last_action = actions.WALK
		
func sit(is_left):
	if not is_jumping and last_action != actions.SIT:
		$Sprite2D.texture = images[actions.SIT]
		$CollisionShape2D.rotation_degrees = 0
		$CollisionShape2D.scale = Vector2(1, 1)
		$CollisionShape2D.position.x = sitting_hitbox_x
		last_action = actions.SIT
