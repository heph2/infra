{
  terraform = {
    required_providers = {
      netcup = {
        source = "rixlhq/netcup";
      };
      supabase = {
        source = "supabase/supabase";
        version = "~> 1.0";
      };
    };
    backend.s3 = { };
  };

  # Credentials are supplied through NETCUP_* and SUPABASE_ACCESS_TOKEN.
  provider.netcup = { };
  provider.supabase = { };
}
