require "./term_size"

module Reply
  alias AutoCompleteProc = String, String -> {Array(String), String?}

  # Interface of auto-completion.
  #
  # It provides following important methods:
  #
  # * `complete_on`: Trigger the auto-completion given a *word_on_cursor* and expression before.
  # Stores the list of entries, and returns the *replacement* string.
  #
  # * `name_filter=`: Update the filtering of entries.
  #
  # * `display_entries`: Displays on screen the stored entries.
  # Highlight the one selected. (initially `nil`).
  #
  # * `selection_next`/`selection_previous`: Increases/decrease the selected entry.
  #
  # * `open`/`close`: Toggle display, clear entries if close.
  #
  # * `clear`: Like `close`, but display a empty space instead of nothing.
  class AutoCompletionInterface
    getter? open = false
    getter? cleared = false
    @selection_pos : Int32? = nil

    @scope_name = ""
    @all_entries = [] of String
    getter entries = [] of String
    property name_filter = ""

    def initialize(&@auto_complete : AutoCompleteProc)
    end

    def complete_on(name_filter : String, expression_before_word_on_cursor : String) : String?
      @all_entries, @scope_name = @auto_complete.call(name_filter, expression_before_word_on_cursor)
      self.name_filter = name_filter

      @entries.empty? ? nil : common_root(@entries)
    end

    def name_filter=(@name_filter)
      @selection_pos = nil
      @entries = @all_entries.select(&.starts_with?(@name_filter))
    end

    # If open, displays completion entries by columns, minimizing the height.
    # Highlight the selected entry (initially `nil`).
    #
    # If cleared, displays `clear_size` space.
    #
    # If closed, do nothing.
    #
    # Returns the actual displayed height.
    #
    # ameba:disable Metrics/CyclomaticComplexity
    def display_entries(io, color? = true, max_height = 10, min_height = 0) : Int32
      if cleared?
        min_height.times { io.puts }
        return min_height
      end

      return 0 unless open?
      return 0 if max_height <= 1

      height = 0

      # Print scope type name:
      io.print @scope_name.colorize(:blue).underline.toggle(color?)
      io.puts ":"
      height += 1

      if @entries.empty?
        (min_height - height).times { io.puts }
        return {height, min_height}.max
      end

      nb_rows = compute_nb_row(@entries, max_nb_row: max_height - height)

      columns = @entries.in_groups_of(nb_rows, filled_up_with: "")
      column_widths = columns.map &.max_of &.size.+(2)

      nb_cols = nb_cols_hold_in_term_width(column_widths)

      col_start = 0
      if pos = @selection_pos
        col_end = pos // nb_rows

        if col_end >= nb_cols
          nb_cols = nb_cols_hold_in_term_width(column_widths: column_widths[..col_end].reverse_each)

          col_start = col_end - nb_cols + 1
        end
      end

      nb_rows.times do |r|
        nb_cols.times do |c|
          c += col_start

          entry = columns[c][r]
          col_width = column_widths[c]

          # `...` on the last column and row:
          if (r == nb_rows - 1) && (c - col_start == nb_cols - 1) && columns[c + 1]?
            entry += ".."
          end

          # Entry to display:
          entry_str = entry.ljust(col_width)

          if r + c*nb_rows == @selection_pos
            # Colorize selection:
            if color?
              io.print entry_str.colorize.bright.on_dark_gray
            else
              io.print ">" + entry_str[...-1] # if no color, remove last spaces to let place to '*'.
            end
          else
            # Display entry_str, with @name_filter prefix in bright:
            unless entry.empty?
              io.print color? ? @name_filter.colorize.bright : @name_filter
              io.print entry_str.lchop(@name_filter)
            end
          end
        end
        io.print Term::Cursor.clear_line_after if color?
        io.puts
      end

      height += nb_rows

      (min_height - height).times { io.puts }

      {height, min_height}.max
    end

    # Increases selected entry.
    def selection_next
      return nil if @entries.empty?

      if (pos = @selection_pos).nil?
        new_pos = 0
      else
        new_pos = (pos + 1) % @entries.size
      end
      @selection_pos = new_pos
      @entries[new_pos]
    end

    # Decreases selected entry.
    def selection_previous
      return nil if @entries.empty?

      if (pos = @selection_pos).nil?
        new_pos = 0
      else
        new_pos = (pos - 1) % @entries.size
      end
      @selection_pos = new_pos
      @entries[new_pos]
    end

    def open
      @open = true
      @cleared = false
    end

    def close
      @selection_pos = nil
      @entries.clear
      @all_entries.clear
      @open = false
      @cleared = false
    end

    def clear
      close
      @cleared = true
    end

    private def nb_cols_hold_in_term_width(column_widths)
      nb_cols = 0
      width = 0
      column_widths.each do |col_width|
        width += col_width
        break if width > self.term_width
        nb_cols += 1
      end
      nb_cols
    end

    # Computes the min number of rows required to display entries:
    # * if all entries cannot fit in `max_nb_row` rows, returns `max_nb_row`,
    # * if there are less than 10 entries, returns `entries.size` because in this case, it's more convenient to display them in one column.
    private def compute_nb_row(entries, max_nb_row)
      if entries.size > 10
        # test possible nb rows: (1 to max_nb_row)
        1.to max_nb_row do |r|
          width = 0
          # Sum the width of each given column:
          entries.each_slice(r, reuse: true) do |col|
            width += col.max_of &.size + 2
          end

          # If width fit width terminal, we found min row required:
          return r if width < self.term_width
        end
      end

      {entries.size, max_nb_row}.min
    end

    private def term_width
      Term::Size.width
    end

    # Finds the common root text between given entries.
    private def common_root(entries)
      return "" if entries.empty?
      return entries[0] if entries.size == 1

      i = 0
      entry_iterators = entries.map &.each_char

      loop do
        char_on_first_entry = entries[0][i]?
        same = entry_iterators.all? do |entry|
          entry.next == char_on_first_entry
        end
        i += 1
        break if !same
      end
      entries[0][...(i - 1)]
    end
  end
end