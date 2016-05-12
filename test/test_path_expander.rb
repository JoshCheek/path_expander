require "minitest/autorun"
require "path_expander"

class TestPathExpander < Minitest::Test
  attr_accessor :args
  attr_accessor :expander

  def setup
    self.args = []

    self.expander = PathExpander.new args, "*.rb"
  end

  def assert_filter_files exp, filter, files = %w[test/dog_and_cat.rb]
    ignore = StringIO.new filter
    act = expander.filter_files files, ignore
    assert_equal exp, act
  end

  def assert_process_args exp_files, exp_args, *args
    expander.args.concat args

    assert_equal [exp_files, exp_args], expander.process_args
  end

  def test_expand_dirs_to_files
    exp = %w[test/test_bad.rb test/test_path_expander.rb]

    assert_equal exp, expander.expand_dirs_to_files("test")
    assert_equal %w[Rakefile], expander.expand_dirs_to_files("Rakefile")
  end

  def test_filter_files_dir
    assert_filter_files [], "test/"
  end

  def test_filter_files_files
    assert_filter_files [], "test/*.rb"

    example = %w[test/file.rb test/sub/file.rb top/test/perf.rb]

    assert_filter_files example[1..-1], "test/*.rb", example
  end

  def test_filter_files_glob
    assert_filter_files [], "test*"
    assert_filter_files [], "test*", ["test/lib/woot.rb"]
    assert_filter_files [], "*.rb"
    assert_filter_files [], "*dog*.rb"
  end

  def test_filter_files_glob_miss
    miss = %w[test/dog_and_cat.rb]
    assert_filter_files miss, "test"
    assert_filter_files miss, "nope"
  end

  def test_process
    self.args.concat %w[test --seed 42]

    act = expander.process

    assert_equal %w[test/test_bad.rb test/test_path_expander.rb], act
    assert_equal %w[--seed 42], expander.args
    assert_equal %w[--seed 42], args # affected our original array (eg, ARGV)
  end

  def with_tempfile *lines
    require "tempfile"

    Tempfile.open("tmp") do |f|
      f.puts lines
      f.flush
      f.rewind

      yield f
    end
  end

  def test_process_args_at
    with_tempfile %w[test -test/test_bad.rb --seed 24] do |f|
      assert_process_args(%w[test/test_path_expander.rb],
                          %w[--seed 24],
                          "@#{f.path}")
    end
  end

  def test_process_args_dash_dir
    assert_process_args(%w[],
                        %w[],
                        "test", "-test")
  end

  def test_process_args_dash_file
    assert_process_args(%w[test/test_path_expander.rb],
                        %w[],
                        "test", "-test/test_bad.rb")

  end

  def test_process_args_dash_other
    assert_process_args(%w[],
                        %w[--verbose],
                        "--verbose")
  end

  def test_process_args_dir
    assert_process_args(%w[test/test_bad.rb test/test_path_expander.rb],
                        %w[],
                        "test")
  end

  def test_process_args_file
    assert_process_args(%w[test/test_path_expander.rb],
                        %w[],
                        "test/test_path_expander.rb")
  end

  def test_process_args_other
    assert_process_args(%w[],
                        %w[42],
                        "42")
  end

  def test_process_flags
    exp = %w[a b c]
    act = expander.process_flags %w[a b c]

    assert_equal exp, act
  end
end
