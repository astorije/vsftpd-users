class UsersController < ApplicationController
  #before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_admin_or_no_user, :only => [:new, :create, :edit_password, :update_password]
  before_filter :require_user, :only => [:show, :edit, :update]
  before_filter :require_admin, :only => [:index, :destroy, :activate, :inactivate, :ban, :manage_groups, :update_groups, :grant_admin, :revoke_admin]
  before_filter :require_no_user, :only => [:new_password, :send_password]
  
  # Making sure users can only edit their account
  # def current_object
  #   @current_object ||= @current_user
  # end
  
  
  def current_object
    if !params[:id] || @current_user.id.to_s == params[:id]
      @current_object ||= @current_user
    elsif @current_user.is_admin?
      @current_object ||= User.find_by_id(params[:id])
    else
      @current_object = nil
      # @current_object ||= User.find_by_id(params[:id])
      # flash[:notice] = "You cannot access this account!"
      # redirect_back_or_default home_url
    end
    
    # if !@current_user.is_admin? && @current_user.id == params[:id]
    #   flash[:notice] = "forbidden #{params[:id]}"
    #   redirect_back_or_default home_url
    # else
    #   @current_object ||= @current_user
    # end
    
  end
  
  make_resourceful do
    actions :index, :show, :new, :create, :edit
    
    # before :show do
    #       if current_user.is_admin?
    #         #@servers = Server.all
    #         @servers = Server.paginate :page => params[:servers_page], :order => 'created_at DESC', :per_page => 5
    #         #@ftpusers = Ftpuser.all
    #         @ftpusers = Ftpuser.paginate :page => params[:ftpusers_page], :order => 'created_at DESC', :per_page => 5
    #         
    #         @groups = Group.paginate :page => params[:groups_page], :order => 'created_at DESC', :per_page => 5
    #       else
    #         @ftpusers = current_object.ftpusers.paginate :page => params[:ftpusers_page], :order => 'created_at DESC', :per_page => 5
    #       end
    #     end
    
    before :show, :edit, :destroy do
      if !@current_object
        flash[:error] = "You cannot access this account!"
        users_logger.info("#{Time.now} -- #{current_user.login}: Tried to access an unauthorized account (#{request.request_uri})")
        redirect_to home_url
      end
    end
      
    before :update do
      if current_object && @current_user.is_admin? && current_object != @current_user
        params[:user][:password] = params[:user][:password_confirmation] = nil
      end
    end
    
    after :create_fails, :update_fails do
      flash[:error] = flash[:notice] = ""
    end
    
  end
  
  def update
    if !current_object
      flash[:error] = "You cannot access this account!"
      users_logger.info("#{Time.now} -- #{current_user.login}: Tried to access an unauthorized account (#{request.request_uri})")
      redirect_to home_url
    end
    
    @user = current_object
    if @user && @current_user.is_admin? && @user != @current_user
      params[:user][:password] = params[:user][:password_confirmation] = nil
    end
    
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "This User has been updated successfully!"
        format.html { redirect_to(user_url(@user)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
      
  end
  
  def destroy
    if current_object != @current_user
      current_object.delete!
      current_object.destroy
      flash[:notice] = "This User has been deleted successfully!"
    else
      flash[:error] = "You cannot delete your own account!"
      users_logger.info("#{Time.now} -- #{current_user.login}: Tried to delete his own account (#{request.request_uri})")
    end

    respond_to do |format|
      format.html { redirect_to(users_url) }
    end
  end
  
  def activate
    if current_object != @current_user
      current_object.activate!
      flash[:notice] = "This User has been activated successfully!"
    else
      flash[:error] = "You cannot update your own state!"
      users_logger.info("#{Time.now} -- #{current_user.login}: Tried to update his own account (#{request.request_uri})")
    end
    redirect_to user_path(current_object)
  end
  
  def inactivate
    if current_object != @current_user
      current_object.inactivate!
      flash[:notice] = "This User has been inactivated successfully!"
    else
      flash[:error] = "You cannot update your own state!"
      users_logger.info("#{Time.now} -- #{current_user.login}: Tried to update his own state (#{request.request_uri})")
    end
    redirect_to user_path(current_object)
  end
  
  def ban
    if current_object != @current_user
      current_object.ban!
      flash[:notice] = "This User has been banned successfully!"
    else
      flash[:error] = "You cannot update your own state!"
      users_logger.info("#{Time.now} -- #{current_user.login}: Tried to update his own state (#{request.request_uri})")
    end
    redirect_to user_path(current_object)
  end
  
  def new_password
    @current_object = User.new
  end
  
  def send_password
    if @current_object = User.find_by_login(params[:user][:login])
      UserMailer.deliver_mail_for_a_new_password(@current_object)
      flash[:notice] = "An email has been sent to this User's email!"
      redirect_to(root_url)
    else
      @current_object = User.new
      flash[:error] = "You provided a wrong login!"
      #@current_object.error_messages = "You provided a wrong login!"
      #@current_object.errors.invalid?(:login) = :true
      render :new_password
    end
  end

  def edit_password
    
    if !(@user = User.find_by_perishable_token(params[:token]))
      flash[:error] = "You cannot change this password!"
      redirect_to(users_path)
    end
  end
     
  def update_password
    if @user = User.find_by_perishable_token(params[:user][:perishable_token])
      respond_to do |format|
        if @user.update_password(params[:user])
          flash[:notice] = "The password has been changed!"
          format.html { redirect_to(user_path(@user)) }
        else
          format.html { render :edit_password }
        end
      end
    else
      flash[:error] = "You cannot change this password!"
      redirect_to(root_url)
    end
  end
  
  def manage_groups
    @groups = Group.all
  end
  
  def update_groups
    current_object.update_groups(params[:user])
    respond_to do |format|
      flash[:notice] = "The Group list has been updated successfully!"
      format.html { redirect_to(user_url(current_object)) }
    end
  end
  
  def revoke_admin
    if current_object.is_admin?
      if current_object != @current_user 
        current_object.revoke_admin!
        flash[:notice] = "This User is not an administrator anymore!"
      else
        flash[:error] = "You cannot update your own rights!"
        users_logger.info("#{Time.now} -- #{current_user.login}: Tried to update his own rights (#{request.request_uri})")
      end
    else
      flash[:error] = "This User is not an administrator!"
    end
    redirect_to user_path(current_object)
  end
  
  def grant_admin
    if !current_object.is_admin?
      if current_object != @current_user 
        current_object.grant_admin!
        flash[:notice] = "This User is an administrator from now on!"
      else
        flash[:error] = "You cannot update your own rights!"
        users_logger.info("#{Time.now} -- #{current_user.login}: Tried to update his own rights (#{request.request_uri})")
      end
    else
      flash[:error] = "This User is already an administrator!"
    end
    redirect_to user_path(current_object)
  end
end
