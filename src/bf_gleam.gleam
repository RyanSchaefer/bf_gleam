import argv
import file_streams/file_stream as fs
import gleam/list
import gleam/option
import gleam/string
import glint
import interpreter
import lexer.{char_to_token}
import parser.{token_to_grammar}

fn get_all_from_stream(
  file: fs.FileStream,
  acc: option.Option(String),
) -> option.Option(String) {
  case fs.read_line(file) {
    Ok(x) ->
      get_all_from_stream(
        file,
        acc
          |> option.or(option.Some(""))
          |> option.then(fn(str) { option.Some(str <> x) }),
      )
    _ -> acc
  }
}

fn get_data(filename: String) -> option.Option(String) {
  fs.open_read(filename)
  |> option.from_result
  |> option.then(get_all_from_stream(_, option.None))
}

fn run() -> glint.Command(option.Option(Nil)) {
  use <- glint.command_help("run a brainfuck file")
  use file <- glint.named_arg("file")
  use named_args, _, _ <- glint.command()
  get_data(file(named_args))
  |> option.map(string.to_graphemes)
  |> option.map(list.map(_, char_to_token))
  |> option.map(option.values)
  |> option.map(token_to_grammar(_, 0, []))
  |> option.map(interpreter.interpert)
}

pub fn main() {
  glint.new()
  |> glint.with_name("brainfuck")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add([], run())
  |> glint.run_and_handle(argv.load().arguments, fn(_) { Nil })
}
