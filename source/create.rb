require 'consular'

if ARGV.size == 1
  create(ARGV[0])
  list()
end
