class AbrtReport < ActiveRecord::Base
  include Authorizable

  belongs_to_host

  validates :json, :presence => true
  #validates :reason, :presence => true
  validates :count, :numericality => { :only_integer => true, :greater_than => 0 }
  validates :duphash, :format => { :with => /\A[0-9a-fA-F]+\z/ }, :allow_blank => true

  #TODO
  scoped_search :on => [:reason, :duphash]

  def self.import(json)
    host = Host.find_by_name(json[:host])
    AbrtReport.transaction do
      json[:reports].each do |report|
        # import one report
        reason = nil # try extracting reason from the report
        reason ||= report[:full][:reason] if report[:full].has_key? :reason
        AbrtReport.create! :host => host, :count => report[:count], :json => report[:full].to_json,
                           :duphash => report[:duphash], :reason => reason,
                           :reported_at => report[:reported_at]
      end
    end
  end
end
