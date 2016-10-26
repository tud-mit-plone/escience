module AppointmentsHelper
  def options_for_cycle
    cycles = {}
    l(:cycles).each_with_index do |index,value| 
      cycles[index] = value
    end
    return cycles
  end
  
  def link_to_appointment(appointment, options={})
    title = nil
    subject = nil
    text = options[:tracker] == false ? "##{appointment.id}" : "#{appointment.tracker} ##{appointment.id}"
    if options[:subject] == false
      title = truncate(appointment.subject, :length => 60)
    else
      subject = appointment.subject
      if options[:truncate]
        subject = truncate(subject, :length => options[:truncate])
      end
    end
    if options[:title] == false
      title = nil
    end
    if options[:link_text].nil?
      link_text = "#{h(appointment.tracker)} ##{appointment.id}"
    else
      link_text = options[:link_text]
    end

    if options[:link_text] != false
      s = link_to(link_text, {:controller => "appointments", :action => "show", :id => appointment},
                                                 :class => appointment.css_classes,
                                                 :title => title)
    else 
      s = ""
    end
    s << h("#{subject}") if subject
    s = h("#{appointment.project} - ") + s if options[:project]
    s
  end  
  
  def format_date_to_time(d)
    unless d.nil?
      return "#{sprintf("%02d",d.hour.to_i - d.zone.to_i)}:#{sprintf("%02d",d.min)}"
    else
      return "00:00"
    end
  end
  
  def render_appointment_tooltip(a)
    sd = a.start_date
    ed = a.due_date
#    out = '<div style="float:left;margin-right:20px;">'.html_safe+link_to_appointment(a, {:subject => false, :link_text => a.subject})+"</div>".html_safe
    out = "<div style=\"float:left;margin-right:20px;\"><h2>#{truncate(a.subject, :length => 60)}</h2></div>".html_safe
    out << '<div style="float:right;">'.html_safe+link_to("<i class='icon icon-pencil' style='color:#7D7D7D'></i>".html_safe,{:controller => 'appointments', :action => 'edit', :id => a.id}).html_safe+'</div>'.html_safe
    out << '<div style="float:right;">'.html_safe+link_to("<i class='icon icon-trash' style='color:#7D7D7D'></i>".html_safe, {:controller => 'appointments', :action => 'destroy', :id => a.id, :view => 'calendar'}, :remote => true, :method => :delete, :confirm => l(:text_are_you_sure)).html_safe+'</div>'.html_safe
    out << '<div class="clear"></div>'.html_safe
    out << textilizable(truncate(a.description, :length => 400)).html_safe unless h(a.description) == ''
    out << render_appointment_cycle(a) 
    out.html_safe
  end
  
  def render_appointment_cycle(a) 
    sd = a.start_date
    ed = a.due_date
    out = ""
    if a.cycle > 0
      out << '<table cellspacing="0" cellpadding="0"><tr>'.html_safe
          out << '<td style="padding:3px 4px;border: 1px solid #DADADA !important;border-right:2px solid #606060 !important">'.html_safe
      out << l(:cycles)[a.cycle].html_safe+'<br>'.html_safe
      unless sd.hour.to_i == 0
        out << format_date_to_time(sd).html_safe
      end
      unless ed.nil? || ed.hour.to_i == 0
        out << " - "+format_date_to_time(ed).html_safe
      end
      out << "</td>".html_safe
      unless ed.nil?
        out << '<td>'.html_safe+image_tag('arrow.png')+'</td>'.html_safe
        out << '<td style="padding:3px 4px;border: 1px solid #DADADA !important;border-right:2px solid #606060 !important">'.html_safe
        out << beautyfulDate(ed)+"</td>".html_safe
      end
      out << '</tr></table>'.html_safe
    else
      unless sd.hour.to_i == 0 && sd != ed && ed.nil?
        out << '<table cellspacing="0" cellpadding="0"><tr>'.html_safe
        if sd.hour.to_i == 0 && sd.min.to_i == 0
          out << '<td style="padding:3px 4px;border: 1px solid #DADADA !important;border-right:2px solid #DADADA !important;border-right:2px solid #606060 !important">'.html_safe
        else 
          out << '<td style="padding:3px 4px;border: 1px solid #DADADA !important; border-right:none !important; -moz-border-radius: 5px 0 0 5px;-webkit-border-radius: 5px 0 0 5px;-khtml-border-radius: 5px 0 0 5px;border-radius: 5px 0 0 5px;">'.html_safe
        end
        out << beautyfulDate(sd)+"</td>".html_safe
        out << '<td valign="top" style="padding:4px;border-top: 1px solid #DADADA !important; border-bottom: 1px solid #DADADA !important; border-right:2px solid #606060 !important; -moz-border-radius: 0 5px 5px 0px;-webkit-border-radius: 0 5px 5px 0px;-khtml-border-radius: 0 5px 5px 0px;border-radius: 0 5px 5px 0px;">'.html_safe+format_date_to_time(sd).html_safe+'</td>'.html_safe unless (sd.hour.to_i == 0 && sd.min.to_i == 0)
      end
      unless sd == ed || ed.nil? || ed.hour.to_i != 0
        out << '<td>'.html_safe+image_tag('arrow.png')+'</td>'.html_safe
        if ed.hour.to_i == 0 && ed.min.to_i == 0
          out << '<td style="padding:3px 4px;border: 1px solid #DADADA !important;border-right:2px solid #606060 !important">'.html_safe
        else 
          out << '<td style="padding:3px 4px;border: 1px solid #DADADA !important; border-right:none !important; -moz-border-radius: 5px 0 0 5px;-webkit-border-radius: 5px 0 0 5px;-khtml-border-radius: 5px 0 0 5px;border-radius: 5px 0 0 5px;">'.html_safe
        end
        out << beautyfulDate(ed)+"</td>".html_safe
        out << '<td valign="top" style="padding:4px;border-top: 1px solid #DADADA !important; border-bottom: 1px solid #DADADA !important; border-right:2px solid #606060 !important; -moz-border-radius: 0 5px 5px 0px;-webkit-border-radius: 0 5px 5px 0px;-khtml-border-radius: 0 5px 5px 0px;border-radius: 0 5px 5px 0px;">'.html_safe+format_date_to_time(ed).html_safe+'</td>'.html_safe unless (ed.hour.to_i == 0 && ed.min.to_i == 0)
      end
      unless sd.hour.to_i == 0 && sd != ed  && ed.nil?
          out << '</tr></table>'.html_safe
      end
    end
    return out.html_safe
  end
end