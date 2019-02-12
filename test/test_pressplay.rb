require 'minitest/autorun'
require 'pressplay'

class PressPlayTest < Minitest::Test
    def test_something
        assert_output (/No project or workspace found./) { PressPlay::Runner.run } 
    end
end
