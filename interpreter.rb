# interpreter.rb

LOOP_MAX = 100000

def interpret(ast)
    node = ast

    if node.kind_of?(Array)
        left = node[0]
        right = node[1]
    else
        left = node
        right = nil
    end

    # traverse nested like this or change how parser build ast?
    if left.kind_of?(Array)
        if left.length == 1
            left = left[0]
        elsif left.length == 2
            right = left[1]
            left = left[0]
        end
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
    when /\>/
        return interpret(right[0]).to_i > interpret(right[1]).to_i
    when /\</
        return interpret(right[0]).to_i < interpret(right[1]).to_i
    when /\=/
        return interpret(right[0]).to_i == interpret(right[1]).to_i
    when /\d/
        return left
    when "assignment"
        $symbols[right[0].to_sym] = interpret(right[1])
        return
    when "output"
        $output << interpret(right)
        return
    when "input"
        $symbols[right.to_sym] = $input[right.to_sym]
        return
    when "if"
        if interpret(right[0])
            return interpret(right[1])
        end
    when "while"
        loop_count = 0
        while interpret(right[0]) && loop_count < LOOP_MAX
            interpret(right[1])
            loop_count += 1
        end
        # inf loop
        if loop_count == LOOP_MAX
            $issues << { pos: nil, issue: "while loop reached LOOP_MAX" }
        end
        return
    when /[a-zA-Z]/
        return $symbols[left.to_sym]
    end
end