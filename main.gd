extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Check to see if dash pickup has been pick up already.
	if $DashPickup/PickUp.visible == true and PlayerVariables.DashPickedUp == false:
		# Check to see if player wants to pick up the collectible.
		if Input.is_action_just_pressed("move_down"):
			# Player can now dash
			PlayerVariables.DashPickedUp = true
			# Hide the pickup dash text
			$DashPickup/PickUp.visible = false
			# Show dash tutorial text
			$DashPickup/DashTutorial.visible = true
	
	
	if PlayerVariables.shouldDie == 1: # If the player should die, reset the character position.
		$Character/KinematicBody2D.position = Vector2(0, 8.662598)
		# Reset this to zero, so we don't die infinitely forever.
		PlayerVariables.shouldDie = 0

func _on_Area2D_body_shape_entered(body_id, body, body_shape, area_shape):
	# Show dash pickup text when close.
	$DashPickup/PickUp/PickUpText.visible = true


func _on_Area2D_body_shape_exited(body_id, body, body_shape, area_shape):
	# Stop showing dash pickup text when moving away
	$DashPickup/PickUp/PickUpText.visible = false


func _on_JumpTutArea_body_entered(body):
	$"Double jump/DJTut".visible = true
