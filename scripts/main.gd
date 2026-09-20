class_name FrontierMain
extends Node

## FRONTIER clean vertical slice. UI is created by this controller; game state is kept in plain data.

const BG: Color = Color("08101a")
const PANEL: Color = Color("101d2b")
const PANEL_2: Color = Color("14283a")
const LINE: Color = Color("2d526b")
const TEXT: Color = Color("d9edf5")
const MUTED: Color = Color("7fa3b5")
const CYAN: Color = Color("4ed9e6")
const AMBER: Color = Color("e9b85c")
const RED: Color = Color("e46b67")
const GREEN: Color = Color("6fd39b")

var screen: String = "cockpit"
var credits: int = 1450
var fuel: int = 82
var hull: int = 100
var cargo_capacity: int = 18
var cargo: Dictionary = {"Water": 3, "Food": 2, "Components": 2}
var components: int = 2
var rare_components: int = 0
var data_fragments: int = 0
var current_system: String = "Harrow"
var destination: String = "Harrow"
var discovered: Dictionary = {"Harrow": true, "Kestrel": true}
var reputation: Dictionary = {"Commonwealth": 0, "Helix": 0, "Veyran": 0, "Free Captains": 2}
var story_flags: Dictionary = {"survey_found": false}

var root_ui: Control
var content: Control
var footer: HBoxContainer
var toast: Label
var combat_running: bool = false
var player_pos: Vector2 = Vector2(170, 350)
var enemy_pos: Vector2 = Vector2(1030, 350)
var enemy_hp: int = 60
var fire_timer: float = 0.0
var missile_ready: bool = true
var combat_nodes: Array[Node] = []

func _ready() -> void:
    _setup_input()
    _build_shell()
    show_cockpit()

func _setup_input() -> void:
    var actions: Array[String] = ["move_up", "move_down", "move_left", "move_right", "fire", "missile"]
    for action_name: String in actions:
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)
    _add_key("move_up", KEY_W)
    _add_key("move_up", KEY_UP)
    _add_key("move_down", KEY_S)
    _add_key("move_down", KEY_DOWN)
    _add_key("move_left", KEY_A)
    _add_key("move_left", KEY_LEFT)
    _add_key("move_right", KEY_D)
    _add_key("move_right", KEY_RIGHT)
    _add_key("fire", KEY_SPACE)
    _add_key("missile", KEY_M)

func _add_key(action_name: String, keycode: Key) -> void:
    var event: InputEventKey = InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action_name, event)

func _process(delta: float) -> void:
    if combat_running:
        _process_combat(delta)

func _build_shell() -> void:
    root_ui = Control.new()
    root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root_ui)
    var background: ColorRect = ColorRect.new()
    background.color = BG
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_ui.add_child(background)

    var top: HBoxContainer = HBoxContainer.new()
    top.position = Vector2(24, 18)
    top.size = Vector2(1232, 54)
    root_ui.add_child(top)
    var title: Label = Label.new()
    title.text = "F R O N T I E R"
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", CYAN)
    title.custom_minimum_size = Vector2(300, 48)
    top.add_child(title)
    var spacer: Control = Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(spacer)
    var state: Label = Label.new()
    state.name = "State"
    state.text = "Harrow • Docked"
    state.add_theme_color_override("font_color", MUTED)
    state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    state.custom_minimum_size = Vector2(360, 48)
    top.add_child(state)

    content = Control.new()
    content.position = Vector2(24, 84)
    content.size = Vector2(1232, 540)
    root_ui.add_child(content)

    footer = HBoxContainer.new()
    footer.position = Vector2(24, 640)
    footer.size = Vector2(1232, 58)
    footer.add_theme_constant_override("separation", 10)
    root_ui.add_child(footer)
    toast = Label.new()
    toast.position = Vector2(24, 604)
    toast.size = Vector2(1232, 30)
    toast.add_theme_color_override("font_color", AMBER)
    root_ui.add_child(toast)

func clear_content() -> void:
    for child: Node in content.get_children():
        child.queue_free()
    for child: Node in footer.get_children():
        child.queue_free()
    combat_running = false
    combat_nodes.clear()

