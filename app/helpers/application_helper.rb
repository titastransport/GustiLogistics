module ApplicationHelper

  def full_title(page_title = '')
    base_title = "GustiLogistics"
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end

  def flash_id(message_type)
    case message_type
    when "alert alert-info"     then :notice
    when "alert alert-success"  then :success
    when "alert alert-error"    then :alert
    when "alert alert-alert"    then :alert
    end
  end

end
