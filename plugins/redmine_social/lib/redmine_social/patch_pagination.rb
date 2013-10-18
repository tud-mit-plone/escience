module RemotePaginator
  class LinkRenderer < WillPaginate::ActionView::LinkRenderer
    protected
    def previous_or_next_page(page, text, classname)
      if page
        link(text, page, :class => classname)
      else
        tag(:a, text, :class => classname + ' btn btn-small disabled', :type => 'button')
      end
    end
    
    private
    def link(text, target, attributes = {})
      if target.is_a? Fixnum
        attributes[:rel] = rel_value(target)
        target = url(target)
      end
      p attributes
      attributes[:href] = target
      attributes["data-remote"] = true #This is added
      attributes[:class] += ' btn btn-small'
      tag(:a, text, attributes)
      end
    end
end