func panel(parent: Node, rect: Rect2) -> VBoxContainer:
    var box: PanelContainer = PanelContainer.new()
    box.position = rect.position
    box.size = rect.size
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = PANEL
    style.border_color = LINE
    style.set_border_width_all(1)
    style.corner_radius_top_left = 6
    style.corner_radius_top_right = 6
    style.corner_radius_bottom_left = 6
    style.corner_radius_bottom_right = 6
    box.add_theme_stylebox_override("panel", style)
    parent.add_child(box)
    var inner: VBoxContainer = VBoxContainer.new()
    inner.add_theme_constant_override("separation", 8)
    box.add_child(inner)
    return inner

func label(parent: Node, text_value: String, size: int = 18, colour: Color = TEXT) -> Label:
    var l: Label = Label.new()
    l.text = text_value
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", colour)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(l)
    return l

func button(parent: Node, text_value: String, callback: Callable) -> Button:
    var b: Button = Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(0, 52)
    b.add_theme_font_size_override("font_size", 17)
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func add_footer_button(text_value: String, callback: Callable) -> void:
    var b: Button = button(footer, text_value, callback)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func show_cockpit() -> void:
    clear_content()
    screen = "cockpit"
    var left: VBoxContainer = panel(content, Rect2(0, 0, 760, 540))
    label(left, "COCKPIT / HARROW SYSTEM", 22, CYAN)
    label(left, "Independent captain • Frigate-class frontier vessel", 15, MUTED)
    var readout: Label = label(left, "\nFORWARD VIEW\n\nA quiet shipping lane cuts across the dark. Kestrel is charted beyond the local jump route.\n\nA faint transponder ping is being repeated from an old survey channel.\n\nNothing is forcing you to investigate.", 20)
    readout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    label(left, "Ship: Frontier Runner     Hull %d/100     Fuel %d%%     Cargo %d/%d" % [hull, fuel, cargo_total(), cargo_capacity], 16, GREEN if hull > 50 else RED)

    var right: VBoxContainer = panel(content, Rect2(780, 0, 452, 540))
    label(right, "CAPTAIN'S TERMINAL", 22, CYAN)
    label(right, "Credits", 14, MUTED)
    label(right, "%d CR" % credits, 28, AMBER)
    label(right, "\nCURRENT OPPORTUNITIES", 16, MUTED)
    button(right, "Open Galaxy Map", show_galaxy)
    button(right, "Visit Market", show_market)
    button(right, "Ship & Cargo", show_ship)
    button(right, "Take a contract", show_missions)
    button(right, "Investigate the survey ping", begin_survey)
    label(right, "\nNo destiny. No prophecy. Just another job on the frontier.", 14, MUTED)

    add_footer_button("GALAXY", show_galaxy)
    add_footer_button("MARKET", show_market)
    add_footer_button("SHIP", show_ship)
    add_footer_button("MISSIONS", show_missions)

func show_galaxy() -> void:
    clear_content()
    screen = "galaxy"
    var map: VBoxContainer = panel(content, Rect2(0, 0, 790, 540))
    label(map, "GALAXY / LOCAL FRONTIER", 22, CYAN)
    label(map, "Known space is deliberately small at first. Distance will matter.", 14, MUTED)
    var rows: VBoxContainer = VBoxContainer.new()
    rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map.add_child(rows)
    galaxy_row(rows, "Harrow", "Current system • station • frontier market", 0)
    galaxy_row(rows, "Kestrel", "Known • mining colonies • 1 jump", 1)
    galaxy_row(rows, "Vega Reach", "Uncharted • deep frontier • 2 jumps", 2)
    galaxy_row(rows, "Veyran Border", "Restricted route • diplomatic patrols", 3)

    var info: VBoxContainer = panel(content, Rect2(810, 0, 422, 540))
    label(info, "NAVIGATION", 22, CYAN)
    label(info, "Select a destination. The terminal will show route cost and known risks.", 16)
    label(info, "\nFuel: %d%%" % fuel, 20, GREEN)
    button(info, "Travel to Kestrel — 12 fuel", func() -> void: travel_to("Kestrel", 12))
    button(info, "Travel to Vega Reach — 24 fuel", func() -> void: travel_to("Vega Reach", 24))
    button(info, "Stay in Harrow", func() -> void: show_cockpit())
    label(info, "\nUnknown routes may contain signals, derelicts, hazards or encounters.", 14, MUTED)
    add_footer_button("COCKPIT", show_cockpit)
    add_footer_button("MISSIONS", show_missions)
    add_footer_button("SHIP", show_ship)
    add_footer_button("MARKET", show_market)

