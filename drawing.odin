package main

import "core:fmt"
import rl "vendor:raylib"

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

draw_walls :: proc(cell: Space, grid_x, grid_y: int, px: f32, py: f32) {
	if has_wall(cell, Wall_Side.North) {
		draw_north_wall(px, py)
		new_cell := get_adjacent_cell({x = grid_x, y = grid_y}, .North)
		draw_south_wall(f32(new_cell.x) * CELL_SIZE + INSET, f32(new_cell.y) * CELL_SIZE + INSET)
	}
	if has_wall(cell, Wall_Side.South) {
		draw_south_wall(px, py)
		new_cell := get_adjacent_cell({x = grid_x, y = grid_y}, .South)
		draw_north_wall(f32(new_cell.x) * CELL_SIZE + INSET, f32(new_cell.y) * CELL_SIZE + INSET)
	}
	if has_wall(cell, Wall_Side.East) {
		draw_east_wall(px, py)
		new_cell := get_adjacent_cell({x = grid_x, y = grid_y}, .East)
		draw_west_wall(f32(new_cell.x) * CELL_SIZE + INSET, f32(new_cell.y) * CELL_SIZE + INSET)
	}
	if has_wall(cell, Wall_Side.West) {
		draw_west_wall(px, py)
		new_cell := get_adjacent_cell({x = grid_x, y = grid_y}, .West)
		draw_east_wall(f32(new_cell.x) * CELL_SIZE + INSET, f32(new_cell.y) * CELL_SIZE + INSET)
	}
}

draw_north_wall :: proc(x, y: f32) {
	rl.DrawRectangleRec(
		rl.Rectangle{x = x, y = y - INSET / 2, width = SIZE, height = INSET / 2},
		rl.BLACK,
	)
}

draw_south_wall :: proc(x, y: f32) {
	rl.DrawRectangleRec(
		rl.Rectangle{x = x, y = y + SIZE, width = SIZE, height = INSET / 2},
		rl.BLACK,
	)
}

draw_east_wall :: proc(x, y: f32) {
	rl.DrawRectangleRec(
		rl.Rectangle{x = x + SIZE, y = y, width = INSET / 2, height = SIZE},
		rl.BLACK,
	)
}

draw_west_wall :: proc(x, y: f32) {
	rl.DrawRectangleRec(
		rl.Rectangle{x = x - INSET / 2, y = y, width = INSET / 2, height = SIZE},
		rl.BLACK,
	)
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

draw_hidden_cell :: proc(pos_x, pos_y: f32, sheet: rl.Texture) {
	columns: i32 = 3
	sprite_size: i32 = 16
	source := get_sprite(6, columns, sprite_size)
	rl.DrawTexturePro(
		sheet,
		source,
		rl.Rectangle{x = pos_x, y = pos_y, width = f32(sprite_size), height = f32(sprite_size)},
		{1, 1},
		0,
		rl.WHITE,
	)
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

			if game_state == .Playing {
				if !cell.hidden {
					draw_walls(cell, x, y, pos_x, pos_y)
					draw_cell_type(cell, pos_x, pos_y, sheet)
				} else {
					draw_hidden_cell(pos_x, pos_y, sheet)
				}
			} else {
				draw_cell_type(cell, pos_x, pos_y, sheet)
			}
			draw_corners(cell, x, y, size)
			draw_border()


		}
	}
}

draw_player :: proc(player: ^Player, sheet: rl.Texture) {
	start_x: f32 = f32(player.position.x) * CELL_SIZE + INSET
	start_y: f32 = f32(player.position.y) * CELL_SIZE + INSET

	columns: i32 : 3
	sprite_size: i32 : 16
	source: rl.Rectangle

	source = get_sprite(5, columns, sprite_size)
	rl.DrawTexturePro(
		sheet,
		source,
		rl.Rectangle {
			x = start_x,
			y = start_y,
			width = f32(sprite_size),
			height = f32(sprite_size),
		},
		{1, 1},
		0,
		rl.WHITE,
	)

}

