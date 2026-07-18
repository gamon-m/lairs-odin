package main

import "core:math"
import rl "vendor:raylib"

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

is_out_of_bounds :: proc(pos: Position) -> bool {
	if pos.x > GRID_SIZE - 1 || pos.y > GRID_SIZE - 1 || pos.x < 0 || pos.y < 0 {
		return true
	}
	return false
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

test_board :: proc(lair: ^Lair, player: ^Player) {
	game_state = .Playing

	place_wall(lair, {0, 0}, .East)
	place_wall(lair, {0, 1}, .East)
	place_wall(lair, {0, 2}, .East)
	place_wall(lair, {0, 3}, .East)
	place_wall(lair, {0, 4}, .East)
	place_wall(lair, {2, 0}, .East)
	place_wall(lair, {1, 1}, .East)
	place_wall(lair, {4, 1}, .East)
	place_wall(lair, {1, 1}, .South)
	place_wall(lair, {2, 1}, .South)
	place_wall(lair, {3, 1}, .South)
	place_wall(lair, {5, 1}, .South)
	place_wall(lair, {2, 2}, .South)
	place_wall(lair, {3, 2}, .South)
	place_wall(lair, {4, 2}, .South)
	place_wall(lair, {5, 2}, .South)
	place_wall(lair, {1, 3}, .South)
	place_wall(lair, {2, 3}, .South)
	place_wall(lair, {4, 3}, .South)
	place_wall(lair, {5, 3}, .South)

	lair.grid[0][0].type = .Monster
	lair.grid[1][1].type = .Monster
	lair.grid[0][4].type = .Monster
	lair.grid[1][2].type = .Finish
	lair.grid[1][5].type = .Treasure
	lair.grid[3][0].type = .Treasure
	lair.grid[3][4].type = .Treasure
	lair.grid[4][0].type = .Trap
	lair.grid[4][3].type = .Trap
	lair.grid[5][2].type = .Trap
	lair.grid[4][1].type = .Start

	lair.start_pos = {1, 4}
	lair.grid[4][1].hidden = false
	lair.finish_pos = {2, 1}
	player.position = lair.start_pos
}

cell_position_at_mouse :: proc(world_pos: rl.Vector2) -> Position {
	local_x := math.mod(world_pos.x, CELL_SIZE)
	local_y := math.mod(world_pos.y, CELL_SIZE)

	inside_cell :=
		local_x >= INSET &&
		local_x < CELL_SIZE - INSET &&
		local_y >= INSET &&
		local_y < CELL_SIZE - INSET

	if !inside_cell {
		return {-1, -1}
	}

	pos_x := int(world_pos.x / CELL_SIZE)
	pos_y := int(world_pos.y / CELL_SIZE)

	pos: Position = {pos_x, pos_y}

	if is_out_of_bounds(pos) {
		return {-1, -1}
	}

	return pos
}

