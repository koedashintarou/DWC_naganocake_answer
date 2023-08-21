class Public::OrdersController < ApplicationController
  before_action :authenticate_customer!
  # before_action :ensure_cart_items, only: [:new, :confirm, :create, :error]

  def new
    @order = Order.new
  end

  def confirm
    @order = Order.new(order_params)
    # [:oders][:select_address]
    # require(:order).permit(:postal_code, :destination, :name, :payment_method)
    # permitの情報を持ってくるときは  # [:oders][:address_id]のように書く
    if params[:select_address] == '0'
      @order.get_shipping_informations_from(current_customer)
    elsif params[:select_address] == '1'
      @selected_address = current_customer.addresses.find(params[:address_id])
      @order.get_shipping_informations_from(@selected_address)
    elsif params[:select_address] == '2' && (@order.postal_code =~ /\A\d{7}\z/) && @order.destination? && @order.name?
      # 処理なし
    # 佐野さんはこれを消していた (@order.postal_code =~ /\A\d{7}\z/) && @order.destination? && @order.name?
    #   # https://gyazo.com/3c6e9f6265cef74343df4cf7e039f855
    # @address = Address.new(address_params)addressのストロングパラメーターも下に書く
    # @address.customer_id = current_customer.id
    # @address.save
    # @order.postal_code = @address.postal_code
    # @order.destination = @address.destination
    # @order.name = @address.name
    else
      flash[:error] = '情報を正しく入力して下さい。'
      render :new
    end
  end

  def error
  end

  def create
    @order = current_customer.orders.new(order_params)
    @order.shipping_cost = 800
    @order.grand_total = @order.shipping_cost + @cart_items.sum(&:subtotal)
    if @order.save
      @order.create_order_details(current_customer)
      redirect_to thanks_path
    else
      render :new
    end
  end

  def thanks
  end

  def index
    @orders = current_customer.orders.includes(:order_details, :items).page(params[:page]).reverse_order
  end

  def show
    @order = current_customer.orders.find(params[:id])
    @order_details = @order.order_details.includes(:item)
  end

  private

  def order_params
    params.require(:order).permit(:postal_code, :destination, :name, :payment_method)
  end

  def ensure_cart_items
  @cart_items = current_customer.cart_items.includes(:item)
  redirect_to items_path unless @cart_items.first
  end
end
