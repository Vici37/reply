require "./spec_helper"

module Reply
  describe ExpressionEditor do
    it "computes expression_height" do
      editor = SpecHelper.expression_editor
      editor.current_line = ":Hi"
      editor.expression_height.should eq 1

      editor.current_line = "print :Hel" \
                            "lo"
      editor.expression_height.should eq 2

      editor.current_line = ":at_edge__"
      editor.expression_height.should eq 2

      editor << "#{""}puts :this" \
                "symbol_is_a_too" \
                "_mutch_long_sym" \
                "bol"
      editor.insert_new_line(indent: 0)
      editor << ":with_a_ne" \
                "line"

      editor.expression_height.should eq 4 + 2
    end

    it "gives previous, current, and next line" do
      editor = SpecHelper.expression_editor
      editor << "aaa"
      editor.previous_line?.should be_nil
      editor.current_line.should eq "aaa"
      editor.next_line?.should be_nil

      editor.insert_new_line(indent: 0)
      editor << "bbb"
      editor.insert_new_line(indent: 0)
      editor << "ccc"
      editor.move_cursor_up

      editor.previous_line?.should eq "aaa"
      editor.current_line.should eq "bbb"
      editor.next_line?.should eq "ccc"
    end

    it "tells if cursor is on last line" do
      editor = SpecHelper.expression_editor
      editor.cursor_on_last_line?.should be_true

      editor << "aaa"
      editor.insert_new_line(indent: 0)
      editor.cursor_on_last_line?.should be_true

      editor << "bbb"
      2.times { editor.move_cursor_left }
      editor.cursor_on_last_line?.should be_true

      editor.move_cursor_up
      editor.cursor_on_last_line?.should be_false
    end

    it "gets expression_before_cursor" do
      editor = SpecHelper.expression_editor
      editor << "print :Hel" \
                "lo"
      editor.insert_new_line(indent: 0)
      editor << "puts :Bye"

      editor.expression_before_cursor.should eq "print :Hello\nputs :Bye"
      editor.expression_before_cursor(x: 0, y: 0).should eq ""
      editor.expression_before_cursor(x: 9, y: 0).should eq "print :He"
    end

    it "modify previous, current, and next line" do
      editor = SpecHelper.expression_editor
      editor << "aaa"

      editor.current_line = "AAA"
      editor.verify("AAA", x: 3, y: 0)

      editor.insert_new_line(indent: 0)
      editor << "bbb"
      editor.insert_new_line(indent: 0)
      editor << "ccc"
      editor.move_cursor_up

      editor.previous_line = "AAA"
      editor.current_line = "BBB"
      editor.next_line = "CCC"

      editor.verify("AAA\nBBB\nCCC", x: 3, y: 1)
    end

    it "deletes line" do
      editor = SpecHelper.expression_editor
      editor << "aaa\nbbb\nccc\n"

      editor.delete_line(1)
      editor.verify("aaa\nccc\n")

      editor.delete_line(0)
      editor.verify("ccc\n")

      editor.delete_line(1)
      editor.verify("ccc")

      editor.delete_line(0)
      editor.verify("")
    end

    it "clears expression" do
      editor = SpecHelper.expression_editor
      editor << "aaa\nbbb\nccc\n"
      editor.clear_expression
      editor.expression.should be_empty
    end

    it "insert chars" do
      editor = SpecHelper.expression_editor
      editor << 'a'
      editor.verify("a", x: 1, y: 0)

      editor.move_cursor_left
      editor << 'b'
      editor.verify("ba", x: 1, y: 0)

      editor << '\n'
      editor.verify("b\na", x: 0, y: 1)
    end

    it "ignores control characters" do
      editor = SpecHelper.expression_editor
      editor << "abc"

      editor << '\b'
      editor.verify("abc", x: 3, y: 0)

      editor << '\u007F' << '\u0002'
      editor.verify("abc", x: 3, y: 0)

      editor << "def\u007F\b\eghi\u0007"
      editor.verify("abcdefghi", x: 9, y: 0)
    end

    it "inserts new line" do
      editor = SpecHelper.expression_editor
      editor << "aaa"
      editor.insert_new_line(indent: 1)
      editor.verify("aaa\n  ", x: 2, y: 1)

      editor << "bbb"
      editor.move_cursor_up
      editor.insert_new_line(indent: 5)
      editor.insert_new_line(indent: 0)
      editor.verify("aaa\n          \n\n  bbb", x: 0, y: 2)
    end

    it "does delete & back" do
      editor = SpecHelper.expression_editor
      editor << "abc\n\ndef\nghi"
      editor.move_cursor_up
      2.times { editor.move_cursor_left }

      editor.delete
      editor.verify("abc\n\ndf\nghi", x: 1, y: 2)

      editor.back
      editor.verify("abc\n\nf\nghi", x: 0, y: 2)

      editor.back
      editor.verify("abc\nf\nghi", x: 0, y: 1)

      editor.back
      editor.verify("abcf\nghi", x: 3, y: 0)

      editor.delete
      editor.verify("abc\nghi", x: 3, y: 0)

      editor.delete
      editor.verify("abcghi", x: 3, y: 0)
    end

    # Empty interpolations `#{""}` are used to better show the influence of the prompt to line wrapping. '#{""}' takes 5 characters, like the prompt used for this spec: 'p:00>'.
    it "moves cursor left" do
      editor = SpecHelper.expression_editor
      editor << "#{""}print :Hel" \
                "lo\n"
      editor << "#{""}print :loo" \
                "ooooooooooooooo" \
                "oooooong\n"
      editor << "#{""}:end"

      editor.verify(x: 4, y: 2)

      4.times { editor.move_cursor_left }
      editor.verify(x: 0, y: 2)

      editor.move_cursor_left
      editor.verify(x: 33, y: 1)

      34.times { editor.move_cursor_left }
      editor.verify(x: 12, y: 0)

      20.times { editor.move_cursor_left }
      editor.verify(x: 0, y: 0)
    end

    # Empty interpolations `#{""}` are used to better show the influence of the prompt to line wrapping. '#{""}' takes 5 characters, like the prompt used for this spec: 'p:00>'.
    it "moves cursor right" do
      editor = SpecHelper.expression_editor
      editor << "#{""}print :Hel" \
                "lo\n"
      editor << "#{""}print :loo" \
                "ooooooooooooooo" \
                "oooooong\n"
      editor << "#{""}:end"
      editor.move_cursor_to_begin

      12.times { editor.move_cursor_right }
      editor.verify(x: 12, y: 0)

      editor.move_cursor_right
      editor.verify(x: 0, y: 1)

      34.times { editor.move_cursor_right }
      editor.verify(x: 0, y: 2)

      10.times { editor.move_cursor_right }
      editor.verify(x: 4, y: 2)
    end

    # Empty interpolations `#{""}` are used to better show the influence of the prompt to line wrapping. '#{""}' takes 5 characters, like the prompt used for this spec: 'p:00>'.
    it "moves cursor up" do
      editor = SpecHelper.expression_editor
      editor << "#{""}print :Hel" \
                "lo\n"
      editor << "#{""}print :loo" \
                "ooooooooooooooo" \
                "oooooong\n"
      editor << "#{""}:end"

      editor.verify(x: 4, y: 2)

      editor.move_cursor_up
      editor.verify(x: 33, y: 1)

      editor.move_cursor_up
      editor.verify(x: 18, y: 1)

      editor.move_cursor_up
      editor.verify(x: 3, y: 1)

      editor.move_cursor_up
      editor.verify(x: 12, y: 0)

      editor.move_cursor_up
      editor.verify(x: 0, y: 0)
    end

    # Empty interpolations `#{""}` are used to better show the influence of the prompt to line wrapping. '#{""}' takes 5 characters, like the prompt used for this spec: 'p:00>'.
    it "moves cursor down" do
      editor = SpecHelper.expression_editor
      editor << "#{""}print :Hel" \
                "lo\n"
      editor << "#{""}print :loo" \
                "ooooooooooooooo" \
                "oooooong\n"
      editor << "#{""}:end"
      editor.move_cursor_to_begin

      editor.move_cursor_down
      editor.verify(x: 12, y: 0)

      editor.move_cursor_down
      editor.verify(x: 0, y: 1)

      editor.move_cursor_down
      editor.verify(x: 15, y: 1)

      editor.move_cursor_down
      editor.verify(x: 30, y: 1)

      editor.move_cursor_down
      editor.verify(x: 0, y: 2)
    end

    it "moves cursor to" do
      editor = SpecHelper.expression_editor
      editor << "#{""}print :Hel" \
                "lo\n"
      editor << "#{""}print :loo" \
                "ooooooooooooooo" \
                "oooooong\n"
      editor << "#{""}:end"
      editor.move_cursor_to(x: 0, y: 1, allow_scrolling: false)
      editor.verify(x: 0, y: 1)

      editor.move_cursor_to(x: 3, y: 2, allow_scrolling: false)
      editor.verify(x: 3, y: 2)

      editor.move_cursor_to_begin(allow_scrolling: false)
      editor.verify(x: 0, y: 0)

      editor.move_cursor_to(x: 21, y: 1, allow_scrolling: false)
      editor.verify(x: 21, y: 1)

      editor.move_cursor_to(x: 12, y: 0, allow_scrolling: false)
      editor.verify(x: 12, y: 0)

      editor.move_cursor_to_end(allow_scrolling: false)
      editor.verify(x: 4, y: 2)

      editor.move_cursor_to_end_of_line(y: 0, allow_scrolling: false)
      editor.verify(x: 12, y: 0)

      editor.move_cursor_to_end_of_line(y: 1, allow_scrolling: false)
      editor.verify(x: 33, y: 1)
    end

    it "replaces" do
      editor = SpecHelper.expression_editor
      editor << "aaa\nbbb\nccc"

      editor.replace(["AAA", "BBBCCC"])
      editor.verify("AAA\nBBBCCC", x: 3, y: 1)
      editor.lines.should eq ["AAA", "BBBCCC"]

      editor.replace(["aaa", "", "ccc", "ddd"])
      editor.verify("aaa\n\nccc\nddd", x: 0, y: 1)
      editor.lines.should eq ["aaa", "", "ccc", "ddd"]

      editor.replace([""])
      editor.verify("", x: 0, y: 0)
      editor.lines.should eq [""]
    end

    # TODO:
    # update
    # end_editing
    # prompt_next
    # scroll_up
    # scroll_down
    # header
  end
end