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
	Moving,
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
}

game_state: Game_States = .Building

get_sprite :: proc(index, columns, sprite_size: i32) -> rl.Rectangle {
	x := (index % columns) * sprite_size
	y := (index / columns) * sprite_size
	return rl.Rectangle {
		x = f32(x),
		y = f32(y),
		height = f32(sprite_size),
		width = f32(sprite_size),
	}
}

init_lair :: proc(lair: ^Lair) {
	for y in 0 ..< GRID_SIZE {
		for x in 0 ..< GRID_SIZE {
			cell := &lair.grid[y][x]
			cell.hidden = true
			cell.type = .None
		}
	}
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

draw_walls :: proc(cell: Space, x: f32, y: f32, size: f32) {
	if has_wall(cell, Wall_Side.North) {
		rl.DrawRectangleRec(
			rl.Rectangle{x = x, y = y - INSET / 2, width = size, height = INSET / 2},
			rl.BLACK,
		)
	}
	if has_wall(cell, Wall_Side.South) {
		rl.DrawRectangleRec(
			rl.Rectangle{x = x, y = y + size, width = size, height = INSET / 2},
			rl.BLACK,
		)
	}
	if has_wall(cell, Wall_Side.East) {
		rl.DrawRectangleRec(
			rl.Rectangle{x = x + size, y = y, width = INSET / 2, height = size},
			rl.BLACK,
		)
	}
	if has_wall(cell, Wall_Side.West) {
		rl.DrawRectangleRec(
			rl.Rectangle{x = x - INSET / 2, y = y, width = INSET / 2, height = size},
			rl.BLACK,
		)
	}
}

draw_corners :: proc(cell: Space, x: int, y: int, size: f32) {
	cell_start_x := f32(x) * CELL_SIZE + INSET
	cell_start_y := f32(y) * CELL_SIZE + INSET
	px := f32(x) * CELL_SIZE + (INSET / 2)
	py := f32(y) * CELL_SIZE + (INSET / 2)

	if (y != 0) {
		if (x != 0) {
			// top left
			rl.DrawRectangleRec(
				rl.Rectangle{x = px, y = py, width = INSET / 2, height = INSET / 2},
				rl.BLACK,
			)
		}
		if (x != GRID_SIZE - 1) {
			// top right
			rl.DrawRectangleRec(
				rl.Rectangle {
					x = cell_start_x + size,
					y = py,
					width = INSET / 2,
					height = INSET / 2,
				},
				rl.BLACK,
			)
		}
	}
	if (y != GRID_SIZE - 1) {
		if (x != 0) {
			// bottom left
			rl.DrawRectangleRec(
				rl.Rectangle {
					x = px,
					y = cell_start_y + size,
					width = INSET / 2,
					height = INSET / 2,
				},
				rl.BLACK,
			)
		}
		if (x != GRID_SIZE - 1) {
			// bottom right
			rl.DrawRectangleRec(
				rl.Rectangle {
					x = cell_start_x + size,
					y = cell_start_y + size,
					width = INSET / 2,
					height = INSET / 2,
				},
				rl.BLACK,
			)
		}
	}
}

draw_border :: proc() {
	rl.DrawRectangleLinesEx(
		rl.Rectangle {
			x = 0,
			y = 0,
			height = CELL_SIZE * f32(GRID_SIZE) + INSET,
			width = CELL_SIZE * f32(GRID_SIZE) + INSET,
		},
		INSET,
		rl.BLACK,
	)
}

draw_cell_type :: proc(cell: Space, pos_x, pos_y: f32, sheet: rl.Texture) {
	columns: i32 = 3
	sprite_size: i32 = 16
	source: rl.Rectangle

	if cell.type != .None {
		source = get_sprite(i32(cell.type), columns, sprite_size)
		rl.DrawTexturePro(
			sheet,
			source,
			rl.Rectangle {
				x = pos_x,
				y = pos_y,
				width = f32(sprite_size),
				height = f32(sprite_size),
			},
			{1, 1},
			0,
			rl.WHITE,
		)
	}
}

draw_grid :: proc(lair: ^Lair, sheet: rl.Texture) {
	line_thickness: f32 : 1

	for y in 0 ..< GRID_SIZE {
		for x in 0 ..< GRID_SIZE {
			cell := lair.grid[y][x]

			pos_x: f32 = f32(x) * CELL_SIZE + INSET
			pos_y: f32 = f32(y) * CELL_SIZE + INSET
			size: f32 = f32(CELL_SIZE - INSET)

			rl.DrawRectangleLinesEx(
				rl.Rectangle{height = size, width = size, x = pos_x, y = pos_y},
				line_thickness,
				rl.BEIGE,
			)

			draw_cell_type(cell, pos_x, pos_y, sheet)
			draw_walls(cell, pos_x, pos_y, size)
			draw_corners(cell, x, y, size)
			draw_border()
		}
	}
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

draw_debug :: proc(lair: ^Lair) {
	x := f32(rl.GetScreenWidth() - 200)
	y := f32(rl.GetScreenHeight() - 150)
	rl.DrawText(
		rl.TextFormat("Walls: %d/%d", lair.placed_counts.Walls, WALL_LIMIT),
		i32(x),
		i32(y),
		20,
		rl.DARKGRAY,
	)
	rl.DrawText(
		rl.TextFormat("Starts: %d/%d", lair.placed_counts.Starts, START_LIMIT),
		i32(x),
		i32(y + 20),
		20,
		rl.DARKGRAY,
	)
	rl.DrawText(
		rl.TextFormat("Finishes: %d/%d", lair.placed_counts.Finishes, FINISH_LIMIT),
		i32(x),
		i32(y + 40),
		20,
		rl.DARKGRAY,
	)
	rl.DrawText(
		rl.TextFormat("Treasures: %d/%d", lair.placed_counts.Treasures, TREASURE_LIMIT),
		i32(x),
		i32(y + 60),
		20,
		rl.DARKGRAY,
	)
	rl.DrawText(
		rl.TextFormat("Monsters: %d/%d", lair.placed_counts.Monsters, MONSTER_LIMIT),
		i32(x),
		i32(y + 80),
		20,
		rl.DARKGRAY,
	)
	rl.DrawText(
		rl.TextFormat("Traps: %d/%d", lair.placed_counts.Traps, TRAP_LIMIT),
		i32(x),
		i32(y + 100),
		20,
		rl.DARKGRAY,
	)
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
		rl.EndMode2D()

		draw_debug(&lair)

		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			if place_mode == .Walls {
				if lair.placed_counts.Walls < WALL_LIMIT {
					new_cell, side := find_closest_cells(world_pos, 2.0)
					if new_cell.x != -1 || new_cell.y != -1 || side != nil {
						place_wall(&lair, new_cell, side)
					}
				}
			} else {
				cell_pos := get_cell_at_pos(world_pos)
				if !is_out_of_bounds({x = cell_pos.x, y = cell_pos.y}) {
					cell := &lair.grid[cell_pos.y][cell_pos.x]
					cell_type := get_cell_type_from_place_state(place_mode)

					if cell.type == .None && !type_at_limit(&lair, cell_type) {
						cell.type = cell_type
						add_type_count(&lair, cell_type)
					}

				}
			}
		}
		if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
			if place_mode == .Walls {
				new_cell, side := find_closest_cells(world_pos, 2.0)
				if new_cell.x != -1 || new_cell.y != -1 || side != nil {
					remove_wall(&lair, new_cell, side)
				}
			} else {
				cell_pos := get_cell_at_pos(world_pos)
				if !is_out_of_bounds({x = cell_pos.x, y = cell_pos.y}) {
					cell := &lair.grid[cell_pos.y][cell_pos.x]
					cell_type := get_cell_type_from_place_state(place_mode)
					if cell.type == cell_type {
						cell.type = .None
						subtract_type_count(&lair, cell_type)
					}
				}
			}
		}

		if rl.IsKeyPressed(rl.KeyboardKey.ONE) {
			place_mode = .Walls
		} else if rl.IsKeyPressed(rl.KeyboardKey.TWO) {
			place_mode = .Start
		} else if rl.IsKeyPressed(rl.KeyboardKey.THREE) {
			place_mode = .Finish
		} else if rl.IsKeyPressed(rl.KeyboardKey.FOUR) {
			place_mode = .Treasure
		} else if rl.IsKeyPressed(rl.KeyboardKey.FIVE) {
			place_mode = .Monster
		} else if rl.IsKeyPressed(rl.KeyboardKey.SIX) {
			place_mode = .Trap
		}
		active_place_mode = i32(place_mode)

		if game_state == .Building {
			rl.GuiToggleGroup(
				rl.Rectangle{x = 10, y = 10, height = 30, width = 120},
				"Walls\nStart\nFinish\nTreasure\nMonster\nTrap",
				&active_place_mode,
			)
		}

		place_mode = Placing_State(active_place_mode)

		if can_finish_building(&lair) && game_state == .Building {
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
				game_state = .Moving
			}
		}
	}
}

