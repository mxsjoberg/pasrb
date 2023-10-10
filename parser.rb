# parser.rb

require 'pp'

# expr      ::= term (('+' | '-') term)*
# term      ::= factor (('*' | '/') factor)*
# factor    ::= number | '(' expr ')'

def parse_expr(tokens, tk_index)
    expr = Array.new
    # term
    term, tk_index = parse_term(tokens, tk_index)
    expr = term
    # (+ | -)
    while tk_index < tokens.length && (tokens[tk_index]["value".to_sym] == "+" || tokens[tk_index]["value".to_sym] == "-")
        tk_current = tokens[tk_index]
        tk_index += 1
        # term
        begin
            term, tk_index = parse_term(tokens, tk_index)
            expr = [tk_current["value".to_sym], [expr, term]]
        rescue
            $issues << { pos: tk_index, issue: "expected term after operator" }
        end
    end

    return expr, tk_index
end

def parse_term(tokens, tk_index)
    term = Array.new
    # factor
    factor, tk_index = parse_factor(tokens, tk_index)
    term = factor
    # (* | /)
    while tk_index < tokens.length && (tokens[tk_index]["value".to_sym] == "*" || tokens[tk_index]["value".to_sym] == "/")
        tk_current = tokens[tk_index]
        tk_index += 1
        # factor
        begin
            factor, tk_index = parse_factor(tokens, tk_index)
            term = [tk_current["value".to_sym], [term, factor]]
        rescue
            $issues << { pos: tk_index, issue: "expected factor after operator" }
        end
    end

    return term, tk_index
end

def parse_factor(tokens, tk_index)
    factor = Array.new
    tk_current = tokens[tk_index]
    tk_index += 1
    # number
    case tk_current["type".to_sym]
    when "number"
        factor = tk_current["value".to_sym]
    when "parentheses"
        begin
            expr, tk_index = parse_expr(tokens, tk_index)
            factor = expr
            # closing parentheses
            if tk_index < tokens.length && tokens[tk_index]["value".to_sym] == ")"
                tk_index += 1
            else
                $issues << { pos: tk_index, issue: "no closing parentheses" }
            end
        rescue
        end
    end

    return factor, tk_index
end

def parse(text)
    $issues = Array.new
    # tokens
    tokens = Array.new
    ch_index = 0

    while ch_index < text.length
        ch_current = text[ch_index]
        case ch_current
        when /\d/
            number = ch_current
            while /\d/.match?(text[ch_index + 1])
                number << text[ch_index + 1]
                ch_index += 1
            end
            tokens << { type: "number", value: number, pos: ch_index }
        when /[\+\-\*\/]/
            operator = ch_current
            tokens << { type: "operator", value: operator, pos: ch_index }
        when /[\(\)]/
            parentheses = ch_current
            tokens << { type: "parentheses", value: parentheses, pos: ch_index }
        end

        ch_index += 1
    end

    # ast
    ast = Array.new
    tk_index = 0

    while tk_index < tokens.length
        expr, tk_index = parse_expr(tokens, tk_index)
        ast = expr
    end

    # pp ast
    return text.length, tokens, ast, $issues
end