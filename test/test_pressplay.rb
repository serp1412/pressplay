require 'minitest/autorun'
require 'pressplay'

class PressPlayTest < Minitest::Test
    def test_hello
        assert_equal "Hello World!", PressPlay.hi
    end
end
