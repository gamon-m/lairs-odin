package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

GRID_SIZE: int : 6
CELL_SIZE: f32 : 16
INSET: f32 : 2

WALL_LIMIT: int : 20
MONSTER_LIMIT: int : 3
TRAP_LIMIT: int : 3
TREASURE_LIMIT: int : 3
START_LIMIT: int : 1
FINISH_LIMIT: int : 1

Game_States :: enum u8 {
	Building,
	Playing,
}

Wall_Side :: enum u8 {
	North,
	South,
	East,
	West,
}

Cell_Type :: enum u8 {
	Start,
	Finish,
	Treasure,
	Monster,
	Trap,
	None,
}

Wall_Flags :: bit_set[Wall_Side;u8]

Space :: struct {
	walls:  Wall_Flags,
	type:   Cell_Type,
	hidden: bool,
}

Placed_Counts :: struct {
	Walls:     int,
	Monsters:  int,
	Treasures: int,
	Traps:     int,
	Starts:    int,
	Finishes:  int,
}

Placing_State :: enum u8 {
	Walls,
	Start,
	Finish,
	Treasure,
	Monster,
	Trap,
}

Position :: struct {
	x: int,
	y: int,
}

Lair :: struct {
	grid:          [GRID_SIZE][GRID_SIZE]Space,
	placed_counts: Placed_Counts,
	start_pos:     Position,
}

Player :: struct {
	position:       Position,
	visited_spaces: []Space,
}

game_state: Game_States = .Building

init_lair :: proc(lair: ^Lair) {
	for y in 0 ..< GRID_SIZE {
		for x in 0 ..< GRID_SIZE {
			cell := &lair.grid[y][x]
			cell.hidden = true
			cell.type = .None
		}
	}
	lair.start_pos = {
		x = -1,
		y = -1,
	}
}

init_player :: proc(player: ^Player, pos: Position) {
	player.position = pos
}

is_out_of_bounds :: proc(pos: Position) -> bool {
	if pos.x > GRID_SIZE - 1 || pos.y > GRID_SIZE - 1 || pos.x < 0 || pos.y < 0 {
		return true
	}
	return false
}

remove_wall :: proc(lair: ^Lair, pos: Position, side: Wall_Side) {
	if is_out_of_bounds(pos) {
		return
	}

	cell := &lair.grid[pos.y][pos.x]
	if side not_in cell.walls {
		return
	}
	cell.walls -= {side}
	lair.placed_counts.Walls -= 1

	adjacent_pos := get_adjacent_cell(pos, side)
	if is_out_of_bounds(adjacent_pos) {
		return
	}

	adjacent_wall := get_adjacent_wall(side)
	cell = &lair.grid[adjacent_pos.y][adjacent_pos.x]
	cell.walls -= {adjacent_wall}

}

place_wall :: proc(lair: ^Lair, pos: Position, side: Wall_Side) {
	if is_out_of_bounds(pos) {
		return
	}

	cell := &lair.grid[pos.y][pos.x]
	if side in cell.walls {
		return
	}

	cell.walls |= {side}
	lair.placed_counts.Walls += 1

	adjecent_pos := get_adjacent_cell(pos, side)
	if is_out_of_bounds(adjecent_pos) {
		return
	}

	adjecent_wall := get_adjacent_wall(side)
	cell = &lair.grid[adjecent_pos.y][adjecent_pos.x]
	cell.walls |= {adjecent_wall}
}

get_adjacent_cell :: proc(pos: Position, side: Wall_Side) -> Position {
	new_pos := pos

	switch side {
	case Wall_Side.North:
		new_pos.y -= 1
	case Wall_Side.South:
		new_pos.y += 1
	case Wall_Side.East:
		new_pos.x += 1
	case Wall_Side.West:
		new_pos.x -= 1
	}

	return new_pos
}

