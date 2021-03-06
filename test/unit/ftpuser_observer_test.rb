require File.dirname(__FILE__) + '/../test_helper'

class FtpuserObserverTest < ActionMailer::TestCase
  context "FtpuserObserver: An unchanged password" do
    setup do
      Ftpuser.make
    end
    
    should "not send an email" do
      assert_did_not_send_email
    end
  end
  
  context "FtpuserObserver: A changed password" do
    setup do
      @admin = User.make(:admin_active)
      # @good_user = User.make(:user_active)
      # @bad_user = User.make(:user_active)
      @group = Group.make
      # @good_user.groups << @group
      @ftpuser = Ftpuser.make
      @ftpuser.group = @group
      @ftpuser.save
      @ftpuser.update_password({:password => "new_password", :password_confirmartion => "new_password"})
    end
    
    should "be seen as recently password changed" do
      assert @ftpuser.password_recently_changed?
    end
    
    should "send an email to the admins" do
      assert_sent_email do |email|
         email.subject =~ /password.*changed/ && email.to.include?(@admin.email)
       end
    end
  end
    
  context "FtpuserObserver: A changed password" do
    setup do
      # @admin = User.make(:admin_active)
      @good_user = User.make(:user_active)
      # @bad_user = User.make(:user_active)
      @group = Group.make
      @good_user.groups << @group
      @ftpuser = Ftpuser.make
      @ftpuser.group = @group
      @ftpuser.save
      @ftpuser.update_password({:password => "new_password", :password_confirmartion => "new_password"})
    end
      
    should "send an email to the groups' users" do
      assert_sent_email do |email|
         email.subject =~ /password.*changed/ && email.to.include?(@good_user.email)
       end
    end
  end
    
  context "FtpuserObserver: A changed password" do
    setup do
      # @admin = User.make(:admin_active)
      # @good_user = User.make(:user_active)
      @bad_user = User.make(:user_active)
      @group = Group.make
      # @good_user.groups << @group
      @ftpuser = Ftpuser.make
      @ftpuser.group = @group
      @ftpuser.save
      @ftpuser.update_password({:password => "new_password", :password_confirmartion => "new_password"})
    end
      
    should "not send an email to the users who don't belong the the Ftpuser's Group" do
         assert_did_not_send_email
    end
  end
end
