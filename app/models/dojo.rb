
require File.dirname(__FILE__) + '/../../lib/Disk'
require File.dirname(__FILE__) + '/../../app/models/Language'
require File.dirname(__FILE__) + '/../../app/models/Exercise'

class Dojo

  def initialize(dir)
    @dir = dir
  end

  def dir
    @dir
  end

  def [](id)
    Kata.new(self,id)
  end

  def language(name)
    Language.new(self,name)
  end

  def exercise(name)
    Exercise.new(self,name)
  end

  def create_kata(manifest)
    disk = Thread.current[:disk] || Disk.new
    kata = self[manifest[:id]]
    disk[kata.dir].write('manifest.rb', manifest)
    kata
  end

end
