require "../src/reply"

class MyInterface < Reply::Interface
end

repl_interface = MyInterface.new

repl_interface.run do |expression|
  # Eval expression here
  puts " => #{expression}"
end

# # Or:
# loop do
#   expression = repl_interface.read_next
#   break unless expression

#   # Eval expression here
#   puts " => #{expression}"
# end