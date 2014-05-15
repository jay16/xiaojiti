#encoding: utf-8 
require "json"
class TransactionsController < ApplicationController
  set :views, ENV["VIEW_PATH"] + "/transactions"

  #无权限则登陆
  before "/:out_trade_no" do 
    pass if %(/checkout /done /notify).include?(request.path_info)
    authenticate!
  end

  #post /transactions/checkout
  post "/checkout" do
    #生成唯一out_trade_no
    out_trade_no = generate_out_trade_no

    options = {
      :partner           => Settings.alipay.pid,
      :key               => Settings.alipay.secret,
      :seller_email      => Settings.alipay.seller_email,
      :description       => params[:order],
      :out_trade_no      => out_trade_no,
      :subject           => "#{Settings.website.title}订单 - ￥" + params[:amount].to_s,
      :price             => params[:amount],
      :quantity          => 1,
      :discount          => '0.00',
      :return_url        => Settings.alipay.return_url,
      :notify_url        => Settings.alipay.notify_url
    }

    #创建订单
    Order.create({ 
      :out_trade_no => out_trade_no,
      :quantity => params[:quantity],
      :amount   => params[:amount],
      :detail   => params[:order],
      :ip       => remote_ip,
      :browser  => remote_browser,
      :created_at => DateTime.now,
      :updated_at => DateTime.now
    })

    redirect AlipayDualfun.trade_create_by_buyer_url(options)
  end

  # post /transactions/notify
  post "/notify" do
    find_or_create_transaction!

    haml :notify
  end

  # get /transactions/done
  get "/done" do
    @status, @transaction = find_or_create_transaction!
    @order = Order.all(:out_trade_no => @transaction.out_trade_no).first

    flash[:notice] = "付款成功啦!"
    haml :done, layout: :"../layouts/layout"
  end

  # show
  # get /transactions/:out_trade_no
  get "/:out_trade_no" do
    @transaction = Transaction.first(:out_trade_no => params[:out_trade_no])
    @order = Order.first(:out_trade_no => params[:out_trade_no])

    @columns = { 
      :out_trade_no => "订单号",
      :subject      => "订单标题",
      :total_fee    => "订单金额",
      :seller_actions => "卖家待做",
      :receive_name => "买家名称",
      :buyer_email => "买家邮箱",
      :receive_mobile => "买家手机号",
      :receive_address => "买家地址",
      :gmt_payment => "付款时间",
      :receive_zip  => "买家邮编"
    }

    haml :show, layout: :"../layouts/layout"
  end
 
  # wheth transaction over
  post "/:id/status" do
    @transaction = Transaction.first(:id => params[:id])
    @transaction.update(:status => params[:status])

    redirect "/admin?transaction=#{@transaction.id}"
  end

  def find_or_create_transaction!
    # %(WAIT_SELLER_SEND_GOODS WAIT_SELLER_SEND_GOODS).include?(params[:trade_status])
    transaction = Transaction.all(:out_trade_no => params[:out_trade_no]).first
    status = "action: "
    params.merge!({ ip: remote_ip, browser: remote_browser })

    #存在则更新，不存在则创建
    if transaction.nil?
      params.merge!({ created_at: DateTime.now, updated_at: DateTime.now })
      transaction = Transaction.create(params)
      status += "create; status: "
      status += (transaction.saved? ? "true" : "false")
    else
      params.merge!({ updated_at: DateTime.now })
      transaction.update(params)
      status += "update; status: " + (transaction.saved? ? "true" : "false")
    end

    [status, transaction]
  end


  def generate_out_trade_no
    ip_hex = remote_ip.split(".").map{ |is| ("%02X" %is.to_i).to_s }.join.hex
    Time.now.to_i.to_s + ip_hex.to_s + Order.count.to_s
  end

  not_found do
    "sorry, #{request.path_info} - not found!"
  end
end
