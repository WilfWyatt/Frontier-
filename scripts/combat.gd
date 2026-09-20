class_name FrontierCombat
extends Node2D

## FRONTIER side-scrolling arcade combat.
## The combat layer is deliberately independent from the terminal UI.

signal combat_won(reward_credits: int, reward_components: int)
signal combat_lost
signal combat_broken_off

const VIEW_SIZE: Vector2 = Vector2(1232.0, 540.0)
const PLAY_RECT: Rect2 = Rect2(18.0, 68.0, 1196.0, 405.0)
const PLAYER_START: Vector2 = Vector2(190.0, 275.0)
const PLAYER_SPEED: float = 330.0
const PLAYER_ACCEL: float = 1450.0
const PLAYER_DECEL: float = 1750.0
const BULLET_SPEED: float = 720.0
const ENEMY_BULLET_SPEED: float = 410.0
const SCROLL_SPEED: float = 105.0
const PRIMARY_COOLDOWN: float = 0.16
const MISSILE_COOLDOWN: float = 3.2

var contract_kind: String = "pirate"
var player_hull: int = 100
var player_max_hull: int = 100
var enemy_remaining: int = 6
var enemy_spawn_timer: float = 0.0
var primary_timer: float = 0.0
var missile_timer: float = 0.0
var elapsed: float = 0.0
var scroll_distance: float = 0.0
var player_velocity: Vector2 = Vector2.ZERO
var player_position: Vector2 = PLAYER_START
var fire_held: bool = false
var joystick_touch: int = -1
var fire_touch: int = -1
var joystick_vector: Vector2 = Vector2.ZERO
var stars: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var enemy_bullets: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var asteroids: Array[Dictionary] = []
var civilian: Dictionary = {}
var civilian_alive: bool = true
var victory_started: bool = false

var player_texture: Texture2D
var pirate_texture: Texture2D
var fighter_texture: Texture2D
var asteroid_texture: Texture2D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process_input(true)
    player_texture = load("res://assets/frontier_player.svg") as Texture2D
    pirate_texture = load("res://assets/frontier_pirate.svg") as Texture2D
    fighter_texture = load("res://assets/frontier_fighter.svg") as Texture2D
    asteroid_texture = load("res://assets/frontier_asteroid.svg") as Texture2D
    _create_stars()
    _create_asteroids()
    _setup_contract()
    queue_redraw()

func _setup_contract() -> void:
    if contract_kind == "pirate":
        enemy_remaining = 7
    elif contract_kind == "escort":
        enemy_remaining = 5
        civilian = {"position": Vector2(620.0, 210.0), "velocity": Vector2(70.0, 0.0), "hull": 100, "max_hull": 100}
    elif contract_kind == "signal":
        enemy_remaining = 4
    else:
        enemy_remaining = 5

func _create_stars() -> void:
    stars.clear()
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = 4017
    for i: int in range(90):
        stars.append({
            "position": Vector2(rng.randf_range(0.0, VIEW_SIZE.x), rng.randf_range(70.0, 472.0)),
            "speed": rng.randf_range(18.0, 120.0),
            "size": rng.randf_range(1.0, 2.7),
            "layer": rng.randi_range(0, 2)
        })

func _create_asteroids() -> void:
    asteroids.clear()
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = 9001
    for i: int in range(10):
        asteroids.append({
            "position": Vector2(rng.randf_range(760.0, 1500.0), rng.randf_range(100.0, 450.0)),
            "speed": rng.randf_range(55.0, 145.0),
            "size": rng.randf_range(0.55, 1.15),
            "spin": rng.randf_range(-1.0, 1.0),
            "angle": rng.randf_range(0.0, TAU)
        })

func _process(delta: float) -> void:
    elapsed += delta
    if victory_started:
        queue_redraw()
        return
    _process_input(delta)
    _process_world(delta)
    _process_player(delta)
    _process_weapons(delta)
    _process_enemies(delta)
    _process_projectiles(delta)
    _check_end_conditions()
    queue_redraw()