get_adjacent_wall :: proc(side: Wall_Side) -> Wall_Side {
	new_side: Wall_Side
	switch side {
	case Wall_Side.North:
		new_side = Wall_Side.South
	case Wall_Side.South:
		new_side = Wall_Side.North
	case Wall_Side.East:
		new_side = Wall_Side.West
	case Wall_Side.West:
		new_side = Wall_Side.East
	}

	return new_side
}

set_opposite_wall :: proc(lair: ^Lair, pos: Position, side: Wall_Side) {
	opposite_side: Wall_Side
	new_pos := pos


	if is_out_of_bounds(pos) {
		return
	}

	cell := &lair.grid[pos.y][pos.x]
	cell.walls |= {side}
}

has_wall :: proc(space: Space, side: Wall_Side) -> bool {
	return side in space.walls
}

get_cell_at_pos :: proc(pos: rl.Vector2) -> Position {
	if pos.x < 0 || pos.y < 0 {
		return {x = -1, y = -1}
	}

	x := pos.x / CELL_SIZE
	y := pos.y / CELL_SIZE

	return {x = int(x), y = int(y)}
}

find_closest_cells :: proc(pos: rl.Vector2, radius: f32) -> (Position, Wall_Side) {
	closest_cell := get_cell_at_pos(pos)
	cell_x := f32(closest_cell.x) * CELL_SIZE + INSET / 2
	cell_y := f32(closest_cell.y) * CELL_SIZE + INSET / 2

	distances: [4]f32
	distances[0] = pos.y - cell_y
	distances[1] = cell_y + CELL_SIZE - pos.y
	distances[2] = cell_x + CELL_SIZE - pos.x
	distances[3] = pos.x - cell_x

	smallest_distance_index: int = -1
	smallest_distance: f32 = 101

	for distance, index in distances {
		if smallest_distance_index == -1 {
			smallest_distance_index = index
		}

		if distance < smallest_distance {
			smallest_distance = distance
			smallest_distance_index = index
		}
	}

	if smallest_distance > radius {
		return {x = -1, y = -1}, nil
	}

	side: Wall_Side
	if smallest_distance_index == 0 {
		if closest_cell.y == 0 {
			side = nil
		} else {
			side = .North
		}
	} else if smallest_distance_index == 1 {
		if closest_cell.y == GRID_SIZE - 1 {
			side = nil
		} else {
			side = .South
		}
	} else if smallest_distance_index == 2 {
		if closest_cell.x == GRID_SIZE - 1 {
			side = nil
		} else {
			side = .East
		}
	} else if smallest_distance_index == 3 {
		if closest_cell.x == 0 {
			side = nil
		} else {
			side = .West
		}
	}

	return closest_cell, side
}

get_cell_type_from_place_state :: proc(state: Placing_State) -> Cell_Type {
	#partial switch state {
	case .Start:
		return .Start
	case .Finish:
		return .Finish
	case .Treasure:
		return .Treasure
	case .Monster:
		return .Monster
	case .Trap:
		return .Trap
	}
	return .None
}

add_type_count :: proc(lair: ^Lair, type: Cell_Type) {
	#partial switch type {
	case .Start:
		lair.placed_counts.Starts += 1
	case .Finish:
		lair.placed_counts.Finishes += 1
	case .Treasure:
		lair.placed_counts.Treasures += 1
	case .Monster:
		lair.placed_counts.Monsters += 1
	case .Trap:
		lair.placed_counts.Traps += 1
	}
}

subtract_type_count :: proc(lair: ^Lair, type: Cell_Type) {
	#partial switch type {
	case .Start:
		lair.placed_counts.Starts -= 1
	case .Finish:
		lair.placed_counts.Finishes -= 1
	case .Treasure:
		lair.placed_counts.Treasures -= 1
	case .Monster:
		lair.placed_counts.Monsters -= 1
	case .Trap:
		lair.placed_counts.Traps -= 1
	}
}

