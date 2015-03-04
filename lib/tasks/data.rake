namespace :data do
  task remove: :environment do
    Domain.find_each do |domain|
      if domain.url =~ /.+\..+\..+/
        domain.destroy
      end
    end
  end

end
