extends KinematicBody2D

var GRAVITY = 9.807 # Earth gravity
export var SPEED = 550.0 # Horizontal movement speed
export var FSCALE := 5.0 # How much faster we want our character to fall compared to normal gravity.
export var LOW_JUMP_SCALE := 2.0 # This scale controls how fast the character falls after jumping.
export var JUMP_SPEED := 300.0 # How much velocity is added for jumping.

var velocity = Vector2() # Velocity. Speed with a direction. In this case, horizontal or vertical.
var a = 0 # Dummy variable to make things faster than the framerate.
var isDashing =  0 # Is the chracter current dashing? Default is no.
var beforexVelocity = 0 # Velocity before a dash
var candash = 1 # Can the character currently dash?
var animationPicker = 1 # For randomising the dash animations (though I think they're all the same???)
var moveCamDown = 0 # For looking down.
var doubleJump = 0 # Has Double Jump been exhausted?

func get_input(dt):
	a = 5 * dt # We want this to update at 5x the frame rate
	if isDashing == 0: # If we're not currently dashing
		if Input.is_action_pressed("move_left"):
			$Sprite.flip_h = true # Flip sprite to face the correct direction
			if velocity.y == 0: # If we're not falling or jumping
				$Sprite.play("Walk") # Play the walking animation
			velocity.x -= a * SPEED # Set speed, with a psuedo-acceleration set by a
			if abs(velocity.x) >= SPEED:
				velocity.x = -SPEED # Set maximum speed.
			
		elif Input.is_action_just_released("move_left"): # When we want to stop moving
			velocity.x = 0 # Set x-velocity to 0
			if velocity.x == 0 and velocity.y == 0:
				$Sprite.play("Idle") # If not falling, jumping, or walking, set idle animation.
		
		if Input.is_action_pressed("move_right"): # Same thing, but for the other x-direction.
			$Sprite.flip_h = false
			if velocity.y == 0:
				$Sprite.play("Walk")
			velocity.x += a * SPEED
			if velocity.x >= SPEED:
				velocity.x = SPEED
			
		elif Input.is_action_just_released("move_right"):
			velocity.x = 0
			if velocity.x == 0 and velocity.y == 0:
				$Sprite.play("Idle")
		if velocity.x == 0 and velocity.y == 0:
				$Sprite.play("Idle")
		
		# Here we want to dash. When dash button is pressed, we check to see if we can dash, and whether we have the dash pickup.
		if Input.is_action_just_pressed("dash") and candash == 1 and PlayerVariables.DashPickedUp == true:
			candash = 0 # No infinite dashing!
			velocity.y = 0.001 # A little bit of y-velocity to prevent idle animations from triggering.
			GRAVITY = 0 # No falling while we dash.
			isDashing =  1 # Yes, we are dashing.
			animationPicker = randi() % 3 + 1 # Decide wish dash animation to use (I think they're all the same???)
			$Sprite.play("Dash" + str(animationPicker)) # Play the chosen animation
			beforexVelocity = velocity.x # Set before x velocity, so we can have nice smooth transitions.
			$DuringDashTimer.start() # Start the during dash timer, which will set dash properties for the duration.
			$DashTimer.start() # Start the dash timer, which will reset canDash when it expires.
			if $Sprite.flip_h == true: # Set dash speed depending on which direction sprite is (so we can dash from idle)
				velocity.x -= 1.5 * SPEED
			else:
				velocity.x += 1.5 * SPEED
		
		if Input.is_action_just_pressed("move_down"): # We want to look down!
			$LookTimer.start() # It takes a while to look down, since we don't want to look down every single time we tap down.
		elif Input.is_action_just_released("move_down"): # Stop the timer if we let go of down.
			$LookTimer.stop()
			moveCamDown = -1 # Will trigger function to bring camera back up.
			

func _process(delta):
	# Really should change this to a function.
	if moveCamDown == 1 and $Camera2D.position.y != 300: 
		$Camera2D.position.y = lerp($Camera2D.position.y, 300, 0.02) # Interpolate between current value and wanted value, then change the position. Makes a nice, smooth transition.
	elif moveCamDown == -1 and $Camera2D.position.y != 0: 
		$Camera2D.position.y = lerp($Camera2D.position.y, 0, 0.02)
	

func _physics_process(delta):
	get_input(delta)
	velocity.y += GRAVITY * FSCALE # Apply gravity
	
	if velocity.y > 0:
		velocity += Vector2.UP * (-GRAVITY) * FSCALE # This makes me accelerate FSCALE faster than gravity would typically dictate.
		if velocity.y < 1.5 * (-GRAVITY) * FSCALE:
			velocity.y = 1.5 * (-GRAVITY) * FSCALE # This caps downward velocity at 2 * FSCALE * GRAVITY
	elif velocity.y < 0 && Input.is_action_just_released("jump"):
		velocity += Vector2.UP * (-GRAVITY) * LOW_JUMP_SCALE # This is falling after a jump. You'll notice that falling after a jump is faster than falling normally. This is because we want the player to have more control over their movement.
		if velocity.y < 2 * (-GRAVITY) * LOW_JUMP_SCALE:
			velocity.y = 2 * (-GRAVITY) * LOW_JUMP_SCALE # Still capped at 2 * FSCALE * GRAVITY, though.
	
	if is_on_floor():
		doubleJump = 0
		if Input.is_action_just_pressed("jump"):
			$Sprite.play("Jump") # Switch to jump sprite (with horizontal direction set by movement branches above)
			velocity += Vector2.UP * JUMP_SPEED # How fast we jump
			
	if !is_on_floor() and Input.is_action_just_pressed("jump") and doubleJump == 0:
		doubleJump = 1
		$Sprite.play("Jump") # Switch to jump sprite (with horizontal direction set by movement branches above)
		velocity.y = 0
		velocity += Vector2.UP * JUMP_SPEED # How fast we jump
	
	
	velocity = move_and_slide(velocity, Vector2(0, -1)) # Tell godot to move our character, and allow movement along other collision boxes.


func _on_Sprite_animation_finished():
	# This function is entirely to stop the sprite animation from looping.
	if  $Sprite.animation == "Jump":
		$Sprite.stop()
		$Sprite.frame = 7 # This stops the weird jittering I see at the end of the animation for some reason.

func _on_DuringDashTimer_timeout():
	# When the dash timer runs out, we reset our velocity, and our gravity, and set isDashing to 0.
	isDashing =  0
	velocity.x = 0
	velocity.y = 0.001
	GRAVITY = 9.807
	$Sprite.play("Jump")
	$Sprite.stop()
	$Sprite.frame = 7 # After dash, set frame to last frame of jump so if we're falling, it looks right.


func _on_DashTimer_timeout():
	candash = 1 # We don't want people to be able to dash all the time, so we have this timer.


func _on_LookTimer_timeout():
	moveCamDown = 1 # Start moving the camera down.
