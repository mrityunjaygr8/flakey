# Rex server (https://superlogical.com).
#
# Enables the service only. Group membership is host policy: each host adds its
# own users with `users.groups.${config.services.rex.group}.members = [ … ]`
# (default group is "rex"), so this module does not need to know any username.
{inputs, ...}: {
  imports = [inputs.rex.nixosModules.default];

  services.rex.enable = true;
}
