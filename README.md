<div align="center">

## sudoku_gleam_webapp

<p style="margin-bottom: 16px;">
    A simple webapp (SPA) for solving sudoku puzzles written in Gleam using the Lustre framework
</p>

<br />

![GitHub License](https://img.shields.io/github/license/emarifer/sudoku_gleam_webapp) ![Static Badge](https://img.shields.io/badge/Gleam-%3E=1.13.0-ffaff3) ![Static Badge](https://img.shields.io/badge/Lustre%20framework-%3E=5.4.0-ffaff3) ![Static Badge](https://img.shields.io/badge/Erlang/OTP-%3E=27-B83998)

</div>

---

### 🚀 Features

This is the web (SPA) version of the [command-line tool for solving Sudoku puzzles](https://github.com/emarifer/sudoku_gleam_cli) written in Gleam, using the [`Lustre`](https://hexdocs.pm/lustre/index.html) framework. At the same time, both are the almost direct translation of the `Elixir` version that I made of [Peter Norvig](https://en.wikipedia.org/wiki/Peter_Norvig)'s algorithm for solving sudokus. This computer scientist developed his [algorithm](https://norvig.com/sudoku.html) in `Python`, based on 2 concepts: [`constraint propagation`](https://en.wikipedia.org/wiki/Constraint_satisfaction) and [`depth-first search`](https://en.wikipedia.org/wiki/Search_algorithm) (a sort of 'sophisticated' brute force). If you have any difficulty understanding it, you can find more details [`here`](https://naokishibuya.medium.com/peter-norvigs-sudoku-solver-25779bb349ce).

---

### 👨‍🚀 Getting Started

You can try the application at this [link](https://gleam-sudoku.netlify.app/). Simply enter the puzzle you want to solve as an 81-character string (9x9 = 81) with no spaces, where empty squares must be represented by periods '.' or zeros '0' and the rest by digits from '1' to '9', something like this: `...8...5..8..3..2.1....4.........8.663.....419.5.........6....3.9..5..1..17..89...`. A string entered with a different number of characters or prohibited characters will generate a warning message. Pressing the `Import` button will display a grid representation of the puzzle you entered, along with the solved Sudoku. The `Reset` button will return you to the input screen so you can enter a new puzzle.

- <ins>Working on the code:</ins>

    With Gleam installed as explained [here](https://gleam.run/getting-started/installing/) (and `Erlang` and its `BEAM VM`), you only need to run the following command in a terminal open in the project folder to start the application in development mode:

    ```sh
    gleam add --dev lustre_dev_tools  
    ```

    This will download the dependencies, compile the project, and start a development server. In your browser, go to [http://localhost:1234](http://localhost:1234) and you will be able to see the application. Any changes you make to the code using your text editor will cause the browser to reload and display the changes.

    > The [lustre_dev_tools](https://hexdocs.pm/lustre_dev_tools/index.html) development server watches your filesystem for changes to your gleam code and can automatically reload the browser. For `Linux` users, this requires [inotify-tools](https://github.com/inotify-tools/inotify-tools) be installed. If you do not or cannot install this, the development server will still run but it will not watch your files for changes.

- <ins>Compiling the code for production deployment:</ins>

    If, after making changes to the code, you decide to test the `SPA application` on a `static file server`, simply run the following command in the project folder opened in a terminal:

    ```sh
    gleam run -m lustre/dev build sudoku_gleam_webapp --minify
    ```

    This will compile (or rather transpile) the `JavaScript` project, generating an `HTML` skeleton and minifying both the `CSS` and JavaScript files, saving everything in a `/dist` folder at the project root. You can find more details about configuring the build for development and production [here](https://hexdocs.pm/lustre/index.html) and [here](https://hexdocs.pm/lustre_dev_tools/index.html).

---

### 📚 Learn more

* Official website: https://gleam.run/
* Guides: https://hexdocs.pm/gleam_stdlib/index.html
* Lustre framework: https://hexdocs.pm/lustre/index.html
* Lustre Dev Tools: https://hexdocs.pm/lustre_dev_tools/index.html
* Community: https://discord.com/invite/Fm8Pwmy
* Gleam discussions on Github: https://github.com/gleam-lang/gleam/discussions

---

### Happy coding 😀!!
