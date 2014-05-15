require "./config/boot.rb"

map("/products") { run ProductsController }
map("/admin") { run AdminController }
map("/transactions") { run TransactionsController }
map("/") { run HomeController }


#run Sinatra::Application
#Rack::Handler::Thin.run @app, :Port => 3000
