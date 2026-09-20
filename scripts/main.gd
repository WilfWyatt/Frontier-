class_name FrontierMain
extends Node

## FRONTIER application shell. Combat is a separate scene/script so arcade play never becomes terminal UI.

const BG: Color = Color("08101a")
const PANEL: Color = Color("101d2b")
const LINE: Color = Color("2d526b")
const TEXT: Color = Color("d9edf5")
const MUTED: Color = Color("7fa3b5")
const CYAN: Color = Color("4ed9e6")
const AMBER: Color = Color("e9b85c")
const RED: Color = Color("e46b67")
const GREEN: Color = Color("6fd39b")

var root_ui: Control
var content: Control
var footer: HBoxContainer
var toast: Label
var combat: FrontierCombat
var combat_break_button: Button

var credits: int = 1450
var fuel: int = 82
var hull: int = 100
var cargo_capacity: int = 18
var cargo: Dictionary = {"Water": 3, "Food": 2, "Components": 2}
var components: int = 2
var rare_components: int = 0
var data_fragments: int = 0
var current_system: String = "Harrow"
var reputation: Dictionary = {"Commonwealth": 0, "Helix": 0, "Veyran": 0, "Free Captains": 2}
var story_flags: Dictionary = {"survey_found": false}
var screen: String = "cockpit"

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

func _clear_content() -> void:
    for child: Node in content.get_children():
        child.queue_free()
    for child: Node in footer.get_children():
        child.queue_free()

func _panel(parent: Node, rect: Rect2) -> VBoxContainer:
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
    inner.add_theme_constant_override("separation", 9)
    box.add_child(inner)
    return inner

func _label(parent: Node, text_value: String, size: int = 18, colour: Color = TEXT) -> Label:
    var result: Label = Label.new()
    result.text = text_value
    result.add_theme_font_size_override("font_size", size)
    result.add_theme_color_override("font_color", colour)
    result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result.custom_minimum_size.x = 0.0
    parent.add_child(result)
    return result

func _button(parent: Node, text_value: String, callback: Callable) -> Button:
    var result: Button = Button.new()
    result.text = text_value
    result.custom_minimum_size = Vector2(0, 52)
    result.add_theme_font_size_override("font_size", 17)
    result.pressed.connect(callback)
    parent.add_child(result)
    return result

func _footer_button(text_value: String, callback: Callable) -> void:
    var result: Button = _button(footer, text_value, callback)
    result.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func show_cockpit() -> void:
    _close_combat()
    _clear_content()
    screen = "cockpit"
    var left: VBoxContainer = _panel(content, Rect2(0, 0, 760, 540))
    _label(left, "COCKPIT / %s SYSTEM" % current_system.to_upper(), 22, CYAN)
    _label(left, "Independent captain • Frigate-class frontier vessel", 15, MUTED)
    var readout: Label = _label(left, "\nFORWARD VIEW\n\nA quiet shipping lane cuts across the dark. Kestrel is charted beyond the local jump route.\n\nA faint transponder ping is being repeated from an old survey channel.\n\nNothing is forcing you to investigate.", 20)
    readout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _label(left, "Frontier Runner     Hull %d/100     Fuel %d%%     Cargo %d/%d" % [hull, fuel, _cargo_total(), cargo_capacity], 16, GREEN if hull > 50 else RED)

    var right: VBoxContainer = _panel(content, Rect2(780, 0, 452, 540))
    _label(right, "CAPTAIN'S TERMINAL", 22, CYAN)
    _label(right, "Credits", 14, MUTED)
    _label(right, "%d CR" % credits, 28, AMBER)
    _label(right, "CURRENT OPPORTUNITIES", 16, MUTED)
    _button(right, "Open Galaxy Map", show_galaxy)
    _button(right, "Visit Market", show_market)
    _button(right, "Ship & Cargo", show_ship)
    _button(right, "Take a contract", show_missions)
    _button(right, "Investigate the survey ping", begin_survey)
    _label(right, "No destiny. No prophecy. Just another job on the frontier.", 14, MUTED)

    _footer_button("GALAXY", show_galaxy)
    _footer_button("MARKET", show_market)
    _footer_button("SHIP", show_ship)
    _footer_button("MISSIONS", show_missions)

