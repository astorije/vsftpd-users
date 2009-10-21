module UsersHelper

  def group_list(user)
    list = user.groups.collect{ |group| link_to(group.name, group_path(group)) }.join(', ')
    list.empty? ? "&nbsp;" : list
  end
  
  def format_states(state)
    state.capitalize
  end
end
