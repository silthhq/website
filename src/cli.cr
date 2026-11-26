require "./app"
require "./commands/**"
require "../db/migrations/**"
require "../db/seeders/**"
exit Silth::CLI.run(ARGV)