func galaxy_row(parent: Node, name_value: String, description: String, index: int) -> void:
    var b: Button = Button.new()
    b.text = "%s\n%s" % [name_value, description]
    b.alignment = HORIZONTAL_ALIGNMENT_LEFT
    b.custom_minimum_size = Vector2(0, 78)
    b.add_theme_font_size_override("font_size", 16)
    b.pressed.connect(func() -> void: toast_message("Selected %s" % name_value))
    parent.add_child(b)

func travel_to(target: String, cost: int) -> void:
    if fuel < cost:
        toast_message("Not enough fuel.")
        return
    fuel -= cost
    current_system = target
    discovered[target] = true
    toast_message("FTL transit complete. %s reached." % target)
    if target == "Kestrel":
        show_system()
    else:
        show_exploration()

func show_system() -> void:
    clear_content()
    screen = "system"
    var left: VBoxContainer = panel(content, Rect2(0, 0, 790, 540))
    label(left, "KESTREL SYSTEM", 22, CYAN)
    label(left, "A practical mining system: industrial traffic, old survey routes and plenty of things worth recovering.", 15, MUTED)
    label(left, "\nCONTACTS", 16, MUTED)
    button(left, "Kestrel Station — market / repairs", show_market)
    button(left, "Asteroid Belt — mining opportunity", func() -> void: toast_message("Mining equipment required for best yields."))
    button(left, "Derelict Survey Vessel — weak signal", begin_survey)
    button(left, "Outer debris field — salvage", func() -> void: collect_salvage())

    var right: VBoxContainer = panel(content, Rect2(810, 0, 422, 540))
    label(right, "SYSTEM NOTES", 22, CYAN)
    label(right, "Nothing here looks extraordinary. That is often when frontier captains make money.", 18)
    label(right, "\nFuel cost to return: 12", 16, MUTED)
    button(right, "Run a sensor sweep", func() -> void: toast_message("Sweep: 3 commercial contacts, 1 weak unregistered signal."))
    button(right, "Return to galaxy", show_galaxy)
    add_footer_button("GALAXY", show_galaxy)
    add_footer_button("MARKET", show_market)
    add_footer_button("MISSIONS", show_missions)
    add_footer_button("SHIP", show_ship)

func show_exploration() -> void:
    clear_content()
    screen = "exploration"
    var left: VBoxContainer = panel(content, Rect2(0, 0, 790, 540))
    label(left, "VEGA REACH / DEEP FRONTIER", 22, CYAN)
    label(left, "The stars are quieter here. Your instruments are doing more work than your weapons.", 15, MUTED)
    label(left, "\nCONTACTS", 16, MUTED)
    button(left, "Uncatalogued planet — scan", func() -> void: toast_message("Atmosphere: nitrogen/oxygen mix. Signs of complex life. Discovery recorded."))
    button(left, "Long-range signal — investigate", func() -> void: begin_signal())
    button(left, "Rocky moon — resource scan", func() -> void: toast_message("Trace rare minerals detected. Mining yield uncertain."))
    button(left, "Silent wreck — approach", func() -> void: begin_combat("wreck_guard"))

    var right: VBoxContainer = panel(content, Rect2(810, 0, 422, 540))
    label(right, "SCIENCE LOG", 22, CYAN)
    label(right, "Unknown systems can yield discoveries, resources, contacts and danger. The player decides what deserves attention.", 17)
    label(right, "\nDATA FRAGMENTS: %d" % data_fragments, 18, AMBER)
    button(right, "Record system in Codex", func() -> void: data_fragments += 1; toast_message("Discovery recorded."))
    button(right, "Return to galaxy", show_galaxy)
    add_footer_button("GALAXY", show_galaxy)
    add_footer_button("COCKPIT", show_cockpit)
    add_footer_button("SHIP", show_ship)
    add_footer_button("MISSIONS", show_missions)

