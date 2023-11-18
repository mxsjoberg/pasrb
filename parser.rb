# parser.rb

# TODO: replace ch_index/tk_index in issues with line + col (or add more info? previous token or current token?)

require 'pp'

def parse_statement(tokens, tk_index)
    statement = Array.new

    while tk_index < tokens.length && (["input", "output", "identifier", "keyword"].include? tokens[tk_index]["type".to_sym])
        tk_current = tokens[tk_index]
        
        case tk_current["type".to_sym]
        when "identifier"
            tk_index += 1
            identifier = tk_current["value".to_sym]
            begin
                if tokens[tk_index]["type".to_sym] == "assignment"
                    tk_index += 1
                    # add to symbols
                    $symbols[identifier.to_sym] = nil
                    # expr
                    expr, tk_index = parse_expr(tokens, tk_index)
                    statement << ["assignment", [identifier, expr]]
                    # semicolon
                    begin
                        if tokens[tk_index]["type".to_sym] == "semicolon"
                            tk_index += 1
                        else
                            raise
                        end
                    rescue
                        $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected ';' after assignment statement" }
                    end
                end
            rescue
                $issues << { pos: tokens[tk_index - 1]["pos".to_sym], issue: "expected ':=' after identifier" }
            end
        when "input"
            tk_index += 1
            begin
                if tokens[tk_index]["type".to_sym] == "identifier"
                    identifier = tokens[tk_index]["value".to_sym]
                    unless $identifiers.include? identifier
                        $identifiers << identifier
                        unless $input.keys.map { |identifier| identifier.to_s }.include? identifier
                            $input[identifier.to_sym] = nil
                        end
                    end
                    tk_index += 1
                    statement << ["input", identifier]
                    # semicolon
                    begin
                        if tokens[tk_index]["type".to_sym] == "semicolon"
                            tk_index += 1
                        else
                            raise
                        end
                    rescue
                        $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected ';' after input statement" }
                    end
                end
            rescue
                $issues << { pos: tokens[tk_index - 1]["pos".to_sym], issue: "expected identifier after '?'" }
            end
        when "output"
            tk_index += 1
            begin
                expr, tk_index = parse_expr(tokens, tk_index)
                statement << ["output", expr]
                # semicolon
                begin
                    if tokens[tk_index]["type".to_sym] == "semicolon"
                        tk_index += 1
                    else
                        raise
                    end
                rescue
                    $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected ';' after output statement" }
                end
            rescue
                $issues << { pos: tokens[tk_index - 1]["pos".to_sym], issue: "expected expression after '!'" }
            end
        when "keyword"
            case tk_current["value".to_sym]
            when "if"
                tk_index += 1
                begin
                    # condition
                    condition, tk_index = parse_condition(tokens, tk_index)
                    begin 
                        if tokens[tk_index]["value".to_sym] == "then" || tokens[tk_index]["value".to_sym] == "{"
                            tk_index += 1
                        end
                    rescue
                        $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected 'then' or opening braces after condition" }
                    end
                rescue
                    $issues << { pos: tokens[tk_index - 1]["pos".to_sym], issue: "expected condition after 'if' keyword" }
                end
                statements, tk_index = parse_statement(tokens, tk_index)
                statement << ["if", [condition, statements]]
                # closing braces
                begin
                    if tokens[tk_index]["value".to_sym] == "end" || tokens[tk_index]["value".to_sym] == "}"
                        tk_index += 1
                    end
                rescue
                    $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected 'end' or closing braces" }
                end
            when "while"
                tk_index += 1
                begin
                    # condition
                    condition, tk_index = parse_condition(tokens, tk_index)
                    begin 
                        if tokens[tk_index]["value".to_sym] == "do" || tokens[tk_index]["value".to_sym] == "{"
                            tk_index += 1
                        end
                    rescue
                        $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected 'do' or opening braces after condition" }
                    end
                rescue
                    $issues << { pos: tokens[tk_index - 1]["pos".to_sym], issue: "expected condition after 'while' keyword" }
                end
                statements, tk_index = parse_statement(tokens, tk_index)
                statement << ["while", [condition, statements]]
                # closing braces
                begin
                    if tokens[tk_index]["value".to_sym] == "end" || tokens[tk_index]["value".to_sym] == "}"
                        tk_index += 1
                    end

                rescue
                    $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected 'end' or closing braces" }
                end
            when "end"
                # break while at 'end' without incrementing tk_index
                break
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
                $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected expression after keyword 'odd'" }
            end
        else
            $issues << { pos: tokens[tk_index - 1]["pos".to_sym], issue: "expected keyword 'odd'" }
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
                        $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected expression after comparison" }
                    end
                end
            rescue
                $issues << { pos: tokens[tk_index - 1]["pos".to_sym], issue: "expected comparison after expression" }
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

    while tk_index < tokens.length && (["+", "-"].include? tokens[tk_index]["value".to_sym])
        tk_current = tokens[tk_index]
        tk_index += 1
        # term
        begin
            term, tk_index = parse_term(tokens, tk_index)
            expr = [tk_current["value".to_sym], [expr, term]]
        rescue
            $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected term after operator" }
        end
    end

    return expr, tk_index
