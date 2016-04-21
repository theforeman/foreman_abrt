# Create feature for Smart Proxy
f = Feature.where(:name => 'Abrt').first_or_create
raise "Unable to create Abrt proxy feature: #{format_errors f}" if f.nil? || f.errors.any?
