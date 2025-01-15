import gleam/io
import gleam/string
import gleam/yielder.{Done}

import gleam/list
import lexer.{type NonControlToken}
import parser.{type Grammar, Block, Empty, T}

import stdin

type Tape {
  Tape(left: List(Int), current: Int, right: List(Int))
}

type Env {
  Env(input: yielder.Yielder(Int), tape: Tape)
}

fn input_stream() {
  stdin.read_lines()
  |> yielder.map(fn(x) {
    string.to_utf_codepoints(x)
    |> list.map(string.utf_codepoint_to_int)
    |> yielder.from_list
  })
  |> yielder.flatten
}

fn shift_tape_left(tape: Tape) -> Tape {
  case tape {
    Tape([l, ..ls], c, rs) -> Tape(ls, l, [c, ..rs])
    Tape([], c, rs) -> Tape([], 0, [c, ..rs])
  }
}

fn shift_tape_right(tape: Tape) -> Tape {
  case tape {
    Tape(ls, c, [r, ..rs]) -> Tape([c, ..ls], r, rs)
    Tape(ls, c, []) -> Tape([c, ..ls], 0, [])
  }
}

fn add_tape(tape: Tape, update: Int) -> Tape {
  Tape(..tape, current: { tape.current + update } % 256)
}

fn update_tape(tape: Tape, update: Int) -> Tape {
  Tape(..tape, current: update)
}

fn token_action(token: NonControlToken, env: Env) -> Env {
  case token {
    lexer.DPI -> Env(..env, tape: shift_tape_right(env.tape))
    lexer.DPD -> Env(..env, tape: shift_tape_left(env.tape))
    lexer.BD -> Env(..env, tape: add_tape(env.tape, -1))
    lexer.BI -> Env(..env, tape: add_tape(env.tape, 1))
    lexer.IN -> {
      let next = yielder.step(env.input)
      case next {
        yielder.Done -> env
        yielder.Next(item, rest) -> {
          Env(rest, update_tape(env.tape, item))
        }
      }
    }
    lexer.OUT -> {
      let result = string.utf_codepoint(env.tape.current)
      case result {
        Ok(x) -> io.print(string.from_utf_codepoints([x]))
        Error(_) -> Nil
      }
      env
    }
  }
}

pub fn interpert(program: List(Grammar)) -> Nil {
  interpert_impl(
    program,
    Env(input_stream(), Tape(left: [], current: 0, right: [])),
  )
  |> fn(_) { Nil }
}

fn interpert_impl(program: List(Grammar), env: Env) -> Env {
  case program, env {
    [T(x), ..rest], _ -> interpert_impl(rest, token_action(x, env))
    [Block(_), ..rest], Env(_, Tape(_, 0, _)) -> {
      interpert_impl(rest, env)
    }
    [Block(x), ..], Env(_, Tape(_, _, _)) -> {
      let new_env = interpert_impl(x, env)
      interpert_impl(program, new_env)
    }
    [Empty, ..rest], _ -> interpert_impl(rest, env)
    [], env -> env
  }
}
