module cell;

import raylib;

struct Cell {
	bool alive;
	Color color;
	Vector2 pos;
	Vector2 size;

	this(int x, int y, int cellSize, Color cellColor) {
		import std.random: uniform;

		alive = cast(bool)(uniform(0, 2));
		color = cellColor;
		pos = Vector2(x * cellSize, y * cellSize);
		size = Vector2(cellSize, cellSize);
	}

	void draw() {
		DrawRectangleV(pos, size, color);
	}
}
