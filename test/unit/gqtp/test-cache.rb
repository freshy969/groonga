# -*- coding: utf-8 -*-
#
# Copyright (C) 2010  Ryo Onodera <onodera@clear-code.com>
# Copyright (C) 2010  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

class CacheTest < Test::Unit::TestCase
  include GroongaLocalGQTPTestUtils

  def setup
    setup_local_database
  end

  def teardown
    teardown_local_database
  end

  def test_cache_with_illegal_select
    assert_commands(<<EXPECTED, <<COMMANDS)
[true]
[true]
[true]
[true]
[1]
[true]
EXPECTED
table_create --name Site --flags TABLE_HASH_KEY --key_type ShortText
column_create --table Site --name title --flags COLUMN_SCALAR --type ShortText
table_create --name Terms --flags TABLE_PAT_KEY|KEY_NORMALIZE --key_type ShortText --default_tokenizer TokenBigram
column_create --table Terms --name blog_title --flags COLUMN_INDEX|WITH_POSITION --type Site --source title
load --table Site
[
 {"_key":"http://example.org/","title":"This is test record 1!"}
]
COMMANDS

    expected= <<EXPECTED
[]
[]
[true]
EXPECTED

    commands = <<COMMANDS
select --table Site --filter "<"
COMMANDS

    output = nil
    IO.popen(construct_command_line(@database_path), "w+") do |pipe|
      sleep 1
      pipe.write(commands)
      sleep 1
      pipe.write(commands)
      pipe.write("shutdown\n")
      output = pipe.read
    end
    assert_error_command_output(expected, output)
  end

  private
  def assert_error_command_output(expected, actual)
    actual = actual.gsub(/^\[\[(-63|0),[\d\.e\-]+,[\d\.e\-]+(,".*"|)\]/) do
      "[[#{$1},0.0,0.0#{$2}]"
    end
    assert_equal(expected, actual)
  end
end
