# interpreter.rb

# TODO: add rest of statements

def interpret(ast)
    result = nil
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
        result = interpret(right[0]).to_i + interpret(right[1]).to_i
    when /\-/
        result = interpret(right[0]).to_i - interpret(right[1]).to_i
    when /\*/
        result = interpret(right[0]).to_i * interpret(right[1]).to_i
    when /\//
        result = interpret(right[0]).to_i / interpret(right[1]).to_i
    when /\d/
        return left
    when "assignment"

    end

    # result ? result : "nil"
    result
end