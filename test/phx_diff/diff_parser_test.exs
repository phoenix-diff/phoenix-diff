defmodule PhxDiff.DiffParserTest do
  use ExUnit.Case, async: true

  import PhxDiff.TestSupport.Sigils

  alias PhxDiff.AppSpecification
  alias PhxDiff.Diff.Chunk
  alias PhxDiff.Diff.Line
  alias PhxDiff.Diff.Patch
  alias PhxDiff.DiffParser
  alias PhxDiff.TestSupport.DiffFixtures

  describe "round-trip fidelity" do
    for fixture <- Path.wildcard(Path.join([__DIR__, "..", "support", "diff_fixtures", "*.diff"])) do
      @fixture fixture
      test "#{Path.basename(fixture)}" do
        original = File.read!(@fixture)
        {:ok, patches} = DiffParser.parse(original)
        assert DiffParser.to_string(patches) == original
      end
    end
  end

  describe "parse/1 basics" do
    test "empty string returns empty list" do
      assert {:ok, []} = DiffParser.parse("")
    end

    test "returns a list of Patch structs" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.4.16|, []),
          AppSpecification.new(~V|1.4.17|, [])
        )

      {:ok, patches} = DiffParser.parse(diff)
      assert [%Patch{}] = patches
    end

    test "multi-file diff returns multiple patches" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.5.9|, []),
          AppSpecification.new(~V|1.5.9|, ["--live"])
        )

      {:ok, patches} = DiffParser.parse(diff)
      assert length(patches) == 17
    end
  end

  describe "parse/1 header extraction" do
    test "extracts from/to filenames for modified file" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.4.16|, []),
          AppSpecification.new(~V|1.4.17|, [])
        )

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "mix.exs"
      assert patch.to == "mix.exs"
    end

    test "extracts from=nil and to for new file" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.5.9|, []),
          AppSpecification.new(~V|1.5.9|, ["--live"])
        )

      {:ok, patches} = DiffParser.parse(diff)

      new_file = Enum.find(patches, &(&1.to == "lib/sample_app_web/live/page_live.ex"))
      assert new_file.from == nil
      assert Map.has_key?(new_file.headers, "new file mode")
      assert new_file.headers["new file mode"] == "100644"
    end

    test "extracts from and to=nil for deleted file" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.5.9|, []),
          AppSpecification.new(~V|1.5.9|, ["--live"])
        )

      {:ok, patches} = DiffParser.parse(diff)

      deleted_file = Enum.find(patches, &(&1.from == "assets/js/socket.js"))
      assert deleted_file.to == nil
      assert Map.has_key?(deleted_file.headers, "deleted file mode")
    end

    test "extracts rename from/to and similarity index" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.5.9|, []),
          AppSpecification.new(~V|1.5.9|, ["--live"])
        )

      {:ok, patches} = DiffParser.parse(diff)

      renamed = Enum.find(patches, &Map.has_key?(&1.headers, "rename from"))
      assert renamed.headers["rename from"] == "lib/sample_app_web/templates/page/index.html.eex"
      assert renamed.headers["rename to"] == "lib/sample_app_web/live/page_live.html.leex"
      assert renamed.headers["similarity index"] == "71%"
      assert renamed.from == "lib/sample_app_web/templates/page/index.html.eex"
      assert renamed.to == "lib/sample_app_web/live/page_live.html.leex"
    end

    test "extracts index header" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.4.16|, []),
          AppSpecification.new(~V|1.4.17|, [])
        )

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.headers["index"] == "3a39fc4..372d3d3 100644"
    end

    test "stores raw_headers preserving original lines" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.4.16|, []),
          AppSpecification.new(~V|1.4.17|, [])
        )

      {:ok, [patch]} = DiffParser.parse(diff)

      assert hd(patch.raw_headers) == "diff --git a/mix.exs b/mix.exs"
      assert "--- a/mix.exs" in patch.raw_headers
      assert "+++ b/mix.exs" in patch.raw_headers
    end

    test "uses diff --git paths for mode-only diffs with unquoted spaces" do
      diff =
        """
        diff --git a/dir b/script.sh b/dir b/script.sh
        old mode 100644
        new mode 100755
        """

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "dir b/script.sh"
      assert patch.to == "dir b/script.sh"
      assert patch.headers["old mode"] == "100644"
      assert patch.headers["new mode"] == "100755"
    end

    test "parses quoted paths with escaped characters" do
      diff =
        """
        diff --git "a/tab\\tfile.txt" "b/tab\\tfile.txt"
        index 3367afd..3e75765 100644
        --- "a/tab\\tfile.txt"
        +++ "b/tab\\tfile.txt"
        @@ -1 +1 @@
        -old
        +new
        """

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "tab\tfile.txt"
      assert patch.to == "tab\tfile.txt"
      assert patch.headers["file_a"] == "tab\tfile.txt"
      assert patch.headers["file_b"] == "tab\tfile.txt"
    end

    test "strips the trailing tab git adds to patch headers for paths with spaces" do
      diff =
        """
        diff --git a/file with space.txt b/file with space.txt
        index 3367afd..3e75765 100644
        --- a/file with space.txt\t
        +++ b/file with space.txt\t
        @@ -1 +1 @@
        -old
        +new
        """

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "file with space.txt"
      assert patch.to == "file with space.txt"
    end

    test "extracts copy metadata" do
      diff =
        """
        diff --git a/src.txt b/dst.txt
        similarity index 100%
        copy from src.txt
        copy to dst.txt
        """

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "src.txt"
      assert patch.to == "dst.txt"
      assert patch.headers["copy from"] == "src.txt"
      assert patch.headers["copy to"] == "dst.txt"
      assert patch.headers["similarity index"] == "100%"
    end

    test "extracts dissimilarity index metadata" do
      diff =
        """
        diff --git a/old.txt b/new.txt
        dissimilarity index 42%
        rename from old.txt
        rename to new.txt
        """

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "old.txt"
      assert patch.to == "new.txt"
      assert patch.headers["dissimilarity index"] == "42%"
    end
  end

  describe "parse/1 chunk parsing" do
    test "parses chunk metadata" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.4.16|, []),
          AppSpecification.new(~V|1.4.17|, [])
        )

      {:ok, [patch]} = DiffParser.parse(diff)
      [chunk] = patch.chunks

      assert %Chunk{} = chunk
      assert chunk.from_start == 33
      assert chunk.from_count == 7
      assert chunk.to_start == 33
      assert chunk.to_count == 7
      assert chunk.context == "defmodule SampleApp.MixProject do"
      assert chunk.header == "@@ -33,7 +33,7 @@ defmodule SampleApp.MixProject do"
    end

    test "handles multiple chunks per patch" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.5.9|, []),
          AppSpecification.new(~V|1.5.9|, ["--live"])
        )

      {:ok, patches} = DiffParser.parse(diff)

      multi_chunk = Enum.find(patches, &(length(&1.chunks) > 1))
      assert multi_chunk != nil
      assert length(multi_chunk.chunks) >= 2
    end

    test "handles chunk header without count (implicit 1)" do
      # @@ -0,0 +1,39 @@ means from_count=0, to_count=39
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.5.9|, []),
          AppSpecification.new(~V|1.5.9|, ["--live"])
        )

      {:ok, patches} = DiffParser.parse(diff)

      new_file = Enum.find(patches, &(&1.to == "lib/sample_app_web/live/page_live.ex"))
      [chunk] = new_file.chunks
      assert chunk.from_start == 0
      assert chunk.from_count == 0
      assert chunk.to_start == 1
      assert chunk.to_count == 39
    end

    test "patch with no chunks has empty chunks list" do
      # A pure rename with no content changes would have no chunks,
      # but our fixtures don't have that case. Test with a crafted input.
      diff = """
      diff --git a/old.txt b/new.txt
      similarity index 100%
      rename from old.txt
      rename to new.txt\
      """

      {:ok, [patch]} = DiffParser.parse(diff)
      assert patch.chunks == []
      assert patch.from == "old.txt"
      assert patch.to == "new.txt"
    end
  end

  describe "parse/1 line parsing" do
    test "parses line types, text, and raw prefixes" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.4.16|, []),
          AppSpecification.new(~V|1.4.17|, [])
        )

      {:ok, [patch]} = DiffParser.parse(diff)
      [chunk] = patch.chunks

      types = Enum.map(chunk.lines, & &1.type)
      assert :context in types
      assert :add in types
      assert :remove in types

      for {type, prefix} <- [add: "+", remove: "-", context: " "] do
        line = Enum.find(chunk.lines, &(&1.type == type))
        assert %Line{type: ^type} = line
        assert String.starts_with?(line.raw, prefix)

        if type == :context do
          assert line.text == String.slice(line.raw, 1..-1//1)
        else
          refute String.starts_with?(line.text, prefix)
          assert line.raw == prefix <> line.text
        end
      end
    end

    test "handles \\ No newline at end of file marker" do
      diff = """
      diff --git a/file.txt b/file.txt
      index 1234567..abcdef0 100644
      --- a/file.txt
      +++ b/file.txt
      @@ -1 +1 @@
      -old
      \\ No newline at end of file
      +new
      \\ No newline at end of file
      """

      {:ok, [patch]} = DiffParser.parse(diff)
      [chunk] = patch.chunks

      no_newline_lines = Enum.filter(chunk.lines, &(&1.type == :no_newline))
      assert length(no_newline_lines) == 2
      assert hd(no_newline_lines).raw == "\\ No newline at end of file"
    end

    test "counts additions and deletions correctly for new file" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.5.9|, []),
          AppSpecification.new(~V|1.5.9|, ["--live"])
        )

      {:ok, patches} = DiffParser.parse(diff)

      new_file = Enum.find(patches, &(&1.to == "lib/sample_app_web/live/page_live.ex"))
      [chunk] = new_file.chunks

      additions = Enum.count(chunk.lines, &(&1.type == :add))
      deletions = Enum.count(chunk.lines, &(&1.type == :remove))

      assert additions == 39
      assert deletions == 0
    end

    test "counts additions and deletions correctly for deleted file" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.5.9|, []),
          AppSpecification.new(~V|1.5.9|, ["--live"])
        )

      {:ok, patches} = DiffParser.parse(diff)

      deleted_file = Enum.find(patches, &(&1.from == "assets/js/socket.js"))
      [chunk] = deleted_file.chunks

      additions = Enum.count(chunk.lines, &(&1.type == :add))
      deletions = Enum.count(chunk.lines, &(&1.type == :remove))

      assert additions == 0
      assert deletions == 63
    end

    test "does not fabricate an empty context line from a trailing newline" do
      diff =
        """
        diff --git a/f.txt b/f.txt
        index abc..def 100644
        --- a/f.txt
        +++ b/f.txt
        @@ -1 +1 @@
        -old
        +new
        """

      {:ok, [patch]} = DiffParser.parse(diff)
      [chunk] = patch.chunks

      assert Enum.map(chunk.lines, & &1.raw) == ["-old", "+new"]
    end
  end

  describe "to_string/1" do
    test "empty list returns empty string" do
      assert DiffParser.to_string([]) == ""
    end

    test "to_string of individual patches can be joined" do
      diff =
        DiffFixtures.known_diff_for!(
          AppSpecification.new(~V|1.5.9|, []),
          AppSpecification.new(~V|1.5.9|, ["--live"])
        )

      {:ok, patches} = DiffParser.parse(diff)

      # Rendering all patches together should equal the full diff
      full = DiffParser.to_string(patches)
      assert full == diff
    end

    test "round-trips a git binary patch" do
      diff =
        """
        diff --git a/img.bin b/img.bin
        index eaf36c1daccfdf325514461cd1a2ffbc139b5464..5bd8bb897b13225c93a1d26baa88c96b7bd5d817 100644
        GIT binary patch
        literal 4
        LcmZQ!Wn%{b05$*@

        literal 4
        LcmZQzWMT#Y01f~L
        """

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "img.bin"
      assert patch.to == "img.bin"
      assert patch.headers["binary"] == true
      assert patch.chunks == []
      assert DiffParser.to_string([patch]) == diff
    end

    test "round-trips multi-file combined diffs" do
      diff =
        """
        diff --cc f1.txt
        index 45cf141,c376d89..4a6c5d6
        --- a/f1.txt
        +++ b/f1.txt
        @@@ -1,1 -1,1 +1,1 @@@
        - left
         -right
        ++left+right
        diff --cc f2.txt
        index 45cf141,c376d89..4a6c5d6
        --- a/f2.txt
        +++ b/f2.txt
        @@@ -1,1 -1,1 +1,1 @@@
        - left
         -right
        ++left+right
        """

      {:ok, patches} = DiffParser.parse(diff)

      assert length(patches) == 2
      assert Enum.map(patches, & &1.from) == ["f1.txt", "f2.txt"]
      assert Enum.map(patches, & &1.to) == ["f1.txt", "f2.txt"]

      assert Enum.map(patches, fn patch -> hd(patch.chunks).header end) == [
               "@@@ -1,1 -1,1 +1,1 @@@",
               "@@@ -1,1 -1,1 +1,1 @@@"
             ]

      assert DiffParser.to_string(patches) == diff
    end

    test "round-trips diff --combined headers" do
      diff =
        """
        diff --combined f.txt
        index 45cf141,c376d89..4a6c5d6
        --- a/f.txt
        +++ b/f.txt
        @@@ -1,1 -1,1 +1,1 @@@
        - left
         -right
        ++left+right
        """

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "f.txt"
      assert patch.to == "f.txt"
      assert DiffParser.to_string([patch]) == diff
    end
  end

  describe "edge cases" do
    test "diff with trailing newline round-trips" do
      diff =
        """
        diff --git a/f.txt b/f.txt
        index abc..def 100644
        --- a/f.txt
        +++ b/f.txt
        @@ -1 +1 @@
        -old
        +new
        """

      {:ok, patches} = DiffParser.parse(diff)
      assert DiffParser.to_string(patches) == diff
    end

    test "diff without trailing newline round-trips" do
      diff =
        """
        diff --git a/f.txt b/f.txt
        index abc..def 100644
        --- a/f.txt
        +++ b/f.txt
        @@ -1 +1 @@
        -old
        +new\
        """

      {:ok, patches} = DiffParser.parse(diff)
      assert DiffParser.to_string(patches) == diff
    end

    test "binary file diff with no chunks" do
      diff = """
      diff --git a/image.png b/image.png
      new file mode 100644
      Binary files /dev/null and b/image.png differ\
      """

      {:ok, [patch]} = DiffParser.parse(diff)
      assert patch.to == "image.png"
      assert patch.from == nil
      assert patch.chunks == []
      assert patch.headers["binary"] == true
      assert Map.has_key?(patch.headers, "new file mode")
    end

    test "chunk header with no context portion" do
      diff =
        """
        diff --git a/f.txt b/f.txt
        index abc..def 100644
        --- a/f.txt
        +++ b/f.txt
        @@ -1,3 +1,3 @@
         old
        -mid
        +new
         old
        """

      {:ok, [patch]} = DiffParser.parse(diff)
      [chunk] = patch.chunks

      assert chunk.context == nil
    end

    test "chunk header with context portion" do
      diff =
        """
        diff --git a/f.ex b/f.ex
        index abc..def 100644
        --- a/f.ex
        +++ b/f.ex
        @@ -10,3 +10,3 @@ defmodule Foo do
           old
        -  mid
        +  new
           old
        """

      {:ok, [patch]} = DiffParser.parse(diff)
      [chunk] = patch.chunks

      assert chunk.context == "defmodule Foo do"
    end

    test "implicit line count of 1 when count is omitted" do
      diff =
        """
        diff --git a/f.txt b/f.txt
        index abc..def 100644
        --- a/f.txt
        +++ b/f.txt
        @@ -1 +1 @@
        -old
        +new
        """

      {:ok, [patch]} = DiffParser.parse(diff)
      [chunk] = patch.chunks

      assert chunk.from_count == 1
      assert chunk.to_count == 1
    end

    test "empty context line (bare empty line in chunk body)" do
      # A chunk can contain a completely empty line representing an empty context line
      diff =
        "diff --git a/f.txt b/f.txt\nindex abc..def 100644\n--- a/f.txt\n+++ b/f.txt\n@@ -1,3 +1,3 @@\n\n-old\n+new\n"

      {:ok, [patch]} = DiffParser.parse(diff)
      [chunk] = patch.chunks

      empty_ctx = Enum.find(chunk.lines, &(&1.raw == ""))
      assert empty_ctx != nil
      assert empty_ctx.type == :context
      assert empty_ctx.text == ""
    end
  end

  describe "parse/1 error handling" do
    test "returns error for non-binary input" do
      assert_raise FunctionClauseError, fn ->
        DiffParser.parse(123)
      end
    end

    test "returns error for malformed diff input" do
      assert DiffParser.parse("not a diff") == {:error, :unrecognized_format}
    end
  end

  describe "parse/1 C-string escape sequences" do
    test "parses octal escape sequences in quoted paths" do
      # \\303\\251 is the octal encoding of the UTF-8 bytes for "é"
      diff =
        ~s|diff --git "a/caf\\303\\251.txt" "b/caf\\303\\251.txt"\n| <>
          ~s|index abc..def 100644\n| <>
          ~s|--- "a/caf\\303\\251.txt"\n| <>
          ~s|+++ "b/caf\\303\\251.txt"\n| <>
          ~s|@@ -1 +1 @@\n| <>
          ~s|-old\n| <>
          ~s|+new\n|

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "café.txt"
      assert patch.to == "café.txt"
    end

    test "parses \\n escape in quoted paths" do
      diff =
        ~s|diff --git "a/line\\nbreak.txt" "b/line\\nbreak.txt"\n| <>
          ~s|index abc..def 100644\n| <>
          ~s|--- "a/line\\nbreak.txt"\n| <>
          ~s|+++ "b/line\\nbreak.txt"\n| <>
          ~s|@@ -1 +1 @@\n| <>
          ~s|-old\n| <>
          ~s|+new\n|

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "line\nbreak.txt"
      assert patch.to == "line\nbreak.txt"
    end

    test "parses \\r escape in quoted paths" do
      diff =
        ~s|diff --git "a/cr\\rfile.txt" "b/cr\\rfile.txt"\n| <>
          ~s|index abc..def 100644\n| <>
          ~s|--- "a/cr\\rfile.txt"\n| <>
          ~s|+++ "b/cr\\rfile.txt"\n| <>
          ~s|@@ -1 +1 @@\n| <>
          ~s|-old\n| <>
          ~s|+new\n|

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "cr\rfile.txt"
      assert patch.to == "cr\rfile.txt"
    end

    test "parses escaped double quote in quoted paths" do
      diff =
        ~s|diff --git "a/say\\"hi\\".txt" "b/say\\"hi\\".txt"\n| <>
          ~s|index abc..def 100644\n| <>
          ~s|--- "a/say\\"hi\\".txt"\n| <>
          ~s|+++ "b/say\\"hi\\".txt"\n| <>
          ~s|@@ -1 +1 @@\n| <>
          ~s|-old\n| <>
          ~s|+new\n|

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "say\"hi\".txt"
      assert patch.to == "say\"hi\".txt"
    end

    test "parses escaped backslash in quoted paths" do
      diff =
        ~s|diff --git "a/back\\\\slash.txt" "b/back\\\\slash.txt"\n| <>
          ~s|index abc..def 100644\n| <>
          ~s|--- "a/back\\\\slash.txt"\n| <>
          ~s|+++ "b/back\\\\slash.txt"\n| <>
          ~s|@@ -1 +1 @@\n| <>
          ~s|-old\n| <>
          ~s|+new\n|

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "back\\slash.txt"
      assert patch.to == "back\\slash.txt"
    end
  end

  describe "parse/1 binary files with quoted paths" do
    test "parses Binary files line with quoted paths" do
      diff =
        ~s|diff --git "a/img\\tfile.png" "b/img\\tfile.png"\n| <>
          ~s|new file mode 100644\n| <>
          ~s|Binary files /dev/null and "b/img\\tfile.png" differ|

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == nil
      assert patch.to == "img\tfile.png"
      assert patch.headers["binary"] == true
    end
  end

  describe "parse/1 ambiguous headers" do
    test "malformed diff --git header still produces a patch" do
      diff =
        """
        diff --git malformed-no-a-b-prefix
        index abc..def 100644
        --- a/f.txt
        +++ b/f.txt
        @@ -1 +1 @@
        -old
        +new
        """

      {:ok, [patch]} = DiffParser.parse(diff)

      # from/to fall back to --- and +++ lines
      assert patch.from == "f.txt"
      assert patch.to == "f.txt"
    end

    test "split_unquoted_pair with single ambiguous candidate" do
      # Path contains " b/" in the middle, creating ambiguity
      # but only one candidate split exists because the paths differ
      diff =
        """
        diff --git a/x b/y
        index abc..def 100644
        --- a/x
        +++ b/y
        @@ -1 +1 @@
        -old
        +new
        """

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "x"
      assert patch.to == "y"
    end
  end

  describe "parse/1 chunk context edge cases" do
    test "combined diff @@@ header context is preserved" do
      diff =
        """
        diff --cc f.txt
        index 45cf141,c376d89..4a6c5d6
        --- a/f.txt
        +++ b/f.txt
        @@@ -1,1 -1,1 +1,1 @@@
        - left
         -right
        ++both
        """

      {:ok, [patch]} = DiffParser.parse(diff)
      [chunk] = patch.chunks

      # The @@@ header doesn't match the @@ regex, so it stores as-is
      assert chunk.header == "@@@ -1,1 -1,1 +1,1 @@@"
    end

    test "chunk context without leading space is returned as-is" do
      diff =
        """
        diff --git a/f.txt b/f.txt
        index abc..def 100644
        --- a/f.txt
        +++ b/f.txt
        @@ -1,3 +1,3 @@context_no_space
         old
        -mid
        +new
         old
        """

      {:ok, [patch]} = DiffParser.parse(diff)
      [chunk] = patch.chunks

      assert chunk.context == "context_no_space"
    end
  end

  describe "parse/1 C-string unknown escape fallback" do
    test "unknown escape sequence passes through the character" do
      # \\x is not a recognized C escape, so the fallback passes 'x' through
      diff =
        ~s|diff --git "a/\\xfile.txt" "b/\\xfile.txt"\n| <>
          ~s|index abc..def 100644\n| <>
          ~s|--- "a/\\xfile.txt"\n| <>
          ~s|+++ "b/\\xfile.txt"\n| <>
          ~s|@@ -1 +1 @@\n| <>
          ~s|-old\n| <>
          ~s|+new\n|

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "xfile.txt"
      assert patch.to == "xfile.txt"
    end
  end

  describe "parse/1 quoted path with trailing tab in metadata headers" do
    test "rename from quoted path with trailing tab" do
      diff =
        ~s|diff --git "a/tab\\tfile.txt" "b/new\\tfile.txt"\n| <>
          ~s|similarity index 100%\n| <>
          ~s|rename from "tab\\tfile.txt"\t\n| <>
          ~s|rename to "new\\tfile.txt"\t|

      {:ok, [patch]} = DiffParser.parse(diff)

      assert patch.from == "tab\tfile.txt"
      assert patch.to == "new\tfile.txt"
      assert patch.headers["rename from"] == "tab\tfile.txt"
      assert patch.headers["rename to"] == "new\tfile.txt"
    end
  end
end