func show_market() -> void:
    clear_content()
    screen = "market"
    var left: VBoxContainer = panel(content, Rect2(0, 0, 790, 540))
    label(left, "HARROW MARKET", 22, CYAN)
    label(left, "Prices vary by system and circumstance. This is a frontier market, not a universal shop.", 14, MUTED)
    trade_row(left, "Water", 18, 11)
    trade_row(left, "Food", 26, 15)
    trade_row(left, "Components", 30, 19)
    trade_row(left, "Rare Components", 92, 70)
    label(left, "\nCargo: %d/%d" % [cargo_total(), cargo_capacity], 17, GREEN)

    var right: VBoxContainer = panel(content, Rect2(810, 0, 422, 540))
    label(right, "MARKET ACTIONS", 22, CYAN)
    button(right, "Buy Water (18 CR)", func() -> void: buy_good("Water", 18))
    button(right, "Buy Food (26 CR)", func() -> void: buy_good("Food", 26))
    button(right, "Sell Water (11 CR)", func() -> void: sell_good("Water", 11))
    button(right, "Sell Components (30 CR)", func() -> void: sell_good("Components", 30))
    button(right, "Sell Rare Components (92 CR)", func() -> void: sell_good("Rare Components", 92))
    button(right, "Repair hull — 40 CR", repair_hull)
    add_footer_button("COCKPIT", show_cockpit)
    add_footer_button("GALAXY", show_galaxy)
    add_footer_button("SHIP", show_ship)
    add_footer_button("MISSIONS", show_missions)

func trade_row(parent: Node, good: String, buy: int, sell: int) -> void:
    label(parent, "%s     BUY %d     SELL %d     IN CARGO %d" % [good, buy, sell, int(cargo.get(good, 0))], 17)

func buy_good(good: String, price: int) -> void:
    if cargo_total() >= cargo_capacity:
        toast_message("Cargo full.")
        return
    if credits < price:
        toast_message("Not enough credits.")
        return
    credits -= price
    cargo[good] = int(cargo.get(good, 0)) + 1
    toast_message("Bought 1 %s." % good)
    show_market()

func sell_good(good: String, price: int) -> void:
    var amount: int = int(cargo.get(good, 0))
    if amount <= 0:
        toast_message("You do not have any %s." % good)
        return
    cargo[good] = amount - 1
    credits += price
    toast_message("Sold 1 %s for %d CR." % [good, price])
    show_market()

func show_ship() -> void:
    clear_content()
    screen = "ship"
    var left: VBoxContainer = panel(content, Rect2(0, 0, 600, 540))
    label(left, "SHIP / FRONTIER RUNNER", 22, CYAN)
    label(left, "Frigate-class independent vessel", 15, MUTED)
    label(left, "\nHULL      %d / 100" % hull, 19, GREEN if hull > 50 else RED)
    label(left, "ENGINE    Mk I", 17)
    label(left, "COILGUN   Mk I", 17)
    label(left, "SENSORS   Mk I", 17)
    label(left, "CARGO     %d / %d" % [cargo_total(), cargo_capacity], 17)
    label(left, "FTL       Operational", 17)
    label(left, "\nCOMPONENTS %d     RARE %d" % [components, rare_components], 17, AMBER)

    var right: VBoxContainer = panel(content, Rect2(620, 0, 612, 540))
    label(right, "REFIT & CARGO", 22, CYAN)
    button(right, "Reinforced Hull — 600 CR + 2 Components", upgrade_hull)
    button(right, "Engine Mk II — 700 CR + 2 Components", upgrade_engine)
    button(right, "Coilgun Mk II — 800 CR + 3 Components", upgrade_weapon)
    label(right, "\nCARGO HOLD", 16, MUTED)
    for good: String in ["Water", "Food", "Components", "Rare Components"]:
        label(right, "%s: %d" % [good, int(cargo.get(good, 0))], 16)
    button(right, "Use a Component to restore 15 hull", use_component)
    button(right, "Back to cockpit", show_cockpit)
    add_footer_button("COCKPIT", show_cockpit)
    add_footer_button("MARKET", show_market)
    add_footer_button("GALAXY", show_galaxy)
    add_footer_button("MISSIONS", show_missions)

func upgrade_hull() -> void:
    if credits >= 600 and components >= 2:
        credits -= 600
        components -= 2
        cargo_capacity += 2
        hull = 120
        toast_message("Reinforced hull installed. Cargo capacity +2.")
        show_ship()
    else:
        toast_message("Need 600 CR and 2 Components.")

func upgrade_engine() -> void:
    if credits >= 700 and components >= 2:
        credits -= 700
        components -= 2
        fuel = min(fuel + 20, 100)
        toast_message("Engine Mk II installed. Fuel reserves topped up.")
        show_ship()
    else:
        toast_message("Need 700 CR and 2 Components.")