func _process_input(delta: float) -> void:
    var keyboard_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var desired: Vector2 = keyboard_direction
    if joystick_vector.length() > 0.05:
        desired = joystick_vector
    if desired.length() > 1.0:
        desired = desired.normalized()
    var target_velocity: Vector2 = desired * PLAYER_SPEED
    var rate: float = PLAYER_ACCEL if desired.length() > 0.05 else PLAYER_DECEL
    player_velocity = player_velocity.move_toward(target_velocity, rate * delta)
    fire_held = fire_held or Input.is_action_pressed("fire") or fire_touch >= 0
    if Input.is_action_just_pressed("missile"):
        _fire_missile()

func _process_world(delta: float) -> void:
    scroll_distance += SCROLL_SPEED * delta
    for star: Dictionary in stars:
        var star_position: Vector2 = star["position"] as Vector2
        var speed: float = float(star["speed"])
        star_position.x -= speed * delta
        if star_position.x < -4.0:
            star_position.x = VIEW_SIZE.x + 4.0
        star["position"] = star_position
    for asteroid: Dictionary in asteroids:
        var asteroid_position: Vector2 = asteroid["position"] as Vector2
        asteroid_position.x -= float(asteroid["speed"]) * delta
        asteroid["angle"] = float(asteroid["angle"]) + float(asteroid["spin"]) * delta
        if asteroid_position.x < -90.0:
            asteroid_position.x = VIEW_SIZE.x + 80.0
            asteroid_position.y = randf_range(100.0, 450.0)
        asteroid["position"] = asteroid_position
    if not civilian.is_empty() and civilian_alive:
        var civilian_position: Vector2 = civilian["position"] as Vector2
        civilian_position.x -= (SCROLL_SPEED - float(civilian["velocity"].x)) * delta
        civilian["position"] = civilian_position
        if civilian_position.x < -120.0:
            civilian_alive = false
            _complete_escort()

func _process_player(delta: float) -> void:
    player_position += player_velocity * delta
    player_position.x = clampf(player_position.x, PLAY_RECT.position.x + 45.0, PLAY_RECT.end.x * 0.52)
    player_position.y = clampf(player_position.y, PLAY_RECT.position.y + 35.0, PLAY_RECT.end.y - 35.0)

func _process_weapons(delta: float) -> void:
    primary_timer = maxf(primary_timer - delta, 0.0)
    missile_timer = maxf(missile_timer - delta, 0.0)
    var keyboard_fire: bool = Input.is_action_pressed("fire")
    if fire_held or keyboard_fire:
        if primary_timer <= 0.0:
            _fire_primary()
    fire_held = false

func _fire_primary() -> void:
    primary_timer = PRIMARY_COOLDOWN
    bullets.append({"position": player_position + Vector2(62.0, 0.0), "velocity": Vector2(BULLET_SPEED, 0.0), "damage": 12, "kind": "primary"})

func _fire_missile() -> void:
    if missile_timer > 0.0:
        return
    missile_timer = MISSILE_COOLDOWN
    bullets.append({"position": player_position + Vector2(55.0, -4.0), "velocity": Vector2(470.0, 0.0), "damage": 34, "kind": "missile"})

func _process_enemies(delta: float) -> void:
    enemy_spawn_timer -= delta
    if enemy_remaining > 0 and enemy_spawn_timer <= 0.0:
        _spawn_enemy()
        enemy_spawn_timer = 1.25 if contract_kind != "pirate" else 1.0
    for enemy: Dictionary in enemies:
        var enemy_position: Vector2 = enemy["position"] as Vector2
        var enemy_type: String = str(enemy["type"])
        var speed: float = float(enemy["speed"])
        enemy_position.x -= (SCROLL_SPEED + speed) * delta
        if enemy_type == "interceptor":
            enemy_position.y += sin(elapsed * 2.8 + float(enemy["phase"])) * 70.0 * delta
        enemy["position"] = enemy_position
        var shot_timer: float = float(enemy["shot_timer"]) - delta
        if shot_timer <= 0.0 and enemy_position.x < VIEW_SIZE.x - 50.0:
            _enemy_fire(enemy)
            shot_timer = float(enemy["shot_rate"])
        enemy["shot_timer"] = shot_timer
    var remaining_enemies: Array[Dictionary] = []
    for enemy: Dictionary in enemies:
        var enemy_position: Vector2 = enemy["position"] as Vector2
        if enemy_position.x < -130.0 and int(enemy["hp"]) > 0:
            enemy_position.x = 1290.0
            enemy_position.y = randf_range(115.0, 430.0)
            enemy["position"] = enemy_position
        if int(enemy["hp"]) > 0:
            remaining_enemies.append(enemy)
    enemies = remaining_enemies

