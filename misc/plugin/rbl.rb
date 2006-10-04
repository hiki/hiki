require "resolv"

def postable?
  dnsbl_list = (@conf['rbl.dnsbl_list'] || '').split
  if dnsbl_list.empty?
    dnsbl_list = ["niku.2ch.net"]
  end

  ip = ENV['REMOTE_ADDR'].scan(/\d+/).reverse.join(".")

  dnsbl_list.each do |dnsbl|
    begin
      Resolv.getaddress( "#{ip}.#{dnsbl}" )
        STDERR.puts "SPAM (RBL)"
        STDERR.puts "IP:#{address}"
        return false
    rescue Resolv::ResolvError
    rescue Exception
    end
  end
  return true
end
