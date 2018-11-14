class SummariesController < ApiController
  
  load_and_authorize_resource
  before_action :authenticate_user!

   # GET /for_user
  def for_user
    begin
      summary = Summary.current_by_user current_user    
      render json: summary
    rescue Exception => e
      summary = Summary.new
      summary.errors.add(:error_getting_summary, "Existió un error obteniendo el resumen.")
      render json: ErrorSerializer.serialize(summary.errors), status: 500
    end
  end

  def by_period_and_user_with_downlines_1_level
    begin
      summaries_with_downlines = Summary.by_period_and_user_with_downlines_1_level User.find(params[:user_id]), 
        params[:period_start], params[:period_end]
      
      render json: UserWithSummarySerializer.serialize(summaries_with_downlines)
    rescue Exception => e
      summary = Summary.new
      summary.errors.add(:error_getting_summary_for_users, "Existió un error obteniendo el resumen por periodo.")
      render json: ErrorSerializer.serialize(summary.errors), status: 500
    end
  end

  def by_period_with_downlines
    begin
      summaries_with_downlines = Summary.by_period_for_user_with_downlines current_user, params[:period_start], params[:period_end]
      render json: UserWithSummarySerializer.serialize(summaries_with_downlines)
    rescue Exception => e
      summary = Summary.new
      summary.errors.add(:error_getting_summary_for_users, "Existió un error obteniendo el resumen por periodo.")
      render json: ErrorSerializer.serialize(summary.errors), status: 500
    end
  end

  def send_by_email
    begin
      AsynchSummaryJob.perform_later(current_user, {period_start: params[:period_start], period_end: params[:period_end]})
      render status: :ok
    rescue Exception => e
      summary = Summary.new
      summary.errors.add(:error_sending_summary_for_user, "Existió un error enviando el resumen.")
      render json: ErrorSerializer.serialize(summary.errors), status: 500
    end
  end 

end
