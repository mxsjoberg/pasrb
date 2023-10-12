# parser.rb

require 'pp'

# https://en.wikipedia.org/wiki/PL/0

# TODO: create my own "dialect"
# - remove semicolons
# - replace begin/end with {}
# - use ? for input and ! for output

# statement ::= identifier ':=' expr
#             | 'if' condition 'then' statement
#             | 'while' condition 'do' statement

# condition ::= 'odd' expr
#             | expr ('=' | '<' | '>') expr

# expr      ::= term (('+' | '-') term)*

# term      ::= factor (('*' | '/') factor)*

# factor    ::= identifier
#             | number
#             | '(' expr ')'

def parse_condition(tokens, tk_index)
    condition = Array.new
    tk_current = tokens[tk_index]
    # 'odd'
    if tk_current["type".to_sym] == "keyword" && tk_current["value".to_sym] == "odd"
        tk_index += 1
        expr, tk_index = parse_expr(tokens, tk_index)
        condition = ["odd", expr]
    else
        # expr
        expr, tk_index = parse_expr(tokens, tk_index)
        condition = expr
        # comparison
        begin
            tk_current = tokens[tk_index]
            tk_index += 1
            case tk_current["type".to_sym]
            when "comparison"
                # expr
                begin
                    expr, tk_index = parse_expr(tokens, tk_index)
                    condition = [tk_current["value".to_sym], [condition, expr]]
                rescue
                    $issues << { pos: tk_index, issue: "expected expression after comparison" }
                end
            end
        rescue
            $issues << { pos: tk_index, issue: "expected comparison after expression" }
        end
    end

    puts condition

    return condition, tk_index
end

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
            tokens << { type: "operator", value: ch_current, pos: ch_index }
        when /[\=\<\>]/
            tokens << { type: "comparison", value: ch_current, pos: ch_index }
        when /[\(\)]/
            tokens << { type: "parentheses", value: ch_current, pos: ch_index }
        when /[\:]/ && text[ch_index + 1] == "="
            tokens << { type: "assignment", value: ":=", pos: ch_index }
        when /[a-zA-Z]/
            identifier = ch_current
            while /[a-zA-Z]/.match?(text[ch_index + 1])
                identifier << text[ch_index + 1]
                ch_index += 1
            end
            if identifier == "odd" || identifier == "if" || identifier == "then" || identifier == "while" || identifier == "do"
                tokens << { type: "keyword", value: identifier, pos: ch_index }
            else
                tokens << { type: "identifier", value: identifier, pos: ch_index }
            end
        end

        ch_index += 1
    end

    # ast
    ast = Array.new
    tk_index = 0

    while tk_index < tokens.length
        expr, tk_index = parse_condition(tokens, tk_index)
        ast = expr
    end

    # pp ast
    return text.length, tokens, ast, $issues
end