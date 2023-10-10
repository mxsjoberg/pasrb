# parser.rb

def parse(text)
    # TODO: parse text input and return AST
    text_length = text.length
    ch_index = 0
    ch_current = ""

    tokens = Array.new

    while ch_index < text_length
        ch_current = text[ch_index]

        case ch_current
        when /\d/
            number = ch_current
            tokens << { number: number, col: ch_index }
        end

        # push to tokens
        # tokens << ch_current
        ch_index += 1
    end

    puts tokens

    tokens
end