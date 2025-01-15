import gleam/list

import lexer.{type NonControlToken, type Token, CT, END, NCT, START}

pub type Grammar {
  Empty
  Block(List(Grammar))
  T(NonControlToken)
}

// this parser is inefficient because it has to go over characters multiple times
pub fn token_to_grammar(
  tokens: List(Token),
  open_parens: Int,
  block_tokens: List(Token),
) -> List(Grammar) {
  case tokens, open_parens {
    [], 0 ->
      // needed because there might be block tokens left to consume
      case block_tokens {
        [] -> []
        [_, ..] -> [Block(token_to_grammar(list.reverse(block_tokens), 0, []))]
      }
    [], _ -> panic as "Malformed program, unmatched ["
    [CT(END), ..], x if x == 0 -> panic as "Malformed program, unmatched ]"
    // opening a block
    [CT(START), ..rest], 0 ->
      token_to_grammar(rest, open_parens + 1, block_tokens)
    //block is already open, don't consume start control character
    [CT(START), ..rest], _ ->
      token_to_grammar(rest, open_parens + 1, [CT(START), ..block_tokens])
    // closing a block
    [CT(END), ..rest], 1 -> [
      Block(token_to_grammar(list.reverse(block_tokens), 0, [])),
      ..token_to_grammar(rest, 0, [])
    ]
    // block nested in another block which still must be closed
    [CT(END), ..rest], _ ->
      token_to_grammar(rest, open_parens - 1, [CT(END), ..block_tokens])
    // these characters are outside of a block
    [NCT(x), ..rest], 0 -> [
      T(x),
      ..token_to_grammar(rest, open_parens, block_tokens)
    ]
    // characters inside a block
    [NCT(x), ..rest], _ ->
      token_to_grammar(rest, open_parens, [NCT(x), ..block_tokens])
  }
}
