module RubySMB
  module SMB2
    module CreateContext
      # [2.2.13.2.5 SMB2_CREATE_QUERY_MAXIMAL_ACCESS_REQUEST](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-smb2/5ea40835-5d40-4e85-977d-13cd745d3af8)
      class CreateQueryMaximalAccessRequest < BinData::Record
        NAME = CREATE_QUERY_MAXIMAL_ACCESS

        default_parameter length: 0

        endian :little
        file_time  :timestamp, label: 'Timestamp', onlyif: -> { length != 0 }
      end

      # [2.2.13.2.9 SMB2_CREATE_QUERY_ON_DISK_ID](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-smb2/6eb9162a-3278-4513-988a-6b52bed30fc3)
      class CreateQueryOnDiskIdRequest < BinData::Record
        NAME = CREATE_QUERY_ON_DISK_ID

        endian :little
      end

      class CreateContextRequest < CreateContext
        delayed_io :data, read_abs_offset: -> { abs_offset + data_offset } do
          choice  :data, selection: -> { name.snapshot } do
            create_query_maximal_access_request CREATE_QUERY_MAXIMAL_ACCESS, length: :data_length
            create_query_on_disk_id_request     CREATE_QUERY_ON_DISK_ID,     length: :data_length
            string                              :default,                    read_length: :data_length
          end
        end
      end

      class CreateContextArrayRequest < CreateContextArray
        default_parameters type: :create_context_request
      end
    end
  end
end