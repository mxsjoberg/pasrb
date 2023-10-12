# parser.rb

require 'pp'

# https://en.wikipedia.org/wiki/PL/0

# TODO: create my own "dialect"
# - remove semicolons
# - replace begin/end blocks with {}
# - add 'end' to 'if' and 'while' statements WHY ISSUE WITH END BUT NOT }
# - use ? for input and ! for output

# statement ::= (identifier ':=' expr
#             | 'if' condition ('then' | '{') statement ('end' | '}')
#             | 'while' condition ('do' | '{') statement ('end' | '}'))*

# condition ::= 'odd' expr | expr ('=' | '<' | '>') expr
# expr      ::= term (('+' | '-') term)*
# term      ::= factor (('*' | '/') factor)*
# factor    ::= identifier | number | '(' expr ')'

def parse_statement(tokens, tk_index)
    statement = Array.new

    while tk_index < tokens.length && (tokens[tk_index]["type".to_sym] == "identifier" || tokens[tk_index]["type".to_sym] == "keyword")
        tk_current = tokens[tk_index]
        tk_index += 1

        case tk_current["type".to_sym]
        when "identifier"
            identifier = tk_current["value".to_sym]
            begin
                if tokens[tk_index]["type".to_sym] == "assignment"
                    tk_index += 1
                    # expr
                    expr, tk_index = parse_expr(tokens, tk_index)
                    statement << ["assignment", [identifier, expr]]
                end
            rescue
                $issues << { pos: tk_index, issue: "expected ':=' after identifier" }
            end
        when "keyword"
            case tk_current["value".to_sym]
            when "if"
                begin
                    # condition
                    condition, tk_index = parse_condition(tokens, tk_index)
                    # ('then' | '{')
                    begin 
                        if tokens[tk_index]["value".to_sym] == "then" || tokens[tk_index]["value".to_sym] == "{"
                            tk_index += 1
                        end
                    rescue
                        $issues << { pos: tk_index, issue: "expected 'then' or opening braces after condition" }
                    end
                rescue
                    $issues << { pos: tk_index, issue: "expected condition after 'if' keyword" }
                end
                statements, tk_index = parse_statement(tokens, tk_index)
                statement << ["if", [condition, statements]]
                # closing braces
                begin
                    if tokens[tk_index]["value".to_sym] == "end" || tokens[tk_index]["value".to_sym] == "}"
                        tk_index += 1
                    end
                rescue
                    $issues << { pos: tk_index, issue: "expected 'end' or closing braces" }
                end
            end
        end
    end

    return statement, tk_index
end

def parse_condition(tokens, tk_index)
    condition = Array.new
    tk_current = tokens[tk_index]

    case tk_current["type".to_sym]
    when "keyword"
        if tk_current["value".to_sym] == "odd"
            tk_index += 1
            begin
                expr, tk_index = parse_expr(tokens, tk_index)
                condition = ["odd", expr]
            rescue
                $issues << { pos: tk_index, issue: "expected expression after keyword 'odd'" }
            end
        else
            $issues << { pos: tk_index, issue: "expected keyword 'odd'" }
        end
    else
        # expr
        expr, tk_index = parse_expr(tokens, tk_index)
        condition = expr

        unless condition.empty?
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
    end

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

    case tk_current["type".to_sym]
    when "identifier"
        factor = $symbols[tk_current["value".to_sym].to_sym]
        if factor.nil?
            $issues << { pos: tk_index, issue: "identifier not found" }
        end
    when "number"
        factor = tk_current["value".to_sym]
    when "parentheses"
        begin
            expr, tk_index = parse_expr(tokens, tk_index)
            factor = expr
            unless factor.empty?
                # closing parentheses
                if tk_index < tokens.length && tokens[tk_index]["value".to_sym] == ")"
                    tk_index += 1
                elsif tk_index < tokens.length
                    $issues << { pos: tk_index, issue: "no closing parentheses" }
                end
            end
        rescue
        end
    end

    return factor, tk_index