func _spawn_enemy() -> void:
    enemy_remaining -= 1
    var y: float = randf_range(115.0, 430.0)
    var interceptor: bool = enemy_remaining % 3 == 0
    enemies.append({
        "position": Vector2(1290.0, y),
        "velocity": Vector2.ZERO,
        "hp": 24 if not interceptor else 18,
        "max_hp": 24 if not interceptor else 18,
        "speed": 55.0 if not interceptor else 110.0,
        "shot_timer": randf_range(0.8, 1.7),
        "shot_rate": 1.7 if not interceptor else 1.15,
        "phase": randf_range(0.0, 6.28),
        "type": "interceptor" if interceptor else "fighter"
    })

func _enemy_fire(enemy: Dictionary) -> void:
    var enemy_position: Vector2 = enemy["position"] as Vector2
    var direction: Vector2 = (player_position - enemy_position).normalized()
    enemy_bullets.append({"position": enemy_position + Vector2(-38.0, 0.0), "velocity": direction * ENEMY_BULLET_SPEED, "damage": 5})

func _process_projectiles(delta: float) -> void:
    var next_bullets: Array[Dictionary] = []
    for bullet: Dictionary in bullets:
        var position: Vector2 = bullet["position"] as Vector2
        position += (bullet["velocity"] as Vector2) * delta
        var hit: bool = false
        for enemy: Dictionary in enemies:
            if int(enemy["hp"]) <= 0:
                continue
            var enemy_position: Vector2 = enemy["position"] as Vector2
            var radius: float = 44.0 if str(enemy["type"]) == "interceptor" else 50.0
            if position.distance_to(enemy_position) < radius:
                enemy["hp"] = int(enemy["hp"]) - int(bullet["damage"])
                hit = true
                if int(enemy["hp"]) <= 0:
                    _enemy_destroyed()
                break
        if not hit and position.x < VIEW_SIZE.x + 80.0:
            next_bullets.append(bullet)
    bullets = next_bullets

    var next_enemy_bullets: Array[Dictionary] = []
    for projectile: Dictionary in enemy_bullets:
        var position: Vector2 = projectile["position"] as Vector2
        position += (projectile["velocity"] as Vector2) * delta
        if position.distance_to(player_position) < 34.0:
            player_hull -= int(projectile["damage"])
        elif not _asteroid_collision(position):
            if position.x > -40.0 and position.x < VIEW_SIZE.x + 40.0 and position.y > 70.0 and position.y < 475.0:
                next_enemy_bullets.append(projectile)
    enemy_bullets = next_enemy_bullets

func _asteroid_collision(position: Vector2) -> bool:
    for asteroid: Dictionary in asteroids:
        var asteroid_position: Vector2 = asteroid["position"] as Vector2
        var radius: float = 38.0 * float(asteroid["size"])
        if position.distance_to(asteroid_position) < radius:
            return true
    return false

func _enemy_destroyed() -> void:
    if enemy_remaining <= 0:
        var all_destroyed: bool = true
        for enemy: Dictionary in enemies:
            if int(enemy["hp"]) > 0:
                all_destroyed = false
                break
        if all_destroyed:
            _complete_contract()

func _complete_escort() -> void:
    if contract_kind == "escort" and civilian_alive:
        return
    if contract_kind == "escort" and enemy_remaining <= 0:
        _complete_contract()

