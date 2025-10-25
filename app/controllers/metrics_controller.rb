class MetricsController < ApplicationController
  def dashboard
    @metrics = MetricReport.new.generate
  end
end