namespace :data do
  task remove: :environment do
    Domain.find_each do |domain|
      if domain.deleted == false
        domain.destroy
      end
    end
  end
end
