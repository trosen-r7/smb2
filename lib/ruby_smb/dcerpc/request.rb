module RubySMB
  module Dcerpc
    # The Request PDU as defined in
    # [The request PDU](http://pubs.opengroup.org/onlinepubs/9629399/chap12.htm#tagcjh_17_06_04_09)
    class Request < BinData::Record
      PTYPE = PTypes::REQUEST

      endian :little

      # PDU Header
      pdu_header :pdu_header, label: 'PDU header common fields'
      uint32     :alloc_hint, label: 'Allocation hint', initial_value: -> { stub.num_bytes }
      uint16     :p_cont_id,  label: 'Presentation context identification'
      uint16     :opnum,      label: 'Operation Number'
      uuid       :object,     label: 'Object UID', onlyif: -> { pdu_header.pfc_flags.object_uuid == 1 }

      # PDU Body
      choice :stub, label: 'Stub', selection: -> { @obj.parent.get_parameter(:endpoint) || '' } do
        string 'Encrypted'
        choice 'Winreg', selection: -> { opnum } do
          open_root_key_request  Winreg::OPEN_HKCR, opnum: Winreg::OPEN_HKCR
          open_root_key_request  Winreg::OPEN_HKCU, opnum: Winreg::OPEN_HKCU
          open_root_key_request  Winreg::OPEN_HKLM, opnum: Winreg::OPEN_HKLM
          open_root_key_request  Winreg::OPEN_HKPD, opnum: Winreg::OPEN_HKPD
          open_root_key_request  Winreg::OPEN_HKU,  opnum: Winreg::OPEN_HKU
          open_root_key_request  Winreg::OPEN_HKCC, opnum: Winreg::OPEN_HKCC
          open_root_key_request  Winreg::OPEN_HKPT, opnum: Winreg::OPEN_HKPT
          open_root_key_request  Winreg::OPEN_HKPN, opnum: Winreg::OPEN_HKPN
          close_key_request      Winreg::REG_CLOSE_KEY
          enum_key_request       Winreg::REG_ENUM_KEY
          enum_value_request     Winreg::REG_ENUM_VALUE
          open_key_request       Winreg::REG_OPEN_KEY
          query_info_key_request Winreg::REG_QUERY_INFO_KEY
          query_value_request    Winreg::REG_QUERY_VALUE
          create_key_request     Winreg::REG_CREATE_KEY
          save_key_request       Winreg::REG_SAVE_KEY
          string                 :default
        end
        choice 'Netlogon', selection: -> { opnum } do
          netr_server_authenticate3_request Netlogon::NETR_SERVER_AUTHENTICATE3
          netr_server_password_set2_request Netlogon::NETR_SERVER_PASSWORD_SET2
          netr_server_req_challenge_request Netlogon::NETR_SERVER_REQ_CHALLENGE
          string                            :default
        end
        choice 'Srvsvc', selection: -> { opnum } do
          net_share_enum_all_request Srvsvc::NET_SHARE_ENUM_ALL
          string             :default
        end
        choice 'Svcctl', selection: -> { opnum } do
          open_sc_manager_w_request       Svcctl::OPEN_SC_MANAGER_W
          create_service_w_request        Svcctl::CREATE_SERVICE_W
          open_service_w_request          Svcctl::OPEN_SERVICE_W
          query_service_status_request    Svcctl::QUERY_SERVICE_STATUS
          query_service_config_w_request  Svcctl::QUERY_SERVICE_CONFIG_W
          change_service_config_w_request Svcctl::CHANGE_SERVICE_CONFIG_W
          start_service_w_request         Svcctl::START_SERVICE_W
          control_service_request         Svcctl::CONTROL_SERVICE
          close_service_handle_request    Svcctl::CLOSE_SERVICE_HANDLE
          delete_service_request          Svcctl::DELETE_SERVICE
          string                          :default
        end
        choice 'Samr', selection: -> { opnum } do
          samr_connect_request                         Samr::SAMR_CONNECT
          samr_lookup_domain_in_sam_server_request     Samr::SAMR_LOOKUP_DOMAIN_IN_SAM_SERVER
          samr_open_domain_request                     Samr::SAMR_OPEN_DOMAIN
          samr_enumerate_users_in_domain_request       Samr::SAMR_ENUMERATE_USERS_IN_DOMAIN
          samr_rid_to_sid_request                      Samr::SAMR_RID_TO_SID
          samr_close_handle_request                    Samr::SAMR_CLOSE_HANDLE
          samr_get_alias_membership_request            Samr::SAMR_GET_ALIAS_MEMBERSHIP
          samr_open_user_request                       Samr::SAMR_OPEN_USER
          samr_get_groups_for_user_request             Samr::SAMR_GET_GROUPS_FOR_USER
          samr_enumerate_domains_in_sam_server_request Samr::SAMR_ENUMERATE_DOMAINS_IN_SAM_SERVER
          samr_lookup_names_in_domain_request          Samr::SAMR_LOOKUP_NAMES_IN_DOMAIN
          string                                       :default
        end
        choice 'Wkssvc', selection: -> { opnum } do
          netr_wksta_get_info_request Wkssvc::NETR_WKSTA_GET_INFO
          string                      :default
        end
        choice 'Epm', selection: -> { opnum } do
          epm_ept_map_request RubySMB::Dcerpc::Epm::EPT_MAP
          string                      :default
        end
        choice 'Drsr', selection: -> { opnum } do
          drs_bind_request                   Drsr::DRS_BIND
          drs_unbind_request                 Drsr::DRS_UNBIND
          drs_domain_controller_info_request Drsr::DRS_DOMAIN_CONTROLLER_INFO
          drs_crack_names_request            Drsr::DRS_CRACK_NAMES
          drs_get_nc_changes_request         Drsr::DRS_GET_NC_CHANGES
          string                      :default
        end
        string :default
      end
      string      :auth_pad,
        onlyif: -> { has_auth_verifier? },
        length: -> { (16 - (stub.num_bytes % 16)) % 16 }

      # Auth Verifier
      sec_trailer :sec_trailer, onlyif: -> { has_auth_verifier? }
      string      :auth_value, label: 'Authentication verifier',
        onlyif:      -> { has_auth_verifier? },
        read_length: -> { pdu_header.auth_length }

      def initialize_instance
        super
        pdu_header.ptype = PTYPE
      end

      def enable_encrypted_stub
        @params[:endpoint] = 'Encrypted'
      end

      def has_auth_verifier?
        self.pdu_header.auth_length > 0
      end

    end
  end
end
