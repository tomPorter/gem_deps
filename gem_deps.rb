#!/usr/bin/env ruby
class GemDep
  attr_reader :dependers, :dependents, :name
  def initialize(name)
    @name = name
    @dependers = []
    @dependents = self.get_deps(@name)
  end

  def get_deps(name)
    ## ToDo:  This currently returns all gem dependencies,
    ## ToDo:  including gems from the stdlib.
    ## ToDo:  See GemDep#remove_dependents_not_on_list and
    ## ToDo:  GemDepHash#remove_stdlib_dependents.
    #
    ## ToDo:  I need to filter out development gems!
    ## ToDo:  'gem dependency tilt' for good example: has lots
    ## ToDo:  of development dependencies, but no prod ones.
    dep_lines = `gem dependency #{name} 2>&1`.split("\n")
    name_found_in = dep_lines.find_index {|x| x =~ /#{name}/i }
    if dep_lines.size == name_found_in +1
      @dependents = []
    else
      dep_lines.shift(name_found_in + 1)
      @dependents = dep_lines.map {|x| x.strip.split()[0] }
    end
  end

  def remove_dependents_not_in_list(gem_list)
    x = @dependents
    not_in_list = x - gem_list
    @dependents = x - not_in_list
  end

  def update_dependers(list_of_gem_names)
    @dependers = list_of_gem_names
  end

end

class GemDepHash < Hash

  def initialize()
    temp_hash = Hash[`gem list`.split("\n").map {|x| [x.strip.split()[0],GemDep.new(x.strip.split()[0])] }] 
    temp_hash.each_pair {|k,v| self[k] = v }
  end

  def update_dependers()
    self.each_pair do |k,v|
      v.update_dependers(gems_that_depend_on(k))
    end

  def remove_stdlib_dependents()
    self.each_pair do |k,v|
      v.remove_dependents_not_in_list(self.keys)
    end
  end

  end

  def gems_that_depend_on(gem_name)
    dependers = []
    self.keys.each do |gn|
      if self[gn].dependents.include? gem_name
        dependers << gn
      end
    end
    dependers
  end

end

gem_hash = GemDepHash.new
#puts gem_hash.inspect
gem_hash.update_dependers
no_dependers = gem_hash.reject {|k,v| v.dependers.size > 0 }
puts "No Dependers:"
no_dependers.each {|x| puts "  #{x.inspect}" }

no_dependents = gem_hash.reject {|k,v| v.dependents.size > 0 }
puts "No Dependents before stdlib removal:"
no_dependents.each {|x| puts "  #{x.inspect}" }

gem_hash.remove_stdlib_dependents
no_dependents = gem_hash.reject {|k,v| v.dependents.size > 0 }
puts "No Dependents after stdlib removal:"
no_dependents.each {|x| puts "  #{x.inspect}" }
