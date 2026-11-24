require "./app"
require "../db/migrations/**"
require "../db/seeders/**"
exit Silth::CLI.run(ARGV)
