package main

import rl "vendor:raylib"

is_move_legal :: proc(lair: ^Lair, pos: Position, dir: rl.Vector2) -> bool {
	pos_vector := rl.Vector2{f32(pos.x), f32(pos.y)}
	new_pos_vector := pos_vector + dir
	new_pos: Position = {int(new_pos_vector.x), int(new_pos_vector.y)}
	if is_out_of_bounds(new_pos) {
		return false
	}

	wall_in_way: bool = false
	cell := lair.grid[pos.y][pos.x]

	switch dir {
	case {0, 1}:
		wall_in_way = has_wall(cell, .South)
	case {0, -1}:
		wall_in_way = has_wall(cell, .North)
	case {1, 0}:
		wall_in_way = has_wall(cell, .East)
	case {-1, 0}:
		wall_in_way = has_wall(cell, .West)
	case:
		return false
	}

	return !wall_in_way
}

move_player :: proc(player: ^Player, dir: rl.Vector2) {
	current_position := player.position
	position_vector := rl.Vector2{f32(current_position.x), f32(current_position.y)}

	new_position_vector := position_vector + dir
	new_position: Position = {
		x = int(new_position_vector.x),
		y = int(new_position_vector.y),
	}

	player.position = new_position
}

is_win :: proc(lair: ^Lair, player: ^Player) -> bool {
	win_condition: bool = false
	if player.collected.Monsters == 3 ||
	   player.collected.Treasures == 3 ||
	   (player.collected.Monsters == 2 && player.collected.Treasures == 2) {
		win_condition = true
	}

	if win_condition && player.position == lair.finish_pos {
		return true
	} else {
		return false
	}
}

get_direction_from_player :: proc(player: ^Player, position: Position) -> rl.Vector2 {
	player_pos := rl.Vector2{f32(player.position.x), f32(player.position.y)}
	current_pos := rl.Vector2{f32(position.x), f32(position.y)}

	return player_pos - current_pos
}

handle_cost :: proc(player: ^Player, move_mode: Move_Type) {
	available_cubes := get_available_cubes(player)
	#partial switch move_mode {
	case .Creep:
		use_cubes(available_cubes, 1, .Normal)
	case .Hustle:
		if count_available_cubes(available_cubes, .Energy) > 0 {
			use_cubes(available_cubes, 1, .Energy)
		} else {
			use_cubes(available_cubes, 2, .Normal)
		}
	case .Backtrack:
		use_cubes(available_cubes, 1, .Energy)
	case .Peer:
		if count_available_cubes(available_cubes, .Vision) > 0 {
			use_cubes(available_cubes, 1, .Vision)
		} else {
			use_cubes(available_cubes, 2, .Normal)
		}
	case .Conserve:
	}
}

can_afford :: proc(player: ^Player, move_mode: Move_Type) -> bool {
	available_cubes := get_available_cubes(player)
	normal_cubes, vision_cubes, energy_cubes: int
	for cube in available_cubes {
		switch cube.type {
		case .Normal:
			normal_cubes += 1
		case .Vision:
			vision_cubes += 1
		case .Energy:
			energy_cubes += 1
		}
	}

	switch move_mode {
	case .Creep:
		if normal_cubes > 0 {
			return true
		}
	case .Hustle:
		if normal_cubes >= 2 || energy_cubes > 0 {
			return true
		}
	case .Backtrack:
		if energy_cubes > 0 {
			return true
		}
	case .Peer:
		if vision_cubes > 0 || normal_cubes >= 2 {
			return true
		}
	case .Conserve:
		if energy_cubes > 0 || vision_cubes > 0 || normal_cubes > 0 {
			return true
		}
	}
	return false
}

get_available_cubes :: proc(player: ^Player) -> [dynamic]^Cube {
	available_cubes: [dynamic]^Cube
	for i in 0 ..< len(player.cubes) {
		if player.cubes[i].stage != .Spent && player.cubes[i].stage != .Fatigued {
			append(&available_cubes, &player.cubes[i])
		}
	}
	return available_cubes
}

use_cubes :: proc(cubes: [dynamic]^Cube, amount: int, type: Cube_Type) {
	used: int = 0
	for cube in cubes {
		if used >= amount {
			break
		}
		if cube.type == type {
			if cube.stage == .Conserved {
				cube.stage = .Fresh
			} else if cube.stage == .Fresh {
				cube.stage = .Spent
			}
			used += 1
		}
	}
}

count_available_cubes :: proc(cubes: [dynamic]^Cube, type: Cube_Type) -> int {
	count: int
	for cube in cubes {
		if cube.type == type {
			count += 1
		}
	}
	return count
}

