class ActivityLogger
  class FileStore
    mattr_accessor :default_dir, default: Rails.root.join("storage", "activity_logs")

    def initialize(dir: self.class.default_dir,
                   max_size: 1.megabyte,
                   max_files: 5)
      @dir = Pathname.new(dir)
      @max_size = max_size
      @max_files = max_files
    end

    def append(user, line)
      path = path_for(user)
      FileUtils.mkdir_p(path.dirname)
      rotate(path) if path.exist? && path.size >= @max_size
      File.open(path, "a") { |f| f.puts line }
    end

    def recent(user, count = 50)
      path = path_for(user)
      return [] unless path.exist?

      File.readlines(path, chomp: true).last(count).reverse
    end

    def read_all(user)
      path = path_for(user)
      path.exist? ? path.read : ""
    end

    private

    def path_for(user)
      @dir.join("user_#{user.id}.log")
    end

    def rotate(path)
      (@max_files - 1).downto(1) do |i|
        old_path = Pathname.new("#{path}.#{i}")
        new_path = Pathname.new("#{path}.#{i + 1}")
        FileUtils.mv(old_path, new_path) if old_path.exist?
      end
      FileUtils.mv(path, Pathname.new("#{path}.1"))
    end
  end
end
