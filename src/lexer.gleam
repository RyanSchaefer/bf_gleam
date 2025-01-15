import gleam/option

pub type NonControlToken {
  DPI
  DPD
  BI
  BD
  OUT
  IN
}

pub type ControlToken {
  START
  END
}

pub type Token {
  CT(ControlToken)
  NCT(NonControlToken)
}

pub fn char_to_token(char: String) -> option.Option(Token) {
  case char {
    ">" -> option.Some(NCT(DPI))
    "<" -> option.Some(NCT(DPD))
    "+" -> option.Some(NCT(BI))
    "-" -> option.Some(NCT(BD))
    "." -> option.Some(NCT(OUT))
    "," -> option.Some(NCT(IN))
    "[" -> option.Some(CT(START))
    "]" -> option.Some(CT(END))
    _ -> option.None
  }
}
