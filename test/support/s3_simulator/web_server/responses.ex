defmodule PhxDiff.S3Simulator.WebServer.Responses do
  @moduledoc false

  def render_list_objects_v2(bucket, objects, prefix) do
    contents =
      Enum.map_join(objects, "\n", fn object ->
        """
        <Contents>
          <Key>#{escape_xml(object.key)}</Key>
          <LastModified>#{DateTime.to_iso8601(object.last_modified)}</LastModified>
          <ETag>&quot;#{object.etag}&quot;</ETag>
          <Size>#{object.size}</Size>
          <StorageClass>STANDARD</StorageClass>
        </Contents>
        """
      end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
      <Name>#{escape_xml(bucket)}</Name>
      <Prefix>#{escape_xml(prefix)}</Prefix>
      <KeyCount>#{length(objects)}</KeyCount>
      <MaxKeys>1000</MaxKeys>
      <IsTruncated>false</IsTruncated>
      #{contents}
    </ListBucketResult>
    """
  end

  def render_error(code, message, resource) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <Error>
      <Code>#{escape_xml(code)}</Code>
      <Message>#{escape_xml(message)}</Message>
      <Resource>#{escape_xml(resource)}</Resource>
    </Error>
    """
  end

  defp escape_xml(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
