#!/usr/bin/env ruby
require 'rubygems'
APPNAME = "Consular"

# List commands
def help
  help =  "#{APPNAME} - Usage:\n"
  help += "-----------------------------------------------\n"
  help += "List all consular recipes:\tcons list\n"
  help += "Start a project:\t\t\t\t\t\tcons start {recipe_name}\n"
  help += "Edit recipe:\t\t\t\t\t\t\t\tcons edit {recipe_name}\n"
  help += "Create new recipe:\t\t\t\t\tcons create {recipe_name}\n"
  help += "Delete new recipe:\t\t\t\t\tcons delete {recipe_name}\n"
  help += "List commands:\t\t\t\t\t\t\tcons help\n"
  help += "-----------------------------------------------"
  # Copy help to clipboard
  `echo "#{help}" | pbcopy`

  short_help = "Commands copied to clipboard - "
  short_help += "consular list, "
  short_help += "consular start {name}, "
  short_help += "consular edit {name} "
  short_help += "consular create {name} or "
  short_help += "consular delete {name}."
  # Show list on Growl
  puts short_help
end

# Start project
def start(project)
  project = project.gsub(/\s+/, "")
  if recipe_exists(project)
    # Run consular recipe in terminal
    osa open_terminal(run_in_terminal(["consular start #{project}"]))
    puts "Starting project: #{project}"
  else
    puts "Recipy not found: #{project}"
  end
end

# Edit recipe
def edit(recipe)
  recipe = recipe.gsub(/\s+/, "")
  if recipe_exists(recipe)
    # Run consular edit in terminal
    osa open_terminal(run_in_terminal(["consular edit #{recipe}"]))
    puts "Editing recipe: #{recipe}"
  else
    puts "Recipy not found: #{recipe}"
  end
end

# Delete recipe
def delete(recipe)
  recipe = recipe.gsub(/\s+/, "")
  if recipe_exists(recipe)
    # Delete recipe
    output = `bash delete.sh #{recipe}`
    puts "Deleted recipe: #{recipe}"
  else
    puts "Recipy not found: #{recipe}"
  end
end

# Create new recipe
def create(name)
  name = name.gsub(/\s+/, "")
  if recipe_exists(name)
    puts "Project #{name} already exists."
  else
    # Run consular edit in terminal
    osa open_terminal(run_in_terminal(["consular edit #{name}"]))
    puts "Created new recipe: #{name}"
  end
  puts name
end

# List recipes
def list()
  list = get_list.join(', ').gsub("\n", "")
  # Show list on growl
  puts "List copied to clipboard - #{list}"
  long =  "Consular recipes:\n"
  long += "-----------------------------------------------\n"
  long += get_list(true).join()
  long += "-----------------------------------------------"
  # Copy list to clipboard
  `echo "#{long}" | pbcopy`
end

# Return true if recipe exists
def recipe_exists(name)
  list = get_list(false)
  found = false
  list.each do |s|
    if s.gsub(/\s+/, "") == name
      found = true
    end
  end
  found
end

# Get list of recipes
# Set verbose to true to get detailed info
def get_list(verbose = false)
  output = `bash list.sh`
  output = output.gsub(" consular.rb delete.sh icon.png info.plist list.sh list.txt ", "\n").to_a[1..-1].join
  if verbose == true
    output = output.to_a
  else
    output = output.gsub(/ - (.)*\n/, "\n").to_a
  end
  output
end

# Run Apple Scripts
def osa(s)
  `osascript <<END\n#{s}\nEND`
end

def create_xml_menu(list, query)
  string = '<?xml version="1.0"?><items>'
  list.each do |item|
    if item.match('^' + query)

      string += '<item uid="'
      string += item
      string += '" arg="'
      string += item
      string += '" valid="yes" autocomplete="'
      string += item
      string += '"><title>'
      string += item
      string += '</title>'
      string += '<icon>icon.png</icon></item>'

    end
  end

  string += '</items>'

  return string

end

def update_list()
  File.open('list.txt', 'w') { |file| file.write(get_list(false).join(',')) }
end

# Create menu for Alfred script filter
def xml_menu(query)
  File.open('list.txt', 'r') { |file| return create_xml_menu(file.read.split(','), query) }
end

# Apple Script for activating terminal with new tab
# and optionally running other scripts in it.
def open_terminal(scripts = nil)
  script =  "tell application \"Terminal\" to activate\n"
  script += "set runningApps to {} as list\n"
  script += "tell application \"System Events\"\n"
  script +=   "repeat 30 times\n"
  script +=      "set runningApps to name of every application process whose visible is equal to true\n"
  script +=      "if runningApps contains \"Terminal\" then\n"
  script +=        "tell application \"Terminal\" to activate\n"
  script +=        "delay 1\n"
  script +=        "tell application \"System Events\" to tell process \"Terminal\" to keystroke \"t\" using command down\n"
  script +=        "tell application \"Terminal\"\n"
  script +=          "do script \"cd\" in first window\n"
  script +=          "do script \"clear\" in first window\n"
  script +=        "end tell\n"
  if scripts
    script +=      "#{scripts}\n"
  end
  script +=        "exit repeat\n"
  script +=      "end if\n"
  script +=    "end repeat\n"
  script +=  "end tell\n"
  script
end

# Apple Script for running scripts in terminal
def run_in_terminal(arr)
  script = "tell application \"Terminal\"\n"
  arr.each do |exe|
    script +=  "do script \"#{exe}\" in first window\n"
  end
  script += "end tell\n"
  script
end
