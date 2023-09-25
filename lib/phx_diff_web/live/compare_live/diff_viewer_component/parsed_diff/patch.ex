  defstruct [:display_filename, :display_filename_hash, :status, :html_anchor, :summary]
          display_filename_hash: String.t(),
      display_filename_hash: :crypto.hash(:sha256, display_filename) |> Base.url_encode64(),