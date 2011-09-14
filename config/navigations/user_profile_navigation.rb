# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  navigation.selected_class = 'ui-state-active'

  # Item keys are normally added to list items as id.
  # This setting turns that off
  navigation.autogenerate_item_ids = false

  # Define the primary navigation
  navigation.items do |primary|
    primary.dom_class = 'local-nav'
    primary.item :user, "#{@user.display_name}", user_path(@user),
      :link => { :class => 'icon-profile_16_18-before' }
    primary.item :wall, 'Mural', show_mural_user_path(@user),
      :link => { :class => 'icon-wall_16_18-before' }
    primary.item :members, "Contatos: #{@user.friends.count}",
      user_friendships_path(@user, :profile => true), :class => 'big-separator',
      :link => { :class => 'icon-contacts_16_18-before' }
  end
end
