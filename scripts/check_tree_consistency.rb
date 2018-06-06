#!/usr/bin/env ruby
require_relative "../config/environment"

User.where("active = ?", true).each do |user|
  puts "checando árbol para usuario con ID #{user.external_id}"

  correct_tree = User.check_tree_consistency_placement user

  unless correct_tree
    #break
  end
end
