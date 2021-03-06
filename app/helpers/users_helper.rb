module UsersHelper

  def groups_links_list(user)
    list = user.groups.collect{ |group| link_to(group.name, group_path(group)) }.join(', ')
    list.empty? ? "&nbsp;" : list
  end
  
  def groups_list(user)
    list = user.groups.collect{ |group| group.name }.join(', ')
    list.empty? ? "&nbsp;" : list
  end
  
  def friendly_is_admin(is_admin)
    image_tag "user.png", :alt => "Is Admin", :title => "This User is Admin!" if is_admin
  end
end
