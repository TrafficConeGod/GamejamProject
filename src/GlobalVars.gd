extends Node

var checkpoint_id := 0
var level_id := 0
var level_data := LevelData.new()
var score := 0
var is_editor_mode = false
var is_title_screen = false
var picking_ability = false
var just_started = false

# RECHARGE POINTS
var ability_recharge_time : float = 50000

# Internal
var ability_recharge_ct : float = 0
var pre_death_ability_recharge_ct : float = 0

var ability_id := 0
#id 0 stopwatch
#id 1 bombs (unused and broken)
#id 2 potion
#id 3 lightning
#id 4 its 3 am but im still working on this 

var is_slow := false # THIS IS NOW THE PARAM FOR ALL ABILITIES
var slow_time : float = 5
var slow_time_1 : float = 5
var slow_time_2 : float = 10
var slow_ticker : float = 0

var credits_from_title = false

var scene_cache = []

func _ready():
	var id_mapper = load("res://actors/obstacles/ids.tres")
	for id in id_mapper.ids:
		var object_resource = load("res://actors/obstacles/" + id + ".tres")
		var object_scene = load(object_resource.scene_path)
		scene_cache.append(object_scene)
		
	pause_mode = PAUSE_MODE_PROCESS
	# DEBUG
	# ability_recharge_ct = ability_recharge_time
	# pre_death_ability_recharge_ct = ability_recharge_time

func enter_editor_mode():
	is_title_screen = false
	is_editor_mode = true
	get_tree().paused = false
	level_id = 0
	switch_level(false)
	get_tree().change_scene("res://editor.tscn")

func enter_play_mode():
	is_title_screen = false
	is_editor_mode = false
	get_tree().paused = false
	level_id = 1
	switch_level(false)
	get_tree().change_scene("res://levels/level_loader.tscn")
	
func return_to_title():
	is_title_screen = true
	ability_recharge_ct = ability_recharge_time
	pre_death_ability_recharge_ct = ability_recharge_ct
	slow_ticker = 0
	is_slow = false
	get_tree().paused = false
	get_tree().change_scene("res://levels/title_screen.tscn")
	
	
func _process(delta):
	ability_recharge_ct = clamp(ability_recharge_ct, 0, ability_recharge_time)
	if Input.is_action_just_pressed("copy_level_data"):
		if get_tree().get_current_scene().mode == 1:
			OS.clipboard = level_data.encode()
		elif get_tree().get_current_scene().mode == 0:
			var level_list = load("res://level_list.tres")
			var level_name = level_list.levels[level_id]
			var level_contents = load("res://assets/levels/" + level_name + ".tres")
			OS.clipboard = level_contents.data
		
	if Input.is_action_just_pressed("paste_level_data") and get_tree().get_current_scene().mode == 1:
		level_data.decode(OS.clipboard)
		get_tree().reload_current_scene()
		
	if Input.is_action_just_pressed("pause") and !picking_ability and get_tree().get_current_scene().mode == 0:
		UI.get_node("CanvasLayer/PauseScreen/AbilityScreen").visible = false
		UI.get_node("CanvasLayer/PauseScreen/MainScreen").visible = true
		UI.get_node("CanvasLayer/PauseScreen").visible = !get_tree().paused
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
	if Input.is_action_just_pressed("return"):
		return_to_title()
	
	if is_slow and get_tree().get_current_scene().mode == 0 and not get_tree().paused:
		slow_ticker += delta
		if slow_ticker >= slow_time:
			is_slow = false

func reset():
	checkpoint_id = 0

func switch_level(reload):
	var level_list = load("res://level_list.tres")
	if level_id < level_list.levels.size():
		var level_name = level_list.levels[level_id]
		var level_contents = load("res://assets/levels/" + level_name + ".tres")
		level_data.decode(level_contents.data)
		if reload:
			get_tree().reload_current_scene()
	else:
		return_to_title()
		GlobalVars.credits_from_title = false
		get_tree().change_scene("res://levels/credits.tscn")

func activate_ability():
	if get_tree().get_current_scene().mode == 0:
		ability_recharge_ct = 0
		slow_ticker = 0
		is_slow = true
		if ability_id == 0:
			slow_time = slow_time_1
		else:
			slow_time = slow_time_2
