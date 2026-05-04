require "test_helper"

class ActivityLogger::FileStoreTest < ActiveSupport::TestCase
  setup do
    @tmpdir = Dir.mktmpdir
    @store = ActivityLogger::FileStore.new(dir: @tmpdir)
    @user = users(:jaime)
  end

  teardown do
    FileUtils.remove_entry(@tmpdir)
  end

  test "append creates the file and writes a line" do
    @store.append(@user, "Hello")
    assert_equal [ "Hello" ], @store.recent(@user)
  end

  test "append appends to existing file" do
    @store.append(@user, "First")
    @store.append(@user, "Second")
    assert_equal [ "Second", "First" ], @store.recent(@user)
  end

  test "recent returns last N lines reversed" do
    5.times { |i| @store.append(@user, "Line #{i}") }
    assert_equal [ "Line 4", "Line 3", "Line 2" ], @store.recent(@user, 3)
  end

  test "recent returns empty array when file does not exist" do
    assert_equal [], @store.recent(@user)
  end

  test "read_all returns full file contents" do
    @store.append(@user, "Alpha")
    @store.append(@user, "Beta")
    assert_equal "Alpha\nBeta\n", @store.read_all(@user)
  end

  test "read_all returns empty string when file does not exist" do
    assert_equal "", @store.read_all(@user)
  end

  test "isolates logs per user" do
    other = users(:sofia)
    @store.append(@user, "mine")
    @store.append(other, "theirs")
    assert_equal [ "mine" ], @store.recent(@user)
    assert_equal [ "theirs" ], @store.recent(other)
  end

  test "rotates when file exceeds max_size" do
    store = ActivityLogger::FileStore.new(dir: @tmpdir, max_size: 50, max_files: 3)
    store.append(@user, "x" * 60)  # forces next append to rotate
    store.append(@user, "after rotate")

    rotated = Pathname.new(@tmpdir).join("user_#{@user.id}.log.1")
    assert rotated.exist?
    assert_equal [ "after rotate" ], store.recent(@user)
  end

  test "rotation creates numbered backups up to max_files" do
    store = ActivityLogger::FileStore.new(dir: @tmpdir, max_size: 10, max_files: 3)
    5.times { store.append(@user, "x" * 20) }

    base = Pathname.new(@tmpdir).join("user_#{@user.id}.log")
    assert base.exist?
    assert Pathname.new("#{base}.1").exist?
    assert Pathname.new("#{base}.2").exist?
    assert Pathname.new("#{base}.3").exist?
    # max_files=3 caps the rotation chain at .log.3 — older content is overwritten in place
    assert_not Pathname.new("#{base}.4").exist?
  end
end
