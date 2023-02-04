# Removes automatic element wrapper that is Rails' default "div.field_with_errors"
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
    html_tag.html_safe
end