func _check_end_conditions() -> void:
    if player_hull <= 0:
        player_hull = 1
        emit_signal("combat_lost")
        set_process(false)
        return
    if contract_kind == "escort" and not civilian_alive:
        emit_signal("combat_lost")
        set_process(false)

func _complete_contract() -> void:
    if victory_started:
        return
    victory_started = true
    set_process(false)
    emit_signal("combat_won", 220 if contract_kind == "pirate" else 190, 1)

func _unhandled_input(event: InputEvent) -> void:
    _handle_input_event(event)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion:
        _handle_input_event(event)

func _handle_input_event(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed:
            if _touch_in_rect(touch.position, Rect2(22.0, 390.0, 260.0, 145.0)) and joystick_touch < 0:
                joystick_touch = touch.index
                _update_joystick(touch.position)
            elif _touch_in_rect(touch.position, Rect2(1030.0, 400.0, 165.0, 92.0)) and fire_touch < 0:
                fire_touch = touch.index
                fire_held = true
            elif _touch_in_rect(touch.position, Rect2(850.0, 400.0, 150.0, 92.0)):
                _fire_missile()
        else:
            if touch.index == joystick_touch:
                joystick_touch = -1
                joystick_vector = Vector2.ZERO
            if touch.index == fire_touch:
                fire_touch = -1
                fire_held = false
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        if drag.index == joystick_touch:
            _update_joystick(drag.position)
    elif event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed:
                if _touch_in_rect(mouse.position, Rect2(22.0, 390.0, 260.0, 145.0)):
                    joystick_touch = 999
                    _update_joystick(mouse.position)
                elif _touch_in_rect(mouse.position, Rect2(1040.0, 390.0, 155.0, 110.0)):
                    fire_touch = 999
                    fire_held = true
                elif _touch_in_rect(mouse.position, Rect2(860.0, 390.0, 155.0, 110.0)):
                    _fire_missile()
            else:
                if joystick_touch == 999:
                    joystick_touch = -1
                    joystick_vector = Vector2.ZERO
                if fire_touch == 999:
                    fire_touch = -1
                    fire_held = false

func _update_joystick(position: Vector2) -> void:
    var centre: Vector2 = Vector2(142.0, 456.0)
    var offset: Vector2 = position - centre
    joystick_vector = offset.limit_length(86.0) / 86.0

func _touch_in_rect(position: Vector2, rect: Rect2) -> bool:
    return rect.has_point(position)

func request_break_off() -> void:
    emit_signal("combat_broken_off")
    set_process(false)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("050b13"), true)
    draw_rect(Rect2(0.0, 0.0, VIEW_SIZE.x, 66.0), Color("08131f"), true)
    draw_rect(PLAY_RECT, Color("07121d"), true)
    draw_line(Vector2(18.0, 66.0), Vector2(1214.0, 66.0), Color("285267"), 1.0)
    for star: Dictionary in stars:
        var star_position: Vector2 = star["position"] as Vector2
        var star_size: float = float(star["size"])
        var brightness: float = 0.35 + float(star["layer"]) * 0.22
        draw_circle(star_position, star_size, Color(0.65, 0.85, 0.9, brightness))
    for asteroid: Dictionary in asteroids:
        var asteroid_position: Vector2 = asteroid["position"] as Vector2
        if asteroid_texture != null:
            var size_scale: float = float(asteroid["size"])
            draw_set_transform(asteroid_position, float(asteroid["angle"]), Vector2(size_scale, size_scale))
            draw_texture(asteroid_texture, Vector2(-48.0, -48.0), Color.WHITE)
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if not civilian.is_empty() and civilian_alive:
        var civilian_position: Vector2 = civilian["position"] as Vector2
        draw_rect(Rect2(civilian_position - Vector2(52.0, 20.0), Vector2(104.0, 40.0)), Color("7e9aa6"), true)
        draw_rect(Rect2(civilian_position - Vector2(32.0, 10.0), Vector2(64.0, 20.0)), Color("b7c9ce"), true)
        draw_string(ThemeDB.fallback_font, civilian_position + Vector2(-55.0, -28.0), "ESCORT", HORIZONTAL_ALIGNMENT_LEFT, 100, 13, Color("9fd6df"))
    for enemy: Dictionary in enemies:
        var enemy_position: Vector2 = enemy["position"] as Vector2
        var enemy_type: String = str(enemy["type"])
        var texture: Texture2D = pirate_texture if contract_kind == "pirate" and enemy_remaining == 0 else fighter_texture
        if texture != null:
            var scale: Vector2 = Vector2(0.58, 0.58) if enemy_type == "interceptor" else Vector2(0.72, 0.72)
            draw_set_transform(enemy_position, 0.0, scale)
            draw_texture(texture, Vector2(-texture.get_width() * 0.5, -texture.get_height() * 0.5), Color.WHITE)
            draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        var hp_ratio: float = clampf(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)
        draw_rect(Rect2(enemy_position + Vector2(-34.0, -50.0), Vector2(68.0, 5.0)), Color("28151a"), true)
        draw_rect(Rect2(enemy_position + Vector2(-34.0, -50.0), Vector2(68.0 * hp_ratio, 5.0)), Color("e46b67"), true)
    if player_texture != null:
        draw_set_transform(player_position, 0.0, Vector2(0.58, 0.58))
        draw_texture(player_texture, Vector2(-90.0, -42.0), Color.WHITE)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    for bullet: Dictionary in bullets:
        var position: Vector2 = bullet["position"] as Vector2
        var is_missile: bool = str(bullet["kind"]) == "missile"
        draw_line(position, position - Vector2(22.0 if not is_missile else 36.0, 0.0), Color("f7d878"), 4.0 if is_missile else 2.5)
    for projectile: Dictionary in enemy_bullets:
        var position: Vector2 = projectile["position"] as Vector2
        draw_circle(position, 4.0, Color("ef7771"))
    _draw_combat_hud()

