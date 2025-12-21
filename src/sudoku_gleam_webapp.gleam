import birl
import formal/form.{type Form}
import gleam/int
import gleam/list
import gleam/string
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import solver/sudoku

const chars = [".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  // As an alternative to controlled inputs, Lustre also supports non-controlled
  // forms. Instead of us having to manage the state and appropriate messages
  // for each input, we use the platform and let the browser handle these things
  // for us.
  //
  // Here, we do not need to store the input values in the model, only keeping
  // the puzzle once the user has entered the data.
  FormData(Form(SubmissionData))
  PuzzleEntered(puzzle: String)
}

fn init(_) {
  FormData(new_data_solve_form())
}

// In addition to our model, we will have a SubmissionData custom type which we
// will use to `decode` the form data into.
type SubmissionData {
  SubmissionData(puzzle: String)
}

fn new_data_solve_form() -> Form(SubmissionData) {
  // We create an empty form that can later be used to parse, check and decode 
  // user supplied data.
  form.new({
    let check_puzzle = fn(puzzle: String) {
      let puzzle_lenght = string.length(puzzle) == 81
      let puzzle_list =
        string.to_graphemes(puzzle)
        |> list.all(fn(i) { list.contains(chars, i) })
      case puzzle_lenght && puzzle_list {
        True -> Ok(puzzle)
        False ->
          Error(
            "The entered puzzle contains invalid characters or an incorrect length!",
          )
      }
    }

    use puzzle <- form.field(
      "puzzle",
      form.parse_string |> form.check(check_puzzle),
    )

    form.success(SubmissionData(puzzle:))
  })
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  // Instead of receiving messages while the user edits the values, we only
  // receive a single message with all the data once the form is
  // submitted and processed.
  UserSubmittedForm(Result(SubmissionData, Form(SubmissionData)))
  UserClickedResetForm
}

