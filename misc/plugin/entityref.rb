# $Id: entityref.rb,v 1.3 2004-03-01 09:50:45 hitoshi Exp $
# Copyright (C) 2003 yoshimi <yoshimik@iris.dti.ne.jp>

def e( str )
  if str.respond_to?(:integer?) || str =~ /^(\d+)/
    %Q[&\##{str};]
  else
    %Q[&#{str};]
  end
end

