package main

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

draw_finish_building_button :: proc() -> bool {
	gui_button_width: i32 = 300
	return rl.GuiButton(
		rl.Rectangle {
			x = f32(rl.GetScreenWidth() / 2 - (gui_button_width / 2)),
			y = f32(rl.GetScreenHeight() - rl.GetScreenHeight() / 10),
			width = f32(gui_button_width),
			height = 30,
		},
		"Finish Building",
	)
}

draw_place_modes_toggles :: proc(active_place_mode: ^i32) {
	rl.GuiToggleGroup(
		rl.Rectangle{x = 10, y = 10, height = 30, width = 120},
		"Walls\nStart\nFinish\nTreasure\nMonster\nTrap",
		active_place_mode,
	)
}