func show_galaxy() -> void:
    _close_combat()
    _clear_content()
    screen = "galaxy"
    var map: VBoxContainer = _panel(content, Rect2(0, 0, 790, 540))
    _label(map, "GALAXY / LOCAL FRONTIER", 22, CYAN)
    _label(map, "Known space is deliberately small at first. Distance will matter.", 14, MUTED)
    var rows: VBoxContainer = VBoxContainer.new()
    rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map.add_child(rows)
    _galaxy_row(rows, "Harrow", "Current system • station • frontier market")
    _galaxy_row(rows, "Kestrel", "Known • mining colonies • 1 jump")
    _galaxy_row(rows, "Vega Reach", "Uncharted • deep frontier • 2 jumps")
    _galaxy_row(rows, "Veyran Border", "Restricted route • diplomatic patrols")

    var info: VBoxContainer = _panel(content, Rect2(810, 0, 422, 540))
    _label(info, "NAVIGATION", 22, CYAN)
    _label(info, "Select a destination. Route cost and risk are shown before you commit.", 16)
    _label(info, "Fuel: %d%%" % fuel, 20, GREEN)
    _button(info, "Travel to Kestrel — 12 fuel", func() -> void: _travel_to("Kestrel", 12))
    _button(info, "Travel to Vega Reach — 24 fuel", func() -> void: _travel_to("Vega Reach", 24))
    _button(info, "Stay in %s" % current_system, show_cockpit)
    _label(info, "Unknown routes may contain signals, derelicts, hazards or encounters.", 14, MUTED)
    _footer_button("COCKPIT", show_cockpit)
    _footer_button("MISSIONS", show_missions)
    _footer_button("SHIP", show_ship)
    _footer_button("MARKET", show_market)

func _galaxy_row(parent: Node, name_value: String, description: String) -> void:
    var result: Button = Button.new()
    result.text = "%s\n%s" % [name_value, description]
    result.alignment = HORIZONTAL_ALIGNMENT_LEFT
    result.custom_minimum_size = Vector2(0, 78)
    result.add_theme_font_size_override("font_size", 16)
    result.pressed.connect(func() -> void: toast_message("Selected %s" % name_value))
    parent.add_child(result)

func _travel_to(target: String, cost: int) -> void:
    if fuel < cost:
        toast_message("Not enough fuel.")
        return
    fuel -= cost
    current_system = target
    toast_message("FTL transit complete. %s reached." % target)
    if target == "Kestrel":
        show_system()
    else:
        show_exploration()

func show_system() -> void:
    _close_combat()
    _clear_content()
    screen = "system"
    var left: VBoxContainer = _panel(content, Rect2(0, 0, 790, 540))
    _label(left, "KESTREL SYSTEM", 22, CYAN)
    _label(left, "Industrial traffic, old survey routes and plenty of things worth recovering.", 15, MUTED)
    _label(left, "CONTACTS", 16, MUTED)
    _button(left, "Kestrel Station — market / repairs", show_market)
    _button(left, "Asteroid Belt — mining opportunity", func() -> void: toast_message("Mining equipment required for best yields."))
    _button(left, "Derelict Survey Vessel — weak signal", begin_survey)
    _button(left, "Outer debris field — salvage", _collect_salvage)

    var right: VBoxContainer = _panel(content, Rect2(810, 0, 422, 540))
    _label(right, "SYSTEM NOTES", 22, CYAN)
    _label(right, "Nothing here looks extraordinary. That is often when frontier captains make money.", 18)
    _label(right, "Fuel cost to return: 12", 16, MUTED)
    _button(right, "Run a sensor sweep", func() -> void: toast_message("Sweep: 3 commercial contacts, 1 weak unregistered signal."))
    _button(right, "Return to galaxy", show_galaxy)
    _footer_button("GALAXY", show_galaxy)
    _footer_button("MARKET", show_market)
    _footer_button("MISSIONS", show_missions)
    _footer_button("SHIP", show_ship)

