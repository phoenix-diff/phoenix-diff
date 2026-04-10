defmodule PhxDiff.DiffManifest do
  @moduledoc """
  A structured manifest of file-level changes between two app specifications.
  """

  alias PhxDiff.AppSpecification

  defmodule AddedFile do
    @moduledoc """
    A file that exists only in the target application and reports added lines.
    """

    defstruct [:path, :added]

    @type t :: %__MODULE__{
            path: String.t(),
            added: non_neg_integer()
          }
  end

  defmodule DeletedFile do
    @moduledoc """
    A file that exists only in the source application and reports deleted lines.
    """

    defstruct [:path, :deleted]

    @type t :: %__MODULE__{
            path: String.t(),
            deleted: non_neg_integer()
          }
  end

  defmodule ModifiedFile do
    @moduledoc """
    A text file present in both applications with added and deleted line counts.
    """

    defstruct [:path, :added, :deleted]

    @type t :: %__MODULE__{
            path: String.t(),
            added: non_neg_integer(),
            deleted: non_neg_integer()
          }
  end

  defmodule RenamedFile do
    @moduledoc """
    A renamed text file that also includes added and deleted line counts.
    """

    defstruct [:path, :old_path, :added, :deleted]

    @type t :: %__MODULE__{
            path: String.t(),
            old_path: String.t(),
            added: non_neg_integer(),
            deleted: non_neg_integer()
          }
  end

  defmodule BinaryAddedFile do
    @moduledoc """
    A binary file that exists only in the target application.
    """

    defstruct [:path]

    @type t :: %__MODULE__{
            path: String.t()
          }
  end

  defmodule BinaryDeletedFile do
    @moduledoc """
    A binary file that exists only in the source application.
    """

    defstruct [:path]

    @type t :: %__MODULE__{
            path: String.t()
          }
  end

  defmodule BinaryModifiedFile do
    @moduledoc """
    A binary file present in both applications whose contents changed.
    """

    defstruct [:path]

    @type t :: %__MODULE__{
            path: String.t()
          }
  end

  defmodule PureRenamedFile do
    @moduledoc """
    A file rename with no content changes.
    """

    defstruct [:path, :old_path]

    @type t :: %__MODULE__{
            path: String.t(),
            old_path: String.t()
          }
  end

  defmodule BinaryRenamedFile do
    @moduledoc """
    A renamed binary file.
    """

    defstruct [:path, :old_path]

    @type t :: %__MODULE__{
            path: String.t(),
            old_path: String.t()
          }
  end

  @type file_entry ::
          AddedFile.t()
          | DeletedFile.t()
          | ModifiedFile.t()
          | RenamedFile.t()
          | BinaryAddedFile.t()
          | BinaryDeletedFile.t()
          | BinaryModifiedFile.t()
          | PureRenamedFile.t()
          | BinaryRenamedFile.t()

  defstruct [:source, :target, :total_files, :total_added, :total_deleted, :files]

  @type t :: %__MODULE__{
          source: AppSpecification.t(),
          target: AppSpecification.t(),
          total_files: non_neg_integer(),
          total_added: non_neg_integer(),
          total_deleted: non_neg_integer(),
          files: [file_entry()]
        }
end