func upgrade_weapon() -> void:
    if credits >= 800 and components >= 3:
        credits -= 800
        components -= 3
        toast_message("Coilgun Mk II installed. Combat damage increased.")
        show_ship()
    else:
        toast_message("Need 800 CR and 3 Components.")

func use_component() -> void:
    if components <= 0:
        toast_message("No spare component.")
        return
    if hull >= 100:
        toast_message("Hull does not need repair.")
        return
    components -= 1
    hull = min(hull + 15, 100)
    toast_message("Field repair complete.")
    show_ship()

func repair_hull() -> void:
    if hull >= 100:
        toast_message("Hull already at maximum.")
    elif credits >= 40:
        credits -= 40
        hull = 100
        toast_message("Dockyard repair complete.")
        show_market()
    else:
        toast_message("Need 40 CR.")

func show_missions() -> void:
    clear_content()
    screen = "missions"
    var left: VBoxContainer = panel(content, Rect2(0, 0, 790, 540))
    label(left, "CONTRACT BOARD", 22, CYAN)
    label(left, "Work is the backbone of frontier life. Major story events emerge from it rather than replacing it.", 14, MUTED)
    button(left, "ESCORT — Mining hauler to Kestrel", func() -> void: begin_combat("escort"))
    button(left, "SALVAGE — Recover components from a derelict", func() -> void: collect_salvage())
    button(left, "BOUNTY — Pirate raider in the outer lane", func() -> void: begin_combat("pirate"))
    button(left, "SURVEY — Chart a weak signal", begin_survey)
    var right: VBoxContainer = panel(content, Rect2(810, 0, 422, 540))
    label(right, "CONTRACT STATUS", 22, CYAN)
    label(right, "Reputation", 15, MUTED)
    label(right, "Commonwealth: %d\nHelix: %d\nVeyran: %d\nFree Captains: %d" % [reputation["Commonwealth"], reputation["Helix"], reputation["Veyran"], reputation["Free Captains"]], 16)
    label(right, "\nA captain's reputation is earned through actions, not a morality bar.", 14, MUTED)
    add_footer_button("COCKPIT", show_cockpit)
    add_footer_button("GALAXY", show_galaxy)
    add_footer_button("SHIP", show_ship)
    add_footer_button("MARKET", show_market)

func begin_survey() -> void:
    if story_flags["survey_found"]:
        toast_message("The survey mystery is already in your log.")
        return
    story_flags["survey_found"] = true
    data_fragments += 1
    reputation["Free Captains"] += 1
    clear_content()
    var left: VBoxContainer = panel(content, Rect2(0, 0, 790, 540))
    label(left, "SALVAGE LOG / UNKNOWN SURVEY VESSEL", 22, CYAN)
    label(left, "The vessel is old enough to have been presumed lost for years. Its crew are dead or missing. Most of the data core is corrupted.", 18)
    label(left, "\nRECOVERED FRAGMENT", 16, MUTED)
    label(left, "\"They are not where the records say they are.\"", 27, AMBER)
    label(left, "\nThis is not an answer. It is the first piece of a question.", 17)
    var right: VBoxContainer = panel(content, Rect2(810, 0, 422, 540))
    label(right, "NEW THREAD", 22, CYAN)
    label(right, "A recognised system has been deliberately omitted from old survey records.", 18)
    button(right, "Log the discovery", func() -> void: show_cockpit())
    button(right, "Pursue the missing frontier", func() -> void: show_exploration())
    add_footer_button("COCKPIT", show_cockpit)
    add_footer_button("GALAXY", show_galaxy)
    add_footer_button("MISSIONS", show_missions)
    add_footer_button("CODEX", func() -> void: toast_message("Codex entry added: Missing Survey.") )

func begin_signal() -> void:
    toast_message("The signal contains structured navigation data. Someone wanted it to be found.")
    begin_combat("signal")

func collect_salvage() -> void:
    components += 2
    credits += 120
    toast_message("Salvage recovered: 2 Components + 120 CR.")
    show_ship()

