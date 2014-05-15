#encoding: utf-8 
require "fileutils"
class ProductsController < ApplicationController
  set :views, ENV["VIEW_PATH"] + "/products"

  before do
    authenticate!
  end

  # GET /products
  get "/" do
    @products = Product.all

    haml :list, layout: :"../layouts/layout"
  end

  #get /products/new
  get "/new" do
    @product = Product.new
    @form_path = "/products/create"

    haml :new, layout: :"../layouts/layout"
  end
  #post /products/create { products: { }}
  post "/create" do
    params.merge!({:onsale => false})
    @product = Product.create(params[:product])

    redirect "/products?product=#{@product.id}" 
  end

  # GET /products/1
  get "/:id" do
    @product = Product.all(:id => params[:id]).first

    haml :show, layout: :"../layouts/layout"
  end

  #get /products/1/edit
  get "/:id/edit" do
    @product = Product.first(:id => params[:id])
    @form_path = "/products/#{@product.id}/update"
    
    haml :edit, layout: :"../layouts/layout"
  end

  #post /products/1/update
  post "/:id/update" do
    @product = Product.first(:id => params[:id])
    @product.update(params[:product])

    redirect "/products?product=#{@product.id}"
  end

  # post /products/1/onsale
  # params: 
  # onsale - true/false
  # whether on sale
  post "/:id/onsale" do
    @product = Product.first(:id => params[:id])
    @product.update(:onsale => params[:status])

    redirect "/products?product=#{@product.id}"
  end

  #delete /products/1
  delete "/:id" do
    @product = Product.first(:id => params[:id])
    @product.destroy
  end

  #upload image
  #post /products/1/image
  post "/:id/image" do
    @product = Product.first(:id => params[:id])

    image_name = params[:image][:filename].to_s
    image_data = params[:image][:tempfile].read

    image_dir = File.join(ENV["APP_ROOT_PATH"], "app/assets/images/products")
    FileUtils.mkdir_p(image_dir) unless File.exist?(image_dir)

    image_path = File.join(image_dir, image_name)
    image_name = Time.now.strftime("%Y%m%d%H%M%S-") + image_name if File.exist?(image_path)
    File.open(File.join(image_dir, image_name), "wb") { |f| f.write(image_data) }

    @product.update(:image => image_name)

    redirect "/products"
  end
end
