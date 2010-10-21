class CardsController < ApplicationController
  before_filter :except => [:show] do
    if params[:cardset_id].nil?
      @card = Card.find(params[:id])
      @cardset = Cardset.find(@card.cardset_id)
    else
      @cardset = Cardset.find(params[:cardset_id])
    end
    require_login_as_admin(@cardset)
  end
  helper CardsHelper

  # GET /cards/1
  # GET /cards/1.xml
  def show
    @card = Card.find(params[:id])
    @comment = Comment.new(:card => @card)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @card }
    end
  end

  # GET /cards/new
  # GET /cards/new.xml
  def new
    @card = Card.new(:cardset_id => params[:cardset_id])
    @cardset = Cardset.find(params[:cardset_id])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @card }
    end
  end

  # GET /cards/1/edit
  def edit
    @card = Card.find(params[:id])
    @render_frame = @card.frame
    if @card.calculated_frame == @card.frame
      @card.frame = "Auto"
    end
  end

  def process_card
    if @card.frame == "Auto"
      @card.frame = @card.calculated_frame
    end
  end

  # POST /cards
  # POST /cards.xml
  def create
    @card = Card.new(params[:card])
    process_card

    respond_to do |format|
      if @card.save
        format.html { redirect_to(@card, :notice => 'Card was successfully created.') }
        format.xml  { render :xml => @card, :status => :created, :location => @card }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @card.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cards/1
  # PUT /cards/1.xml
  def update
    @card = Card.find(params[:id])

    respond_to do |format|
      if @card.update_attributes(params[:card])
        process_card
        @card.save!
        format.html { redirect_to(@card, :notice => 'Card was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @card.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cards/1
  # DELETE /cards/1.xml
  def destroy
    @card = Card.find(params[:id])
    @cardset = @card.cardset
    @card.destroy

    respond_to do |format|
      format.html { redirect_to(@cardset) }
      format.xml  { head :ok }
    end
  end
end