func begin_combat(kind: String) -> void:
    clear_content()
    screen = "combat"
    combat_running = true
    enemy_hp = 60 if kind != "pirate" else 85
    player_pos = Vector2(170, 350)
    enemy_pos = Vector2(1030, 350)
    fire_timer = 0.0
    missile_ready = true
    var arena: Control = Control.new()
    arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    content.add_child(arena)
    combat_nodes.append(arena)
    var title: Label = label(arena, "COMBAT • %s" % kind.to_upper(), 22, CYAN)
    title.position = Vector2(20, 10)
    var hint: Label = label(arena, "WASD / arrow keys move • SPACE fire • M missile • survive and destroy the target", 14, MUTED)
    hint.position = Vector2(20, 45)
    var ship: ColorRect = ColorRect.new()
    ship.color = CYAN
    ship.size = Vector2(48, 20)
    ship.position = player_pos
    ship.name = "PlayerSprite"
    arena.add_child(ship)
    var enemy: ColorRect = ColorRect.new()
    enemy.color = RED
    enemy.size = Vector2(72, 34)
    enemy.position = enemy_pos
    enemy.name = "EnemySprite"
    arena.add_child(enemy)
    var hp: Label = label(arena, "TARGET %d / %d" % [enemy_hp, 60 if kind != "pirate" else 85], 16, RED)
    hp.position = Vector2(930, 70)
    hp.name = "EnemyHP"
    var player_hp: Label = label(arena, "HULL %d" % hull, 18, GREEN)
    player_hp.position = Vector2(20, 500)
    player_hp.name = "PlayerHP"
    var quit: Button = Button.new()
    quit.text = "BREAK OFF"
    quit.position = Vector2(1050, 485)
    quit.size = Vector2(150, 48)
    quit.pressed.connect(func() -> void: end_combat(false))
    arena.add_child(quit)
    add_footer_button("FIRE: SPACE", func() -> void: toast_message("Hold SPACE on keyboard; mobile build uses touch FIRE."))
    add_footer_button("MISSILE: M", func() -> void: fire_missile())
    add_footer_button("BREAK OFF", func() -> void: end_combat(false))

func _process_combat(delta: float) -> void:
    var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    player_pos += direction * 340.0 * delta
    player_pos.x = clampf(player_pos.x, 60.0, 600.0)
    player_pos.y = clampf(player_pos.y, 130.0, 500.0)
    fire_timer -= delta
    if Input.is_action_pressed("fire") and fire_timer <= 0.0:
        enemy_hp -= 12
        fire_timer = 0.24
        toast_message("Hit.")
    if Input.is_action_just_pressed("missile"):
        fire_missile()
    var arena: Control = combat_nodes[0] as Control if combat_nodes.size() > 0 else null
    if arena != null:
        var ship: ColorRect = arena.get_node_or_null("PlayerSprite") as ColorRect
        var enemy: ColorRect = arena.get_node_or_null("EnemySprite") as ColorRect
        var hp_label: Label = arena.get_node_or_null("EnemyHP") as Label
        var player_label: Label = arena.get_node_or_null("PlayerHP") as Label
        if ship != null:
            ship.position = player_pos
        if enemy != null:
            enemy.position = enemy_pos
        if hp_label != null:
            hp_label.text = "TARGET %d" % max(enemy_hp, 0)
        if player_label != null:
            player_label.text = "HULL %d" % hull
    if enemy_hp <= 0:
        end_combat(true)
    else:
        if randf() < delta * 0.35 and player_pos.distance_to(enemy_pos) < 900.0:
            hull -= 2
            if hull <= 0:
                hull = 25
                end_combat(false)

func fire_missile() -> void:
    if not combat_running:
        return
    if not missile_ready:
        toast_message("Missile reloading.")
        return
    missile_ready = false
    enemy_hp -= 28
    toast_message("MISSILE HIT — 28 damage.")
    get_tree().create_timer(3.0).timeout.connect(func() -> void: missile_ready = true)

func end_combat(victory: bool) -> void:
    combat_running = false
    var was_story: bool = screen == "combat"
    if victory:
        credits += 180
        components += 1
        reputation["Free Captains"] += 1
        toast_message("Combat won. +180 CR, +1 Component.")
        show_missions()
    else:
        toast_message("You disengage. The frontier will still be here.")
        show_cockpit()

func cargo_total() -> int:
    var total: int = 0
    for value: Variant in cargo.values():
        total += int(value)
    return total

func toast_message(message: String) -> void:
    toast.text = message
    var timer: SceneTreeTimer = get_tree().create_timer(3.0)
    timer.timeout.connect(func() -> void:
        if toast.text == message:
            toast.text = ""
    )
