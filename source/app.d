module app;

import raylib;
import cell;

import std.conv: to;
import std.math: floor;
import std.random: uniform;

// constants
immutable fps = 10;
immutable width = 1080;
immutable height = 720;
immutable cellSize = 30;
immutable gridWidth = width/cellSize;
immutable gridHeight = height/cellSize;

void main() {
	// init window
	InitWindow(width, height, "Conway's Game Of Life");
	SetTargetFPS(fps);

	// set up
	Cell[gridWidth][gridHeight] cells = randomizeCells(Color(0, 0, 0, 255));

	bool pauseGame = false;
	while(!WindowShouldClose()) {
		// PROCESS EVENTS
		if(IsKeyPressed(KeyboardKey.KEY_SPACE)) {
			pauseGame = !pauseGame;
		}

		// get mouse position
		Vector2 mpos = GetMousePosition();
		int mouseX = (mpos.x / cellSize).to!int;
		int mouseY = (mpos.y / cellSize).to!int;

		// add/remove cells
		if(pauseGame && IsMouseButtonPressed(MouseButton.MOUSE_LEFT_BUTTON)) {
			cells[mouseY][mouseX].alive = !cells[mouseY][mouseX].alive;
		}

		// remove all cells
		if(pauseGame && IsKeyPressed(KeyboardKey.KEY_C)) {
			foreach(int i, ref row; cells) {
				foreach(int j, ref cell; row) {
					cell.alive = false;
				}
			}
		}

		// randomize cells
		if(pauseGame && IsKeyPressed(KeyboardKey.KEY_R)) {
			cells = randomizeCells(randomizeColor());
		}

		// UPDATE GAME LOGIC
		if(!pauseGame) {
			update(cells);
		}

		// RENDER
		BeginDrawing();
		ClearBackground(Colors.RAYWHITE);

		// draw cells
		foreach(i, row; cells) {
			foreach(j, cell; row) {
				if(cell.alive) {
					cell.draw();
				}

				// draw mouse cursor block
				if(j == mouseX && i == mouseY && pauseGame) {
					DrawRectangleRounded(Rectangle(cell.pos.x, cell.pos.y, cell.size.x, cell.size.y), 0.24, 0, Color(100, 255, 100, 200));
				}
			}
		}

		// draw paused game menu
		if(pauseGame) {
			DrawRectangleRounded(Rectangle(width/2-200, height/3-60, 400, 120), 1, 0, Color(255, 255, 255, 225));
			DrawRectangleRoundedLines(Rectangle(width/2-200, height/3-60, 400, 120), 1, 0, 3, Color(0, 0, 0, 225));
			DrawText("GAME PAUSED", width/2-170, height/3-20, 48, Color(255, 140, 0, 245));
			DrawText("EDIT MODE", width/2-60, height/3+30, 21, Color(255, 140, 0, 245));

			DrawRectangleRounded(Rectangle(width/2-120, height/3+90, 240, 60), 0.5, 0, Color(255, 255, 255, 225));
			DrawRectangleRoundedLines(Rectangle(width/2-120, height/3+90, 240, 60), 0.5, 0, 3, Color(0, 0, 0, 225));
			DrawText("(C)LEAR", width/2-65, height/3+105, 32, Color(0, 0, 255, 165));

			DrawRectangleRounded(Rectangle(width/2-120, height/3+180, 240, 60), 0.5, 0, Color(255, 255, 255, 225));
			DrawRectangleRoundedLines(Rectangle(width/2-120, height/3+180, 240, 60), 0.5, 0, 3, Color(0, 0, 0, 225));
			DrawText("(R)ANDOMIZE", width/2-110, height/3+195, 32, Color(0, 0, 255, 165));
		}

		DrawFPS(10, 10);
		EndDrawing();
	}
}

auto randomizeCells(Color color) {
	Cell[gridWidth][gridHeight] cells;
	foreach(int i, ref rows; cells) {
		foreach(int j, ref cell; rows) {
			cell = Cell(j, i, cellSize, color);
		}
	}

	return cells;
}

Color randomizeColor(const ubyte alpha = 255) {
	return Color(uniform(0, 255).to!ubyte, uniform(0, 255).to!ubyte, uniform(0, 255).to!ubyte, alpha);
}

void update(T)(ref T currentGeneration) {
	auto nextGeneration = currentGeneration;
	foreach(int i, ref rows; currentGeneration) {
		foreach(int j, ref cell; rows) {
			// count neighbours
			int neighbours = countNeighbours(currentGeneration, i, j);

			// apply rules
			if(!cell.alive && neighbours == 3) {
				nextGeneration[i][j].alive = true;
			} else if(cell.alive && (neighbours < 2 || neighbours > 3)) {
				nextGeneration[i][j].alive = false;
			} else {
				nextGeneration[i][j].alive = cell.alive;
			}
		}
	}

	currentGeneration = nextGeneration;
}

int countNeighbours(T)(T cells, int i, int j) {
	int neighbours = 0;

	/+
	bool cmin = j - 1 > 0;
	bool cmax = j + 1 < gridWidth;
	bool rmin = i - 1 > 0;
	bool rmax = i + 1 < gridHeight;

	/* We scan a 3x3 sub-matrix from our cells' grid

		row/col
			  (j-1)   (j)   (j+1)
		(i-1)  []     []     []
		(i)    []     []     []
		(i+1)  []     []     []
	*/

	// (i-1) row
	if(rmin) {
		// j-th column
		if(cells[i - 1][j].alive) {
			neighbours++;
		}

		// (j-1) column
		if(cmin && cells[i - 1][j - 1].alive) {
			neighbours++;
		}

		// (j+1) column
		if(cmax && cells[i - 1][j + 1].alive) {
			neighbours++;
		}
	}

	// i-th row, (j-1) column
	if(cmin && cells[i][j - 1].alive) {
		neighbours++;
	}

	// i-th row, (j+1) column
	if(cmax && cells[i][j + 1].alive) {
		neighbours++;
	}

	// i-th row, j-th column
	// !!! Here we do not count the (i, j)-th position, since it's where the current cell is located

	// (i+1) row
	if(rmax) {
		// j-th column
		if(cells[i + 1][j].alive) {
			neighbours++;
		}

		// (j-1) column
		if(cmin && cells[i + 1][j - 1].alive) {
			neighbours++;
		}

		// (j+1) column
		if(cmax && cells[i + 1][j + 1].alive) {
			neighbours++;
		}
	}
	+/

	/*
		This is an improvement to the countNeighbours function 
			proposed by Steven Schveighoffer.

		It is the same process as done previously with multiple ifs statements.
	*/
	bool hasNeighbour(int ni, int nj) {
		// off the board 
		if(ni < 0 || nj < 0 || ni >= gridHeight || nj >= gridWidth)  {
			return false; 
		}

		return cells[ni][nj].alive;
	}

	// count live cells
	foreach(di; -1 .. 2) {
		foreach(dj; -1 .. 2) {
			if(hasNeighbour(i + di, j + dj)) {
				++neighbours;
			}
		}
	}
	
	// subtract the current cell if it's alive, since it is included in the loop above.
	if(cells[i][j].alive) {
		--neighbours;
	}

	return neighbours;
}