func _draw_combat_hud() -> void:
    var title: String = "COMBAT • " + contract_kind.to_upper()
    draw_string(ThemeDB.fallback_font, Vector2(26.0, 31.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("55e5ee"))
    var hint: String = "HOLD FIRE  •  TAP MISSILE  •  MOVE / DODGE  •  SURVIVE"
    draw_string(ThemeDB.fallback_font, Vector2(26.0, 52.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("7fa3b5"))
    draw_string(ThemeDB.fallback_font, Vector2(1000.0, 32.0), "HULL %d%%" % player_hull, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("6fd39b" if player_hull > 50 else "e46b67"))
    draw_string(ThemeDB.fallback_font, Vector2(930.0, 52.0), "HOSTILES %d" % (enemies.size() + enemy_remaining), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("e46b67"))
    var joystick_centre: Vector2 = Vector2(142.0, 456.0)
    draw_circle(joystick_centre, 67.0, Color(0.05, 0.12, 0.18, 0.88))
    draw_arc(joystick_centre, 67.0, 0.0, TAU, 48, Color("3b6477"), 2.0)
    draw_circle(joystick_centre + joystick_vector * 38.0, 25.0, Color(0.12, 0.35, 0.43, 0.95))
    draw_arc(joystick_centre + joystick_vector * 38.0, 25.0, 0.0, TAU, 32, Color("55e5ee"), 2.0)
    _draw_button(Rect2(850.0, 400.0, 150.0, 92.0), "MISSILE", missile_timer <= 0.0, Color("e9b85c"))
    _draw_button(Rect2(1030.0, 400.0, 165.0, 92.0), "FIRE", true, Color("55e5ee"))
    draw_string(ThemeDB.fallback_font, Vector2(55.0, 528.0), "STEER", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("7fa3b5"))

func _draw_button(rect: Rect2, text_value: String, active: bool, accent: Color) -> void:
    var fill: Color = Color(0.07, 0.13, 0.19, 0.94)
    if not active:
        fill = Color(0.05, 0.08, 0.11, 0.94)
    draw_rect(rect, fill, true)
    draw_rect(rect, Color(accent, 0.9 if active else 0.35), false, 2.0)
    var text_colour: Color = accent if active else Color("526a75")
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(0.0, 54.0), text_value, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18, text_colour)