func show_exploration() -> void:
    _close_combat()
    _clear_content()
    screen = "exploration"
    var left: VBoxContainer = _panel(content, Rect2(0, 0, 790, 540))
    _label(left, "VEGA REACH / DEEP FRONTIER", 22, CYAN)
    _label(left, "The stars are quieter here. Your instruments are doing more work than your weapons.", 15, MUTED)
    _label(left, "CONTACTS", 16, MUTED)
    _button(left, "Uncatalogued planet — scan", func() -> void: toast_message("Atmosphere: nitrogen/oxygen mix. Signs of complex life. Discovery recorded."))
    _button(left, "Long-range signal — investigate", func() -> void: begin_combat("signal"))
    _button(left, "Rocky moon — resource scan", func() -> void: toast_message("Trace rare minerals detected. Mining yield uncertain."))
    _button(left, "Silent wreck — approach", func() -> void: begin_combat("wreck_guard"))

    var right: VBoxContainer = _panel(content, Rect2(810, 0, 422, 540))
    _label(right, "SCIENCE LOG", 22, CYAN)
    _label(right, "Unknown systems can yield discoveries, resources, contacts and danger. The player decides what deserves attention.", 17)
    _label(right, "DATA FRAGMENTS: %d" % data_fragments, 18, AMBER)
    _button(right, "Record system in Codex", func() -> void: data_fragments += 1; toast_message("Discovery recorded."))
    _button(right, "Return to galaxy", show_galaxy)
    _footer_button("GALAXY", show_galaxy)
    _footer_button("COCKPIT", show_cockpit)
    _footer_button("SHIP", show_ship)
    _footer_button("MISSIONS", show_missions)

func show_market() -> void:
    _close_combat()
    _clear_content()
    screen = "market"
    var left: VBoxContainer = _panel(content, Rect2(0, 0, 790, 540))
    _label(left, "%s MARKET" % current_system.to_upper(), 22, CYAN)
    _label(left, "Prices vary by system and circumstance. This is a frontier market, not a universal shop.", 14, MUTED)
    _trade_row(left, "Water", 18, 11)
    _trade_row(left, "Food", 26, 15)
    _trade_row(left, "Components", 30, 19)
    _trade_row(left, "Rare Components", 92, 70)
    _label(left, "Cargo: %d/%d" % [_cargo_total(), cargo_capacity], 17, GREEN)

    var right: VBoxContainer = _panel(content, Rect2(810, 0, 422, 540))
    _label(right, "MARKET ACTIONS", 22, CYAN)
    _button(right, "Buy Water (18 CR)", func() -> void: _buy_good("Water", 18))
    _button(right, "Buy Food (26 CR)", func() -> void: _buy_good("Food", 26))
    _button(right, "Sell Water (11 CR)", func() -> void: _sell_good("Water", 11))
    _button(right, "Sell Components (30 CR)", func() -> void: _sell_good("Components", 30))
    _button(right, "Sell Rare Components (92 CR)", func() -> void: _sell_good("Rare Components", 92))
    _button(right, "Repair hull — 40 CR", _repair_hull)
    _footer_button("COCKPIT", show_cockpit)
    _footer_button("GALAXY", show_galaxy)
    _footer_button("SHIP", show_ship)
    _footer_button("MISSIONS", show_missions)

func _trade_row(parent: Node, good: String, buy: int, sell: int) -> void:
    _label(parent, "%s     BUY %d     SELL %d     IN CARGO %d" % [good, buy, sell, int(cargo.get(good, 0))], 17)

func _buy_good(good: String, price: int) -> void:
    if _cargo_total() >= cargo_capacity:
        toast_message("Cargo full.")
        return
    if credits < price:
        toast_message("Not enough credits.")
        return
    credits -= price
    cargo[good] = int(cargo.get(good, 0)) + 1
    toast_message("Bought 1 %s." % good)
    show_market()

func _sell_good(good: String, price: int) -> void:
    var amount: int = int(cargo.get(good, 0))
    if amount <= 0:
        toast_message("You do not have any %s." % good)
        return
    cargo[good] = amount - 1
    credits += price
    toast_message("Sold 1 %s for %d CR." % [good, price])
    show_market()

