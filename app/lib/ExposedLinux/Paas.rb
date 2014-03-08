
module ExposedLinux

  class Paas

    def initialize(disk,git,runner)
      @disk,@git,@runner = disk,git,runner
    end

    #- - - - - - - - - - - - - - - - - - - - - - - -

    def create_dojo(root,format)
      Dojo.new(self,root,format)
    end

    #- - - - - - - - - - - - - - - - - - - - - - - -

    def languages_each(languages)
      Dir.entries(path(languages)).select do |name|
        yield name if is_dir?(File.join(path(languages),name))
      end
    end

    def language_read(language,filename)
      dir(language).read(filename)
    end

    #- - - - - - - - - - - - - - - - - - - - - - - -

    def exercises_each(exercises)
      Dir.entries(path(exercises)).each do |name|
        yield name if is_dir?(File.join(path(exercises),name))
      end
    end

    def exercise_read(exercise,filename)
      dir(exercise).read(filename)
    end

    #- - - - - - - - - - - - - - - - - - - - - - - -

    def katas_each(katas)
      Dir.entries(path(katas)).each do |outer_dir|
        outer_path = File.join(path(katas),outer_dir)
        if is_dir?(outer_path)
          Dir.entries(outer_path).each do |inner_dir|
            inner_path = File.join(outer_path,inner_dir)
            if is_dir?(inner_path)
              yield outer_dir+inner_dir
            end
          end
        end
      end
    end

    def make_kata(language, exercise, now = make_time(Time.now), id = Uuid.new.to_s)
      kata = Kata.new(language.dojo,id)
      dir(kata).make
      manifest = {
        :created => now,
        :id => id,
        :language => language.name,
        :exercise => exercise.name,
        :unit_test_framework => language.unit_test_framework,
        :tab_size => language.tab_size
      }
      manifest[:visible_files] = language.visible_files
      manifest[:visible_files]['output'] = ''
      manifest[:visible_files]['instructions'] = exercise.instructions
      dir(kata).write(kata.manifest_filename, manifest)
      kata
    end

    def kata_read(kata,filename)
      dir(kata).read(filename)
    end

    #- - - - - - - - - - - - - - - - - - - - - - - -

    def avatars_each(kata)
      Dir.entries(path(kata)).each do |name|
        yield name if is_dir?(File.join(path(kata),name))
      end
    end

    def start_avatar(kata)
      avatar = nil
      dir(kata).lock do
        started_avatar_names = kata.avatars.collect { |avatar| avatar.name }
        unstarted_avatar_names = Avatar.names - started_avatar_names
        if unstarted_avatar_names != [ ]
          avatar_name = unstarted_avatar_names.shuffle[0]
          avatar = Avatar.new(kata,avatar_name)

#         @disk[path].make
          dir(avatar).make

#         @git.init(path, "--quiet")
          @git.init(path(avatar), '--quiet')

#         dir.write(visible_files_filename, @kata.visible_files)
          dir(avatar).write(avatar.visible_files_filename, kata.visible_files)

#         @git.add(path, visible_files_filename)
          @git.add(path(avatar), avatar.visible_files_filename)

#         dir.write(traffic_lights_filename, [ ])
          dir(avatar).write(avatar.traffic_lights_filename, [ ])

#         @git.add(path, traffic_lights_filename)
          @git.add(path(avatar), avatar.traffic_lights_filename)
#
#         @kata.visible_files.each do |filename,content|
#           sandbox.dir.write(filename, content)
#           @git.add(sandbox.path, filename)
#         end
          kata.visible_files.each do |filename,content|
            dir(avatar.sandbox).write(filename,content)
            @git.add(path(avatar.sandbox), filename)
          end

#         @kata.language.support_filenames.each do |filename|
#           old_name = @kata.language.path + filename
#           new_name = sandbox.path + filename
#           @disk.symlink(old_name, new_name)
#         end
          kata.language.support_filenames.each do |filename|
            old_name = path(kata.language) + filename
            new_name = path(avatar.sandbox) + filename
            @disk.symlink(old_name, new_name)
          end

