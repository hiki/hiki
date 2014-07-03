# Copyright (C) 2003 yoshimi <yoshimik@iris.dti.ne.jp>

def e( str )
  if str.respond_to?(:integer?) || str =~ /^(\d+)/
    %Q[&\##{str};]
  else
    %Q[&#{str};]
  end
end

