{ ... }:

{
  services.mosquitto = {
    enable = false;
    listeners = [{
      address = "0.0.0.0";
      port = 1883;
      settings = { allow_anonymous = true; };
    }];
  };
}
