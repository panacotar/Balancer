class HealthchecksController < ActionController::Base
  def show
    ActiveRecord::Base.connection_pool.with_connection { |connection| connection.select_value('SELECT 1') }
    head :ok
  rescue ActiveRecord::ActiveRecordError, PG::Error
    head :service_unavailable
  end
end