type_at_limit :: proc(lair: ^Lair, type: Cell_Type) -> bool {
	#partial switch type {
	case .Start:
		return lair.placed_counts.Starts >= START_LIMIT
	case .Finish:
		return lair.placed_counts.Finishes >= FINISH_LIMIT
	case .Treasure:
		return lair.placed_counts.Treasures >= TREASURE_LIMIT
	case .Monster:
		return lair.placed_counts.Monsters >= MONSTER_LIMIT
	case .Trap:
		return lair.placed_counts.Traps >= TRAP_LIMIT
	}
	return false
}

can_finish_building :: proc(lair: ^Lair) -> bool {

	return(
		lair.placed_counts.Finishes == FINISH_LIMIT &&
		lair.placed_counts.Monsters == MONSTER_LIMIT &&
		lair.placed_counts.Starts == START_LIMIT &&
		lair.placed_counts.Traps == TRAP_LIMIT &&
		lair.placed_counts.Treasures == TREASURE_LIMIT &&
		lair.placed_counts.Walls >= (WALL_LIMIT - 3) \
	)
}

main :: proc() {
	lair: Lair
	init_lair(&lair)

	player: Player
	init_player(&player, {-1, -1})

	screen_width :: 1280
	screen_height :: 720

	place_mode := Placing_State.Walls
	active_place_mode := i32(place_mode)

	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})

	rl.InitWindow(screen_width, screen_height, "Title")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	rl.SetExitKey(.ESCAPE)
	font := rl.LoadFont("fonts/PixelOperator.ttf")

	rl.GuiLoadStyle("styles/genesis.rgs")
	rl.GuiSetFont(font)

	dungeon_icons := rl.LoadTexture("assets/dungeon_icons.png")
	defer rl.UnloadTexture(dungeon_icons)

	camera := rl.Camera2D{}
	camera.target = {CELL_SIZE * f32(GRID_SIZE) / 2, CELL_SIZE * f32(GRID_SIZE) / 2}
	camera.offset = rl.Vector2{f32(rl.GetScreenWidth()) / 2.0, f32(rl.GetScreenHeight()) / 2.0}
	camera.zoom = 4

	mouse_pos: rl.Vector2
	world_pos: rl.Vector2

	fmt.println(player)

	for !rl.WindowShouldClose() {
		if rl.IsWindowResized() {
			scale_x := f32(rl.GetScreenWidth()) / f32(screen_width)
			scale_y := f32(rl.GetScreenHeight()) / f32(screen_height)
			scale: f32 = math.min(scale_x, scale_y)

			camera.zoom = scale * 4
			camera.offset = {f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)}
		}

		mouse_pos = rl.GetMousePosition()
		world_pos = rl.GetScreenToWorld2D(mouse_pos, camera)

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.WHITE)

		rl.BeginMode2D(camera)
		draw_grid(&lair, dungeon_icons)
		if game_state != .Building {
			draw_player(&player, dungeon_icons)
		}
		rl.EndMode2D()

		if game_state == .Building {
			draw_debug(&lair)
			handle_building_input(&lair, world_pos, &place_mode)
			active_place_mode = i32(place_mode)

			rl.GuiToggleGroup(
				rl.Rectangle{x = 10, y = 10, height = 30, width = 120},
				"Walls\nStart\nFinish\nTreasure\nMonster\nTrap",
				&active_place_mode,
			)

			place_mode = Placing_State(active_place_mode)

			if can_finish_building(&lair) {
				gui_button_width: i32 = 300
				if rl.GuiButton(
					rl.Rectangle {
						x = f32(rl.GetScreenWidth() / 2 - (gui_button_width / 2)),
						y = f32(rl.GetScreenHeight() - rl.GetScreenHeight() / 10),
						width = f32(gui_button_width),
						height = 30,
					},
					"Finish Building",
				) {
					game_state = .Playing
					init_player(&player, lair.start_pos)
				}
			}
		} else if game_state == .Playing {

		}
	}
}