func show_ship() -> void:
    _close_combat()
    _clear_content()
    screen = "ship"
    var left: VBoxContainer = _panel(content, Rect2(0, 0, 600, 540))
    _label(left, "SHIP / FRONTIER RUNNER", 22, CYAN)
    _label(left, "Frigate-class independent vessel", 15, MUTED)
    _label(left, "HULL      %d / 100" % hull, 19, GREEN if hull > 50 else RED)
    _label(left, "ENGINE    Mk I", 17)
    _label(left, "COILGUN   Mk I", 17)
    _label(left, "SENSORS   Mk I", 17)
    _label(left, "CARGO     %d / %d" % [_cargo_total(), cargo_capacity], 17)
    _label(left, "FTL       Operational", 17)
    _label(left, "COMPONENTS %d     RARE %d" % [components, rare_components], 17, AMBER)

    var right: VBoxContainer = _panel(content, Rect2(620, 0, 612, 540))
    _label(right, "REFIT & CARGO", 22, CYAN)
    _button(right, "Reinforced Hull — 600 CR + 2 Components", _upgrade_hull)
    _button(right, "Engine Mk II — 700 CR + 2 Components", _upgrade_engine)
    _button(right, "Coilgun Mk II — 800 CR + 3 Components", _upgrade_weapon)
    _label(right, "CARGO HOLD", 16, MUTED)
    for good: String in ["Water", "Food", "Components", "Rare Components"]:
        _label(right, "%s: %d" % [good, int(cargo.get(good, 0))], 16)
    _button(right, "Use a Component to restore 15 hull", _use_component)
    _button(right, "Back to cockpit", show_cockpit)
    _footer_button("COCKPIT", show_cockpit)
    _footer_button("MARKET", show_market)
    _footer_button("GALAXY", show_galaxy)
    _footer_button("MISSIONS", show_missions)

func _upgrade_hull() -> void:
    if credits >= 600 and components >= 2:
        credits -= 600
        components -= 2
        cargo_capacity += 2
        hull = min(hull + 20, 120)
        toast_message("Reinforced hull installed. Cargo capacity +2.")
        show_ship()
    else:
        toast_message("Need 600 CR and 2 Components.")

func _upgrade_engine() -> void:
    if credits >= 700 and components >= 2:
        credits -= 700
        components -= 2
        fuel = mini(fuel + 20, 100)
        toast_message("Engine Mk II installed. Fuel reserves topped up.")
        show_ship()
    else:
        toast_message("Need 700 CR and 2 Components.")

func _upgrade_weapon() -> void:
    if credits >= 800 and components >= 3:
        credits -= 800
        components -= 3
        toast_message("Coilgun Mk II installed. Primary weapon damage will improve in a later fitting pass.")
        show_ship()
    else:
        toast_message("Need 800 CR and 3 Components.")

func _use_component() -> void:
    if components <= 0:
        toast_message("No spare component.")
        return
    if hull >= 100:
        toast_message("Hull does not need repair.")
        return
    components -= 1
    hull = mini(hull + 15, 100)
    toast_message("Field repair complete.")
    show_ship()

func _repair_hull() -> void:
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
    _close_combat()
    _clear_content()
    screen = "missions"
    var left: VBoxContainer = _panel(content, Rect2(0, 0, 790, 540))
    _label(left, "CONTRACT BOARD", 22, CYAN)
    _label(left, "Work is the backbone of frontier life. Major story events emerge from it rather than replacing it.", 14, MUTED)
    _button(left, "ESCORT — Mining hauler to Kestrel", func() -> void: begin_combat("escort"))
    _button(left, "SALVAGE — Recover components from a derelict", _collect_salvage)
    _button(left, "BOUNTY — Pirate raider in the outer lane", func() -> void: begin_combat("pirate"))
    _button(left, "SURVEY — Chart a weak signal", begin_survey)
    var right: VBoxContainer = _panel(content, Rect2(810, 0, 422, 540))
    _label(right, "CONTRACT STATUS", 22, CYAN)
    _label(right, "Commonwealth: %d\nHelix: %d\nVeyran: %d\nFree Captains: %d" % [reputation["Commonwealth"], reputation["Helix"], reputation["Veyran"], reputation["Free Captains"]], 16)
    _label(right, "A captain's reputation is earned through actions, not a morality bar.", 14, MUTED)
    _footer_button("COCKPIT", show_cockpit)
    _footer_button("GALAXY", show_galaxy)
    _footer_button("SHIP", show_ship)
    _footer_button("MARKET", show_market)

