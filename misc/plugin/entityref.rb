def e( str )
  if str.respond_to?(:integer?) || str =~ /^(\d+)/
    %Q[&\##{str};]
  else
    %Q[&#{str};]
  end
end

