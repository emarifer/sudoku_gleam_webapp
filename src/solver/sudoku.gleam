import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import gleam_community/maths
import solver/helpers.{type Grid, GridErr, GridOk, get_list_from_dict}

pub type Data =
  #(dict.Dict(String, List(List(String))), dict.Dict(String, List(String)))

// HARDS SUDOKU:
// const inkala_sudoku = "8..........36......7..9.2...5...7.......457.....1...3...1....68..85...1..9....4.."
// const exocet_sudoku = "......7....71.9...68..7..1...1.9.6.....3...2..4......3..8.6.1..5......4......2..5"
// const escargot_sudoku = "1....7.9..3..2...8..96..5....53..9...1..8...26....4...3......1..4......7..7...3.."

pub fn solver(puzzle: String) -> #(List(String), List(String), String) {
  let squares = helpers.cross(helpers.rows, helpers.cols)
  let initial_grid = helpers.generate_grid(squares, helpers.digits)
  let unitslist = helpers.units_list(helpers.rows, helpers.cols)
  let units = helpers.units(squares, unitslist)
  let peers = helpers.peers(squares, units)
  let dt: Data = #(units, peers)

  let t1 = timestamp.system_time()

  let sudoku_solved =
    puzzle
    |> solve(squares, initial_grid, dt)
    |> helpers.display_sudoku(squares)

  let t2 = timestamp.system_time()

  let time =
    timestamp.difference(t1, t2)
    |> duration.to_seconds
    |> float.to_precision(4)
    |> float.to_string

  #(
    puzzle
      |> helpers.display_board,
    sudoku_solved,
    time,
  )
}

// PARSING A GRID --------------------------------------------------------------

fn parse_grid_spec(
  spec: String,
  squares: List(String),
) -> dict.Dict(String, String) {
  let l =
    string.to_graphemes(spec)
    |> list.filter(fn(i) { list.contains([".", "0", ..helpers.digits], i) })
  case list.length(l) != 81 {
    True -> panic as "Board with invalid grid spec!"
    _ -> list.map2(squares, l, fn(i, j) { #(i, j) }) |> dict.from_list
  }
}

// CONSTRAINT PROPAGATION ------------------------------------------------------

fn assign_into(
  values: dict.Dict(String, String),
  initial_grid: dict.Dict(String, List(String)),
  dt: Data,
) -> Grid {
  dict.fold(values, GridOk(initial_grid), fn(acc, k, v) {
    do_assign_into(acc, #(k, v), dt)
  })
}

fn do_assign_into(acc: Grid, item: #(String, String), dt: Data) -> Grid {
  case acc, list.contains(helpers.digits, item.1) {
    GridOk(grid), True -> assign(grid, item, dt)
    GridOk(_), _ -> acc
    GridErr(_), _ -> acc
  }
}

// Eliminate all the other values (except d) from grid[s]
fn assign(
  grid: dict.Dict(String, List(String)),
  item: #(String, String),
  // 0 -> square; 1 -> digit
  dt: Data,
) -> Grid {
  let other_values =
    result.unwrap(dict.get(grid, item.0), [""])
    |> list.filter(fn(i) { i != item.1 })

  eliminate_values(grid, item.0, other_values, dt)
}

fn eliminate_values(
  grid: dict.Dict(String, List(String)),
  s: String,
  other: List(String),
  dt: Data,
) -> Grid {
  let acc = #(GridOk(grid), s)
  let new_acc =
    other |> list.fold(acc, fn(acc, d) { eliminate_value(acc, d, dt) })

  new_acc.0
}

fn eliminate_value(
  acc: #(Grid, String),
  // 0 -> grid; 1 -> square
  d: String,
  dt: Data,
) -> #(Grid, String) {
  case acc.0, d {
    GridOk(grid), d -> #(eliminate(grid, acc.1, d, dt), acc.1)
    GridErr(_), _d -> acc
  }
}

fn eliminate_from_squares(
  grid: dict.Dict(String, List(String)),
  peers_sq: List(String),
  d: String,
  dt: Data,
) -> Grid {
  let acc = #(GridOk(grid), d)
  let new_acc =
    peers_sq
    |> list.fold(acc, fn(acc, sq) { eliminate_from_square(acc, sq, dt) })

  new_acc.0
}

fn eliminate_from_square(
  acc: #(Grid, String),
  // 0 -> grid; 1 -> digit
  sq: String,
  dt: Data,
) -> #(Grid, String) {
  case acc.0, sq {
    GridOk(grid), sq -> #(eliminate(grid, sq, acc.1, dt), acc.1)
    GridErr(_), _sq -> acc
  }
}

// Eliminate d from grid[s]
fn eliminate(
  in_grid: dict.Dict(String, List(String)),
  s: String,
  d: String,
  dt: Data,
) -> Grid {
  let assert Ok(dig_list) = dict.get(in_grid, s)
  // let dig_list = result.unwrap(dict.get(in_grid, s), [""])

  case !list.contains(dig_list, d) {
    // Already eliminated 
    True -> GridOk(in_grid)
    False -> {
      let new_grid =
        dict.upsert(in_grid, s, fn(x) {
          case x {
            // remove the digit
            option.Some(l) -> list.filter(l, fn(i) { i != d })
            option.None -> []
          }
        })

      let d2 = get_list_from_dict(new_grid, s)

      case check_peers(new_grid, s, d2, dt) {
        GridOk(new_grid) -> {
          check_units(new_grid, s, d, dt)
        }
        GridErr(_) as err -> err
      }
    }
  }
}

fn check_peers(
  grid: dict.Dict(String, List(String)),
  s: String,
  d2: List(String),
  dt: Data,
) -> Grid {
  let peers = dt.1
  let peers_sq = get_list_from_dict(peers, s)
  let peers_l = list.length(d2)
  let first_p = result.unwrap(list.first(d2), "")

  case grid, s, d2 {
    // (1) If a square s is reduced to one value d2,
    // then eliminate d2 from the peers
    grid, _s, _d2 if peers_l == 1 ->
      eliminate_from_squares(grid, peers_sq, first_p, dt)
    _, _, [] -> GridErr("Removed last value")
    grid, _, _ -> GridOk(grid)
  }
}

// (2) If a unit u is reduced to only one place
// for a value d, then put it there
fn check_units(
  grid: dict.Dict(String, List(String)),
  s: String,
  d: String,
  dt: Data,
) -> Grid {
  let units: dict.Dict(String, List(List(String))) = dt.0
  let assert Ok(units_l) = dict.get(units, s)
  // let units_l = result.unwrap(dict.get(units, s), [[""]])
  let acc = #(GridOk(grid), s, d)

  let new_acc = units_l |> list.fold(acc, fn(acc, u) { check_unit(acc, u, dt) })

  new_acc.0
}

fn check_unit(
  acc: #(Grid, String, String),
  u: List(String),
  dt: Data,
) -> #(Grid, String, String) {
  case acc {
    #(GridOk(grid), _s, _d) -> {
      let dplaces = dplaces(u, grid, acc.2)
      let first_dplaces = result.unwrap(list.first(dplaces), "")

      case list.length(dplaces) {
        0 -> #(GridErr("No place found for inserting value"), acc.1, acc.2)
        // d can only be in one place in unit; assign it there
        1 -> #(assign(grid, #(first_dplaces, acc.2), dt), acc.1, acc.2)
        _ -> acc
      }
    }
    #(GridErr(_msg), _s, _d) as err -> err
  }
}