draw_debug :: proc(lair: ^Lair) {
	x := f32(screen_width - 200)
	y := f32(screen_height - 150)
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

draw_collected_debug :: proc(player: ^Player) {
	x := f32(screen_width - 200)
	y := f32(screen_height - 100)
	rl.DrawText(
		rl.TextFormat("Treasures: %d", player.collected.Treasures),
		i32(x),
		i32(y),
		20,
		rl.DARKGRAY,
	)
	rl.DrawText(
		rl.TextFormat("Monsters: %d", player.collected.Monsters),
		i32(x),
		i32(y + 20),
		20,
		rl.DARKGRAY,
	)
	rl.DrawText(
		rl.TextFormat("Traps: %d", player.collected.Traps),
		i32(x),
		i32(y + 40),
		20,
		rl.DARKGRAY,
	)
}

draw_finish_building_button :: proc() -> bool {
	gui_button_width: i32 = 300
	return rl.GuiButton(
		rl.Rectangle {
			x = f32(screen_width / 2 - (gui_button_width / 2)),
			y = f32(screen_height - screen_height / 10),
			width = f32(gui_button_width),
			height = 30,
		},
		"Finish Building",
	)
}

draw_end_turn_button :: proc(player: ^Player) -> bool {
	count_fresh := 0
	for i in 0 ..< len(player.cubes) {
		if player.cubes[i].stage == .Fresh {
			count_fresh += 1
		}
	}

	gui_button_width: i32 = 300
	gui_button_text: cstring = "End Turn"
	if count_fresh > 0 {
		gui_button_text = "Conserve & End Turn"
	}

	if count_fresh > 3 {
		return false
	}

	return rl.GuiButton(
		rl.Rectangle {
			x = f32(screen_width / 2 - (gui_button_width / 2)),
			y = f32(screen_height - screen_height / 10),
			width = f32(gui_button_width),
			height = 30,
		},
		gui_button_text,
	)
}

draw_stop_backtrack_button :: proc() -> bool {
	gui_button_width: i32 = 300
	return rl.GuiButton(
		rl.Rectangle {
			x = f32(screen_width / 2 - (gui_button_width / 2)),
			y = f32(screen_height - screen_height / 10 - 50),
			width = f32(gui_button_width),
			height = 30,
		},
		"Stop Backtrack",
	)
}

draw_stop_peer_button :: proc() -> bool {
	gui_button_width: i32 = 300
	return rl.GuiButton(
		rl.Rectangle {
			x = f32(screen_width / 2 - (gui_button_width / 2)),
			y = f32(screen_height - screen_height / 10 - 50),
			width = f32(gui_button_width),
			height = 30,
		},
		"Stop Peer",
	)
}

draw_turn_count :: proc(player: ^Player) {
	font_size: i32 = 20
	text := rl.TextFormat("Turn: %d", player.turn)
	text_width := rl.MeasureText(text, font_size)
	x := f32(screen_width / 2 - text_width / 2)
	y := f32(screen_height - screen_height / 10 - 40)
	rl.DrawText(text, i32(x), i32(y), font_size, rl.BLACK)
}

draw_hustle_count :: proc(player: ^Player) {
	font_size: i32 = 20
	text := rl.TextFormat("Hustle moves: %d", player.hustle_remaining)
	text_width := rl.MeasureText(text, font_size)
	x := f32(screen_width / 2 - text_width / 2)
	y := f32(screen_height - screen_height / 10 - 70)
	rl.DrawText(text, i32(x), i32(y), font_size, rl.BLACK)
}

draw_move_mode_locked :: proc(move_mode: Move_Type) {
	rl.DrawText(rl.TextFormat("Locked: %v", move_mode), 10, 10, 20, rl.DARKGRAY)
}

draw_place_modes_toggles :: proc(active_place_mode: ^i32) {
	rl.GuiToggleGroup(
		rl.Rectangle{x = 10, y = 10, height = 30, width = 150},
		"Walls\nStart\nFinish\nTreasure\nMonster\nTrap",
		active_place_mode,
	)
}

draw_move_type_toggles :: proc(move_type: ^i32) {
	rl.GuiToggleGroup(
		rl.Rectangle{x = 10, y = 10, height = 30, width = 150},
		"Creep\nHustle\nBacktrack\nPeer",
		move_type,
	)
}

draw_win_screen :: proc() {
	x := screen_width / 2 - 50
	y := screen_height / 6

	rl.DrawText("You Win!", x, y, 32, rl.BLACK)
}

draw_highlight_cell :: proc(pos: Position, is_hovered: bool) {
	x := f32(pos.x) * CELL_SIZE + INSET
	y := f32(pos.y) * CELL_SIZE + INSET

	rl.DrawRectangleRec(
		rl.Rectangle{x = x, y = y, width = SIZE, height = SIZE},
		rl.Color{0, 255, 0, 40},
	)

	if is_hovered {
		rl.DrawRectangleRec(
			rl.Rectangle{x = x, y = y, width = SIZE, height = SIZE},
			rl.Color{0, 255, 0, 80},
		)
	}
}

draw_peer_target_highlight :: proc(player: ^Player, hovered_position: Position) {
	draw_highlight_cell(player.peer_position, player.peer_position == hovered_position)
}

draw_legal_moves :: proc(
	player: ^Player,
	lair: ^Lair,
	hovered_position: Position,
	move_type: Move_Type,
) {
	player_position := player.position

	directions := [4]rl.Vector2{{0, -1}, {0, 1}, {1, 0}, {-1, 0}}

	for direction in directions {
		if is_move_legal(lair, player_position, direction, move_type) {
			new_pos := Position {
				x = player_position.x + int(direction.x),
				y = player_position.y + int(direction.y),
			}
			draw_highlight_cell(new_pos, new_pos == hovered_position)
		}
	}
}

draw_cube_inventory :: proc(cubes: [6]Cube) {
	stage_order := [4]Cube_Stage{.Conserved, .Fresh, .Spent, .Fatigued}
	type_order := [3]Cube_Type{.Normal, .Energy, .Vision}

	Y_SPACING: i32 = 40

	stages := [Cube_Stage][dynamic]Cube_Type{}
	for cube in cubes {
		append(&stages[cube.stage], cube.type)
	}

	line_count: i32 = len(stage_order)
	total_height: i32 = line_count * Y_SPACING
	start_y := screen_height - total_height - 20

	for i in 0 ..< line_count {
		draw_cube_stage(stages[Cube_Stage(i)], i, start_y)
	}

}

draw_cube_stage :: proc(cubes: [dynamic]Cube_Type, stage: i32, start_y: i32) {
	Y_SPACING: i32 = 40
	Y_POS := start_y + stage * Y_SPACING
	CUBE_Y: f32 = 20 + f32(Y_POS)


	stage_title := Cube_Stage(stage)
	rl.DrawText(rl.TextFormat("%v", stage_title), 20, Y_POS, 20, rl.BLACK)
	for type, i in cubes {
		draw_cube(type, i, CUBE_Y)
	}
}

draw_cube :: proc(type: Cube_Type, index: int, pos_y: f32) {
	START_X: f32 = 20
	SIZE: f32 = 16
	X_OFFSET: f32 = 4

	POS_X: f32 = START_X + ((SIZE + X_OFFSET) * f32(index))

	colour: rl.Color
	switch type {
	case .Normal:
		colour = rl.GRAY
	case .Energy:
		colour = rl.ORANGE
	case .Vision:
		colour = rl.GREEN
	}

	rl.DrawRectangleRec(rl.Rectangle{x = POS_X, y = pos_y, width = SIZE, height = SIZE}, colour)
}