#         git_commit(tag=0)
          commit(avatar,tag=0)
        end #if
      end #dir.lock do
    avatar
    end

    def save(avatar,delta,visible_files)
      #...
      #from sandbox.
      #delta[:changed].each do |filename|
      #  dir.write(filename, visible_files[filename])
      #end
      delta[:changed].each do |filename|
        dir(avatar.sandbox).write(filename, visible_files[filename])
      end

      #delta[:new].each do |filename|
      #  dir.write(filename, visible_files[filename])
      #  @git.add(path, filename)
      #end
      delta[:new].each do |filename|
        dir(avatar.sandbox).write(filename, visible_files[filename])
        @git.add(path, filename)
      end

      #delta[:deleted].each do |filename|
      #  @git.rm(path, filename)
      #end
      delta[:deleted].each do |filename|
        @git.rm(path(avatar.sandbox), filename)
      end
    end

    def test(avatar, max_duration)
      output = @runner.run(path(avatar.sandbox), "./cyber-dojo.sh", max_duration)
      output.encode('utf-8', 'binary', :invalid => :replace, :undef => :replace)
    end

    def save_traffic_light(avatar,traffic_light,now)
      #...
      #lights = traffic_lights
      #lights << traffic_light
      #traffic_light['number'] = lights.length
      #traffic_light['time'] = now
      #dir.write(traffic_lights_filename, lights)
      #lights
      #...
      lights = traffic_lights(avatar)
      lights << traffic_light
      traffic_light['number'] = lights.length
      traffic_light['time'] = now
      dir(avatar).write(avatar.raffic_lights_filename, lights)
      lights
    end

    def commit(avatar,tag)
      #...from avatar
      @git.commit(path(avatar), "-a -m '#{tag}' --quiet")
      @git.tag(path(avatar), "-m '#{tag}' #{tag} HEAD")
    end

    # - - - - - - - - - - - - - - - - - -

    def visible_files(avatar,tag)
      #...from avatar
      #parse(unlocked_read(visible_files_filename, tag))
      #...
      #parse(unlocked_read(avatar.visible_files_filename, tag))
    end

    def traffic_lights(avatar,tag)
      #...from avatar
      #parse(unlocked_read(traffic_lights_filename, tag))
      #...
      #parse(unlocked_read(avatar.traffic_lights_filename, tag))
    end

    #def avatar.unlocked_read(filename, tag)
    #  dir.lock {
    #    locked_read(filename, tag)
    #  }
    #end
    #
    #def avatar.locked_read(filename, tag)
    #  if tag != nil
    #    @git.show(path, "#{tag}:#{filename}")
    #  else
    #    dir.read(filename)
    #  end
    #end
    #def avatar.parse(text)
    #  if format == 'rb'
    #    return JSON.parse(JSON.unparse(eval(text)))
    #  end
    #  if format == 'json'
    #    return JSON.parse(text)
    #  end
    #end


    def diff_lines(avatar,was_tag, now_tag)
      #...from avatar
      command = "--ignore-space-at-eol --find-copies-harder #{was_tag} #{now_tag} sandbox"
      output = @git.diff(path(avatar), command)
      output.encode('utf-8', 'binary', :invalid => :replace, :undef => :replace)
    end

    #- - - - - - - - - - - - - - - - - - - - - - - -

    def dir(obj)
      @disk[path(obj)]
    end

    def path(obj)
      case obj
        when ExposedLinux::Languages
          obj.dojo.path + 'languages/'
        when ExposedLinux::Language
          path(obj.dojo.languages) + obj.name + '/'
        when ExposedLinux::Exercises
          obj.dojo.path + 'exercises/'
        when ExposedLinux::Exercise
          path(obj.dojo.exercises) + obj.name + '/'
        when ExposedLinux::Katas
          obj.dojo.path + 'katas/'
        when ExposedLinux::Kata
          path(obj.dojo.katas) + obj.id[0..1] + '/' + obj.id[2..-1] + '/'
        when ExposedLinux::Avatar
          path(obj.kata) + obj.name + '/'
        when ExposedLinux::Sandbox
          path(obj.avatar) + 'sandbox/'
      end
    end

  private

    def is_dir?(name)
      File.directory?(name) && !name.end_with?('.') && !name.end_with?('..')
    end

    def make_time(now)
      [now.year, now.month, now.day, now.hour, now.min, now.sec]
    end

  end

end

# idea is that this will hold methods that forward to external
# services namely: disk, git, shell.
# And I will create another implementation IsolatedDockerPaas
# Design notes
#
# o) locking is not right.
#    I need a 'Paas::Session' object which can scope the lock/unlock
#    over a sequence of actions.
#
# o) IsolatedDockerPaas.disk will have smarts to know if reads/writes
#    are local to disk (eg exercises) or need to go into container.
#    ExposedLinuxPaas.disk can have several dojos (different root-dirs eg testing)
#    so parent refs need to link back to dojo which
#    will be used by paas to determine paths.
#
# o) how will IsolatedDockerPaas know a languages'
#    initial visible_files? use same manifest format?
#    seems reasonable. Could even repeat the languages subfolder
#    pattern. No reason a Docker container could not support
#    several variations of language/unit-test.
#       - the docker container could have ruby code installed to
#         initialize an avatar from a language. All internally.
#         would save many docker run calls. Optimization.
#
# o) tests could be passed a paas object which they will use
#    idea is to repeat same test for several paas objects
#    eg one that spies completely
#    eg one that uses ExposedLinuxPaas
#    eg one that uses IsolatedDockerPaas
