# interpreter.rb

# TODO: add rest of statements

def interpret(ast)
    # result = nil
    node = ast

    if node.kind_of?(Array)
        left = node[0]
        right = node[1]
    else
        left = node
        right = nil
    end

    case left
    when /\+/
        return interpret(right[0]).to_i + interpret(right[1]).to_i
    when /\-/
        return interpret(right[0]).to_i - interpret(right[1]).to_i
    when /\*/
        return interpret(right[0]).to_i * interpret(right[1]).to_i
    when /\//
        return interpret(right[0]).to_i / interpret(right[1]).to_i
    when /\d/
        return left
    when "assignment"
        $symbols[right[0].to_sym] = interpret(right[1])
        return
    when "output"
        $output << interpret(right)
        return
    when /[a-zA-Z]/
        return $symbols[left.to_sym]
    end

    # result ? result : "nil"
end