require 'docdiff/diff/shortestpath'
require 'docdiff/diff/contours'
require 'thread'

class Diff
  class Speculative
    def initialize(a, b)
      @a = a
      @b = b
    end

    def lcs
      # Try speculative execution.
      result = nil

      tg = ThreadGroup.new

      # Since ShortestPath is faster than Contours if two sequences are very similar,
      # try it first.
      tg.add(Thread.new {
        #print "ShortestPath start.\n"
        result = ShortestPath.new(@a, @b).lcs
        Thread.exclusive {tg.list.each {|t| t.kill if t != Thread.current}}
        #print "ShortestPath win.\n"
      })

      # start Contours unless ShortestPath is already ended with first quantum, 
      tg.add(Thread.new {
        #print "Contours start.\n"
        result = Contours.new(@a, @b).lcs
        Thread.exclusive {tg.list.each {|t| t.kill if t != Thread.current}}
        #print "Contours win.\n"
      }) unless tg.list.empty?

      tg.list.each {|t| t.join}

      return result
    end
  end
end