end

def parse_term(tokens, tk_index)
    term = Array.new
    # factor
    factor, tk_index = parse_factor(tokens, tk_index)
    term = factor
    
    while tk_index < tokens.length && (["*", "/"].include? tokens[tk_index]["value".to_sym])
        tk_current = tokens[tk_index]
        tk_index += 1
        # factor
        begin
            factor, tk_index = parse_factor(tokens, tk_index)
            term = [tk_current["value".to_sym], [term, factor]]
        rescue
            $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "expected factor after operator" }
        end
    end

    return term, tk_index
end

def parse_factor(tokens, tk_index)
    factor = Array.new
    tk_current = tokens[tk_index]
    tk_index += 1 # ;

    case tk_current["type".to_sym]
    when "identifier"
        identifier = tk_current["value".to_sym]
        factor = identifier
        unless $identifiers.include? identifier
            $identifiers << identifier
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
                    $issues << { pos: tokens[tk_index]["pos".to_sym], issue: "no closing parentheses" }
                end
            end
        rescue
        end
    end

    return factor, tk_index
end

def parse(text)
    # $symbols = Hash.new
    # $identifiers = Array.new
    # $issues = Array.new
    # tokens
    tokens = tokenize(text)
    # ast
    ast = Array.new
    tk_index = 0
    # parse
    ast, tk_index = parse_statement(tokens, tk_index)

    # pp $symbols
    # pp $identifiers

    # report uninitialized but used identifiers
    # pp $identifiers - $symbols.keys.map { |identifier| identifier.to_s }
    unless ($identifiers - $symbols.keys.map { |identifier| identifier.to_s }).empty?
        $issues << { pos: nil, issue: "some identifiers not initialized" }
    end

    # pp ast
    return text.length, tokens, ast
end

def tokenize(text)
    tokens = Array.new
    ch_index = 0
    line = 1

    while ch_index < text.length
        ch_current = text[ch_index]
        case ch_current
        # newline
        when /[\n]/
            line += 1
        # whitespace
        when /[\s\t\r]/
        # number
        when /\d/
            number = ch_current
            while /\d/.match?(text[ch_index + 1])
                number << text[ch_index + 1]
                ch_index += 1
            end
            tokens << { type: "number", value: number, pos: line }
        # operator
        when /[\+\-\*\/]/
            tokens << { type: "operator", value: ch_current, pos: line }
        # comparison
        when /[\=\<\>]/
            tokens << { type: "comparison", value: ch_current, pos: line }
        # parentheses
        when /[\(\)]/
            tokens << { type: "parentheses", value: ch_current, pos: line }
        # braces
        when /[\{\}]/
            tokens << { type: "braces", value: ch_current, pos: line }
        # input
        when /\?/
            tokens << { type: "input", value: ch_current, pos: line }
        # output
        when /\!/
            tokens << { type: "output", value: ch_current, pos: line }
        # assignment
        when /\:/
            if text[ch_index + 1] == "="
                ch_index += 1
                tokens << { type: "assignment", value: ":=", pos: line }
            else
                begin
                    ch_index += 1
                    tokens << { type: "assignment", value: ":=", pos: line }
                rescue
                end
                $issues << { pos: line, issue: "expected '=' after ':'" }
            end
        # semicolon
        when /\;/
            tokens << { type: "semicolon", value: ch_current, pos: line }
        # identifier
        when /[a-zA-Z]/
            identifier = ch_current
            while /[a-zA-Z]/.match?(text[ch_index + 1])
                identifier << text[ch_index + 1]
                ch_index += 1
            end
            if identifier == "odd" || identifier == "if" || identifier == "then" || identifier == "while" || identifier == "do" || identifier == "end"
                tokens << { type: "keyword", value: identifier, pos: line }
            else
                tokens << { type: "identifier", value: identifier, pos: line }
            end
        else
            $issues << { pos: line, issue: "unknown character" }
        end

        ch_index += 1
    end

    tokens
end