fn dplaces(
  u: List(String),
  grid: dict.Dict(String, List(String)),
  // s: String,
  d: String,
) {
  list.filter(u, fn(s) { list.contains(get_list_from_dict(grid, s), d) })
}

// DEPTH-FIRST SEARCH ----------------------------------------------------------

pub fn solve(
  spec: String,
  squares: List(String),
  initial_grid: dict.Dict(String, List(String)),
  dt: Data,
) {
  spec
  |> parse_grid_spec(squares)
  |> assign_into(initial_grid, dt)
  |> search(squares, dt)
}

fn search(v: Grid, squares: List(String), dt: Data) -> Grid {
  case v {
    GridErr(_msg) as err -> err
    GridOk(grid) -> {
      let r =
        list.all(squares, fn(s) {
          list.length(get_list_from_dict(grid, s)) == 1
        })

      case r {
        // Solved!
        True -> GridOk(grid)
        // Choose the unfilled square s with the fewest possibilities
        False -> {
          let #(s, values) = choose_fewest_possibilities(grid)

          loop_until_solution_found(values, fn(d) {
            search(assign(grid, #(s, d), dt), squares, dt)
          })
        }
      }
    }
  }
}

fn choose_fewest_possibilities(
  g: dict.Dict(String, List(String)),
) -> #(String, List(String)) {
  let r = dict.filter(g, fn(_k, v) { list.length(v) > 1 }) |> dict.to_list

  let assert Ok(res) =
    maths.list_minimum(r, fn(t1, t2) {
      int.compare(list.length(t1.1), list.length(t2.1))
    })

  res
}

fn loop_until_solution_found(
  values: List(String),
  searcher: fn(String) -> Grid,
) -> Grid {
  case values {
    [] -> GridErr("No solution found")
    [d, ..rest] -> {
      case searcher(d) {
        GridErr(_msg) -> loop_until_solution_found(rest, searcher)
        GridOk(_value) as grid -> grid
      }
    }
  }
}
// 
// # Compile the program to an escript
// gleam build
// gleam run -m gleescript
// 
// import esgleam

// pub fn main() {
//   esgleam.new("./dist")
//   |> esgleam.entry("sudoku_gleam_cli.gleam")
//   |> esgleam.minify(True)
//   |> esgleam.bundle()
// }

// gleam run -m esgleam/install
// gleam build -t javascript
// gleam run -m build

// REFERENCES:
// https://tour.gleam.run/everything/
// https://erikarow.land/notes/using-use-gleam
// https://erikarow.land/notes/gleam-syntax
// https://agustinus.kristia.de/blog/gleam-aoc-2024/
// Importing type variants: https://github.com/gleam-lang/gleam/discussions/3232
// ABOUT SUDOKU:
// https://norvig.com/sudoku.html
// https://naokishibuya.medium.com/peter-norvigs-sudoku-solver-25779bb349ce
// https://github.com/emarifer/elixir_sudoku_solver_cli_app
// https://www.sudokuwiki.org/Arto_Inkala_Sudoku
// https://abakcus.com/article/the-worlds-hardest-sudoku-by-arto-inkala/
// https://www.sudokuwiki.org/
// https://eli.thegreenplace.net/2022/sudoku-go-and-webassembly/