func begin_survey() -> void:
    if story_flags["survey_found"]:
        toast_message("The survey mystery is already in your log.")
        return
    story_flags["survey_found"] = true
    data_fragments += 1
    reputation["Free Captains"] += 1
    _close_combat()
    _clear_content()
    var left: VBoxContainer = _panel(content, Rect2(0, 0, 790, 540))
    _label(left, "SALVAGE LOG / UNKNOWN SURVEY VESSEL", 22, CYAN)
    _label(left, "The vessel is old enough to have been presumed lost for years. Its crew are dead or missing. Most of the data core is corrupted.", 18)
    _label(left, "RECOVERED FRAGMENT", 16, MUTED)
    _label(left, "\"They are not where the records say they are.\"", 27, AMBER)
    _label(left, "This is not an answer. It is the first piece of a question.", 17)
    var right: VBoxContainer = _panel(content, Rect2(810, 0, 422, 540))
    _label(right, "NEW THREAD", 22, CYAN)
    _label(right, "A recognised system has been deliberately omitted from old survey records.", 18)
    _button(right, "Log the discovery", show_cockpit)
    _button(right, "Pursue the missing frontier", show_exploration)
    _footer_button("COCKPIT", show_cockpit)
    _footer_button("GALAXY", show_galaxy)
    _footer_button("MISSIONS", show_missions)
    _footer_button("CODEX", func() -> void: toast_message("Codex entry added: Missing Survey."))

func _collect_salvage() -> void:
    components += 2
    credits += 120
    toast_message("Salvage recovered: 2 Components + 120 CR.")
    show_ship()

func begin_combat(kind: String) -> void:
    _clear_content()
    screen = "combat"
    if combat != null:
        combat.queue_free()
    combat = FrontierCombat.new()
    combat.contract_kind = kind
    combat.player_hull = hull
    combat.player_max_hull = 100
    combat.combat_won.connect(_on_combat_won)
    combat.combat_lost.connect(_on_combat_lost)
    combat.combat_broken_off.connect(_on_combat_broken_off)
    root_ui.add_child(combat)
    combat.z_index = 20
    combat_break_button = Button.new()
    combat_break_button.text = "BREAK OFF"
    combat_break_button.position = Vector2(1110, 18)
    combat_break_button.size = Vector2(110, 42)
    combat_break_button.add_theme_font_size_override("font_size", 14)
    combat_break_button.z_index = 30
    combat_break_button.pressed.connect(func() -> void:
        if combat != null:
            combat.request_break_off()
    )
    root_ui.add_child(combat_break_button)

func _on_combat_won(reward_credits: int, reward_components: int) -> void:
    if combat == null:
        return
    hull = combat.player_hull
    credits += reward_credits
    components += reward_components
    reputation["Free Captains"] += 1
    if screen == "combat":
        toast_message("Contract complete. +%d CR, +%d Component." % [reward_credits, reward_components])
    _close_combat()
    show_missions()

func _on_combat_lost() -> void:
    if combat != null:
        hull = max(combat.player_hull, 1)
    _close_combat()
    toast_message("Contract failed. You limped away with %d hull." % hull)
    show_cockpit()

func _on_combat_broken_off() -> void:
    if combat != null:
        hull = max(combat.player_hull, 1)
    _close_combat()
    toast_message("You broke off the engagement.")
    show_missions()

func _close_combat() -> void:
    if combat_break_button != null:
        combat_break_button.queue_free()
        combat_break_button = null
    if combat != null:
        combat.queue_free()
        combat = null

func _cargo_total() -> int:
    var total: int = 0
    for value: Variant in cargo.values():
        total += int(value)
    return total

func toast_message(message: String) -> void:
    if toast == null:
        return
    toast.text = message
    var timer: SceneTreeTimer = get_tree().create_timer(3.0)
    timer.timeout.connect(func() -> void:
        if toast.text == message:
            toast.text = ""
    )