end

def parse(text)
    $issues = Array.new
    $symbols = Hash.new
    # tokens
    tokens = tokenize(text)
    # tokens = Array.new
    # ch_index = 0

    # while ch_index < text.length
    #     ch_current = text[ch_index]
    #     case ch_current
    #     when /[\s\t\r\n]/
    #     when /\d/
    #         number = ch_current
    #         while /\d/.match?(text[ch_index + 1])
    #             number << text[ch_index + 1]
    #             ch_index += 1
    #         end
    #         tokens << { type: "number", value: number, pos: ch_index }
    #     when /[\+\-\*\/]/
    #         tokens << { type: "operator", value: ch_current, pos: ch_index }
    #     when /[\=\<\>]/
    #         tokens << { type: "comparison", value: ch_current, pos: ch_index }
    #     when /[\(\)]/
    #         tokens << { type: "parentheses", value: ch_current, pos: ch_index }
    #     when /\:/
    #         if text[ch_index + 1] == "="
    #             tokens << { type: "assignment", value: ":=", pos: ch_index }
    #         else
    #             $issues << { pos: ch_index, issue: "expecting '=' after ':'" }
    #         end
    #     when /[a-zA-Z]/
    #         identifier = ch_current
    #         while /[a-zA-Z]/.match?(text[ch_index + 1])
    #             identifier << text[ch_index + 1]
    #             ch_index += 1
    #         end
    #         if identifier == "odd" || identifier == "if" || identifier == "then" || identifier == "while" || identifier == "do"
    #             tokens << { type: "keyword", value: identifier, pos: ch_index }
    #         else
    #             tokens << { type: "identifier", value: identifier, pos: ch_index }
    #         end
    #     else
    #         $issues << { pos: ch_index, issue: "unknown character" }
    #     end

    #     ch_index += 1
    # end

    # ast
    ast = Array.new
    tk_index = 0

    expr, tk_index = parse_statement(tokens, tk_index)
    ast = expr

    # pp ast
    return text.length, tokens, ast, $issues
end

def tokenize(text)
    tokens = Array.new
    ch_index = 0

    while ch_index < text.length
        ch_current = text[ch_index]
        case ch_current
        # whitespace
        when /[\s\t\r\n]/
        # number
        when /\d/
            number = ch_current
            while /\d/.match?(text[ch_index + 1])
                number << text[ch_index + 1]
                ch_index += 1
            end
            tokens << { type: "number", value: number, pos: ch_index }
        # operator
        when /[\+\-\*\/]/
            tokens << { type: "operator", value: ch_current, pos: ch_index }
        # comparison
        when /[\=\<\>]/
            tokens << { type: "comparison", value: ch_current, pos: ch_index }
        # parentheses
        when /[\(\)]/
            tokens << { type: "parentheses", value: ch_current, pos: ch_index }
        # braces
        when /[\{\}]/
            tokens << { type: "braces", value: ch_current, pos: ch_index }
        # assignment
        when /\:/
            if text[ch_index + 1] == "="
                ch_index += 1
                tokens << { type: "assignment", value: ":=", pos: ch_index }
            else
                $issues << { pos: ch_index, issue: "expecting '=' after ':'" }
            end
        # identifier
        when /[a-zA-Z]/
            identifier = ch_current
            while /[a-zA-Z]/.match?(text[ch_index + 1])
                identifier << text[ch_index + 1]
                ch_index += 1
            end
            if identifier == "odd" || identifier == "if" || identifier == "then" || identifier == "while" || identifier == "do" || identifier == "end"
                tokens << { type: "keyword", value: identifier, pos: ch_index }
            else
                tokens << { type: "identifier", value: identifier, pos: ch_index }
            end
        else
            $issues << { pos: ch_index, issue: "unknown character" }
        end

        ch_index += 1
    end

    tokens
end

