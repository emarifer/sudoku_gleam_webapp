import gleam/bool
import gleam/dict
import gleam/list
import gleam/string

pub const rows = ["A", "B", "C", "D", "E", "F", "G", "H", "I"]

pub const cols = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

pub const digits = cols

pub type Grid {
  GridOk(value: dict.Dict(String, List(String)))
  GridErr(msg: String)
}

pub fn cross(rows: List(String), cols: List(String)) -> List(String) {
  // list.map(rows, fn(r) { list.map(cols, fn(c) { r <> c }) }) |> list.flatten

  use r <- list.flat_map(rows)
  use c <- list.map(cols)
  r <> c
}

pub fn generate_grid(
  s: List(String),
  d: List(String),
) -> dict.Dict(String, List(String)) {
  list.map(s, fn(i) { #(i, d) }) |> dict.from_list
}

pub fn units_list(rows: List(String), cols: List(String)) -> List(List(String)) {
  let units_c = list.map(cols, fn(c) { cross(rows, [c]) })
  let units_r = list.map(rows, fn(r) { cross([r], cols) })

  list.append(units_c, units_r) |> list.append(peers_list(rows, cols))
}

pub fn units(
  squares: List(String),
  unitlist: List(List(String)),
) -> dict.Dict(String, List(List(String))) {
  list.map(squares, fn(s) { generate_tuple(s, unitlist) }) |> dict.from_list
}

pub fn peers(
  sq: List(String),
  units: dict.Dict(String, List(List(String))),
) -> dict.Dict(String, List(String)) {
  let units_as = fn(s) {
    let assert Ok(list) = dict.get(units, s)
    list
  }
  list.map(sq, fn(s) { associate_units(s, units_as(s)) }) |> dict.from_list
}

pub fn get_list_from_dict(dict: dict.Dict(String, List(String)), s: String) {
  // We can always be certain that the dictionaries
  // used as a "grid" contain a value for each key
  let assert Ok(list) = dict.get(dict, s)
  list
}

fn peers_list(rows: List(String), cols: List(String)) -> List(List(String)) {
  let chunked_list_r = list.sized_chunk(rows, 3)
  let chunked_list_c = list.sized_chunk(cols, 3)

  list.map(chunked_list_r, fn(rs) {
    list.map(chunked_list_c, fn(rc) { cross(rs, rc) })
  })
  |> list.flatten
}

fn generate_tuple(
  sq: String,
  unitlist: List(List(String)),
) -> #(String, List(List(String))) {
  #(sq, list.filter(unitlist, fn(u) { list.contains(u, sq) }))
}

fn associate_units(sq: String, u: List(List(String))) -> #(String, List(String)) {
  #(sq, list.flatten(u) |> list.unique |> list.filter(fn(i) { i != sq }))
}

// SHOW BOARD & SOLVED GRID ----------------------------------------------------

pub fn display_board(puzzle: String) -> List(String) {
  let sq_data = string.to_graphemes(puzzle) |> list.sized_chunk(9)

  use tr_list <- list.map({
    {
      use list_row <- list.map(sq_data)
      "<tr>"
      <> {
        use sq <- list.map(list_row)
        use <- bool.guard(string.contains(".0", sq), "<td></td>")
        "<td>" <> sq <> "</td>"
      }
      |> string.join("")
      <> "</tr>"
    }
    |> list.sized_chunk(3)
  })

  tr_list |> string.join("")
}

pub fn display_sudoku(res: Grid, sq: List(String)) -> List(String) {
  let sq_list = sq |> list.sized_chunk(9)

  case res {
    GridErr(msg) -> ["Sudoku with no solution: " <> msg]
    GridOk(grid) -> {
      let row_l =
        list.map(sq_list, fn(l) {
          "<tr>"
          <> list.map(l, fn(s) {
            let assert [d] = get_list_from_dict(grid, s)
            "<td>" <> d <> "</td>"
          })
          |> string.join("")
          <> "</tr>"
        })
        |> list.sized_chunk(3)

      list.map(row_l, fn(r) { r |> string.join("") })
    }
  }
}
