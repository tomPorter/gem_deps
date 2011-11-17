#!/usr/bin/env ruby
def sub_it(x)
  if x == 0
    puts "done!"
  else
    puts x
    sub_it(x-1)
  end  
end
