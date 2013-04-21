#!/usr/bin/env ruby
require 'rubygems'
APPNAME = "Consular"

# Start project
def start(project)
  project = project.gsub(/\s+/, "")
  if recipe_exists(project)
    # Run consular recipe in terminal
    osa open_terminal(run_in_terminal(["consular start #{project}"], true))
    puts "Starting project: #{project}"
  else
    puts "Recipy not found: #{project}"
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
    `ruby consular.rb update`
    puts "Deleted recipe: #{recipe}"
  else
    puts "Recipy not found: #{recipe}"
  end
end

# List recipes
def list()
  list = get_list.join(', ').gsub("\n", "")
  # Show list on growl
  puts "List copied to clipboard - #{list}"
  long =  "Consular recipes:\n"
  long += "-----------------------------------------------\n"
  long += get_list(true).join('\n') + '\n'
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
  output = output.gsub(/[\w_\-]*?\.[rb|sh|png|plist|txt]*/, "\n").gsub(/^\s/, "").gsub(/\s$/, "").gsub(/\n\s\n/, "\n").split("\n")
  output.shift
  if verbose == true
    output = output
  else
    output = output.join(',') + ','
    output = output.gsub(/ - (.)*?,/, "\n").to_a
  end
  output
end

# Update project list
def update_list()
  list = get_list(true)
  list.each do |item|
    item = item.gsub(',', '&#44')
  end
  File.open('list.txt', 'w') { |file| file.write(list.join(',')) }
end

# Create menu for Alfred script filter
def xml_menu(query, icon)
  menu = []
  list = []
  File.open('list.txt', 'r') { |file| menu = file.read.split(',') }
  menu.each do |item|
    obj = {}
    arr = item.split(' - ')
    obj[:title] = arr.shift()
    if (arr.length > 0)
      obj[:subtitle] = arr.join(' - ')
    end
    list.push(obj)
  end
  return create_xml_menu(list, query, icon)
end

# Run Apple Scripts
def osa(s)
  `osascript <<END\n#{s}\nEND`
end

def create_xml_menu(list, query, icon)
  string = '<?xml version="1.0"?><items>'
  list.each do |item|
    if item[:title] && item[:title].match('^' + query)

      string += '<item uid="'
      string += item[:title]
      string += '" arg="'
      string += item[:title]
      string += '" valid="yes" autocomplete="'
      string += item[:title]
      string += '"><title>'
      string += item[:title]
      string += '</title>'
      if (item[:subtitle])
        string += '<subtitle>'
        string += item[:subtitle]
        string += '</subtitle>'
      end
      if (icon)
        string += '<icon>'
        string += icon
        string += '.png</icon>'
      end
      string += '</item>'

    end
  end

  string += '</items>'

  return string

end

# Apple Script for activating terminal with new tab
# and optionally running other scripts in it.
def open_terminal(scripts = nil)
  script =  "set terminalIsRunning to false as boolean\n"
  script += "tell application \"System Events\"\n"
  script +=   "set terminalCount to (count (processes whose name is \"Terminal\")) as number\n"
  script +=   "set terminalIsRunning to (terminalCount is not 0) as boolean\n"
  script += "end tell\n"
  script += "tell application \"Terminal\" to activate\n"
  script += "set runningApps to {} as list\n"
  script += "tell application \"System Events\"\n"
  script +=   "repeat 30 times\n"
  script +=      "set runningApps to name of every application process whose visible is equal to true\n"
  script +=      "if runningApps contains \"Terminal\" then\n"
  script +=        "tell application \"Terminal\" to activate\n"
  script +=        "delay 1\n"
  script +=        "if terminalIsRunning is true\n"
  script +=          "tell application \"System Events\" to tell process \"Terminal\" to keystroke \"t\" using command down\n"
  script +=        "end if\n"
  script +=        "tell application \"Terminal\"\n"
  script +=          "do script \"cd\" in first window\n"
  script +=          "do script \"clear\" in first window\n"
  script +=        "end tell\n"
  if scripts
    script +=      "#{scripts}\n"
    script +=      "tell application \"Terminal\"\n"
    script +=        "do script \"exit\" in first window\n"
    script +=      "end tell\n"
  end
  script +=        "exit repeat\n"
  script +=      "end if\n"
  script +=    "end repeat\n"
  script +=  "end tell\n"
  script
end

# Get path to Alfred directory
def get_current_dir()
  path = Dir.pwd()
  path = path + "/"
  return path
end

# Apple Script for running scripts in terminal
def run_in_terminal(arr, skipUpdate = false)
  path = get_current_dir()
  script = "tell application \"Terminal\"\n"
  arr.each do |exe|
    script += "do script \"#{exe}\" in first window\n"
  end
  if (skipUpdate != true)
    # Update project list after running command
    script +=   "do script \"cd '" + path + "'\" in first window\n"
    script +=   "do script \"ruby consular.rb update\" in first window\n"
  end
  script += "end tell\n"
end

# Init
if ARGV.size == 0
  if !File.exist?("list.txt")
    # Update project list if not available
    update_list()
  end
else
  args = ARGV[0].split(" ")
  case args[0]
  when "update"
    # Update project list
    update_list()
  end
end