fn update(_model: Model, msg: Msg) -> Model {
  case msg {
    // Validation succeeded - the puzzle will be sent to be solved.!
    UserSubmittedForm(Ok(SubmissionData(puzzle:))) -> {
      PuzzleEntered(puzzle:)
    }
    // Validation failed - store the form in the model to show the errors.
    UserSubmittedForm(Error(form)) -> {
      FormData(form)
    }
    // The user clicks on the 'Reset' button - a empty form is displayed again
    UserClickedResetForm -> FormData(new_data_solve_form())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> element.Element(Msg) {
  html.div([attribute.class("py-5 sm:pt-16 flex flex-col text-center")], [
    html.div([attribute.class("mx-auto w-11/12 sm:w-1/2")], [
      html.h1([attribute.class("text-xl sm:text-3xl font-bold my-2 sm:my-6")], [
        html.text("Sudoku Solver"),
      ]),
      case model {
        FormData(form) -> view_puzzle_form(form)
        PuzzleEntered(puzzle:) -> {
          html.div([], [
            view_sudoku_grid(puzzle),
            html.div([attribute.class("flex justify-end mt-4")], [
              html.button(
                [
                  attribute.class(
                    "flex justify-end bg-lime-600 text-xs sm:text-sm font-semibold px-3 py-2 sm:px-4 sm:py-2 mr-10 -mt-2  sm:mr-0 sm:-mt-0 rounded-lg hover:bg-base-300 cursor-pointer",
                  ),
                  event.on_click(UserClickedResetForm),
                ],
                [html.text("Reset")],
              ),
            ]),
          ])
        }
      },
    ]),
    get_credits(),
  ])
}

fn view_puzzle_form(form: Form(SubmissionData)) -> element.Element(Msg) {
  // Lustre sends us the form data as a list of tuples, which we can then
  // process, decode, or send off to our backend.
  //
  // Here, we use `formal` to turn the form values we got into Gleam data.
  let handle_submit = fn(values: List(#(String, String))) {
    form |> form.add_values(values) |> form.run |> UserSubmittedForm
  }

  let errors = form.field_error_messages(form, "puzzle")

  html.form(
    [
      attribute.class("p-6 w-full border rounded-2xl shadow-lg space-y-2"),
      // The message provided to the built-in `on_submit` handler receives the
      // `FormData` associated with the form as a List of (name, value) tuples.
      //
      // The event handler also calls `preventDefault()` on the form, such that
      // Lustre can handle the submission instead off being
      // sent off to the server.
      event.on_submit(handle_submit),
    ],
    [
      html.label(
        [
          attribute.for("puzzle"),
          attribute.class(
            "flex flex-start text-sm font-semibold text-slate-300 cursor-pointer",
          ),
        ],
        [html.text("Enter a puzzle:")],
      ),
      html.input([
        // we use the `id` in the associated `for` attribute on the label.
        attribute.id("puzzle"),
        // the `name` attribute is used as the first element of the tuple
        // we receive for this input.
        attribute.type_("search"),
        attribute.name("puzzle"),
        attribute.placeholder("Only digits from '1' to '9' and '.' or '0' ..."),
        attribute.autofocus(True),
        attribute.class(
          "block text-xs sm:text-base font-mono w-full px-3 py-2 border border-cyan-50 rounded-md focus:outline focus:outline-offset-[-5px] focus:outline-2 focus:outline-cyan-50",
        ),
      ]),

      // formal provides us with customisable error messages for every element
      // in case its validation fails, which we can show right below the input.
      errors_list(errors),
      //
      html.div([attribute.class("flex justify-end")], [
        html.button(
          [
            // buttons inside of forms submit the form by default.
            attribute.class("text-sm font-semibold cursor-pointer"),
            attribute.class("px-2 py-1 sm:px-4 sm:py-2 bg-primary rounded-lg"),
            attribute.class("hover:bg-base-300"),
          ],
          [html.text("Import")],
        ),
      ]),
    ],
  )
}

fn errors_list(errors: List(String)) -> element.Element(Msg) {
  html.div(
    [],
    list.map(errors, fn(error_message) {
      html.p([attribute.class("mt-0.5 text-left text-sm text-red-500")], [
        html.text(error_message),
      ])
    }),
  )
}

// https://hexdocs.pm/lustre/lustre/element.html#unsafe_raw_html
fn view_sudoku_grid(puzzle: String) {
  let #(bl, sl) = sudoku.solver(puzzle)

  html.div(
    [
      attribute.class("flex flex-col gap-4 p-2 sm:flex-row sm:justify-between"),
      attribute.class("sm:p-6 w-3/4 sm:w-full"),
      attribute.class("border rounded-2xl shadow-lg mx-auto"),
    ],
    [
      // Show puzzle
      html.table([attribute.class("mx-auto")], [
        html.caption([attribute.class("text-sm sm:text-base")], [
          html.text("Board to solve:"),
        ]),
        html.colgroup([], [html.col([]), html.col([]), html.col([])]),
        html.colgroup([], [html.col([]), html.col([]), html.col([])]),
        html.colgroup([], [html.col([]), html.col([]), html.col([])]),
        ..bl
        |> list.map(fn(body) { element.unsafe_raw_html("", "tbody", [], body) })
      ]),
      // Show sudoku
      case sl {
        [msg] -> {
          html.p(
            [
              attribute.class("lowercase fl text-error text-xs"),
              attribute.class("sm:text-sm sm:w-1/2"),
            ],
            [html.text(msg)],
          )
        }
        _ -> {
          html.table([attribute.class("mx-auto")], [
            html.caption([attribute.class("text-sm sm:text-base")], [
              html.text("Sudoku solved:"),
            ]),
            html.colgroup([], [html.col([]), html.col([]), html.col([])]),
            html.colgroup([], [html.col([]), html.col([]), html.col([])]),
            html.colgroup([], [html.col([]), html.col([]), html.col([])]),
            ..sl
            |> list.map(fn(body) {
              element.unsafe_raw_html("", "tbody", [], body)
            })
          ])
        }
      },
    ],
  )
}

fn get_credits() -> element.Element(Msg) {
  html.a(
    [
      attribute.class(
        "absolute left-3 bottom-4 sm:bottom-6 text-center text-xs text-lime-500 hover:text-lime-300",
      ),
      attribute.href("https://github.com/emarifer?tab=repositories"),
      attribute.target("_blank"),
      attribute.rel("noopener noreferrer"),
    ],
    [
      html.text(
        "⚡ Made by emarifer | Copyright © "
        <> { birl.now() |> birl.get_day }.year |> int.to_string
        <> " - MIT Licensed",
      ),
    ],
  )
}
