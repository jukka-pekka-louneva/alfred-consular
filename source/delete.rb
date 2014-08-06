require 'consular'

if ARGV.size == 1
  delete(ARGV[0])
  list()
end
