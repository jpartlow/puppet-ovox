# This structure provides a consistent mapping of Target arrays to the
# ov_role module roles that need to be applied within the cluster to
# install and configure OpenVox services.
#
# The keys are the spefic ov_role::<role_name>.
type Ovox::RoleMap = Struct[{
  primary     => Array[Target,1,1],
  ovdb        => Array[Target],
  postgres    => Array[Target],
  compiler    => Array[Target],
  compiler_lb => Array[Target],
  ovdb_lb     => Array[Target],
}]
