package main

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

Collected_Counts :: struct {
	Monsters:  int,
	Treasures: int,
	Traps:     int,
}

Placing_State :: enum u8 {
	Walls,
	Start,
	Finish,
	Treasure,
	Monster,
	Trap,
}

Cube_Type :: enum u8 {
	Normal,
	Energy,
	Vision,
}

Cube_Stage :: enum u8 {
	Conserved,
	Fresh,
	Spent,
	Fatigued,
}

Cube :: struct {
	type:  Cube_Type,
	stage: Cube_Stage,
}

Move_Type :: enum i32 {
	Creep,
	Hustle,
	Backtrack,
	Peer,
}

Position :: struct {
	x: int,
	y: int,
}

Lair :: struct {
	grid:          [GRID_SIZE][GRID_SIZE]Space,
	placed_counts: Placed_Counts,
	start_pos:     Position,
	finish_pos:    Position,
}

Player :: struct {
	position:         Position,
	collected:        Collected_Counts,
	cubes:            [6]Cube,
	turn:             int,
	hustle_remaining: int,
	backtrack_active: bool,
	peer_position:    Position,
}

