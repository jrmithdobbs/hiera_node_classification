class hiera_node_classification(
  $classes_scope = 'data::classes',
  $definitions_scope = 'data::definitions'
) {
  require stdlib
  # This will only work with hiera 1.2+ and :merge_behavior: [deep|deeper]
  $resources = merge(
    { 'class' => hiera_hash($classes_scope,{})},
    hiera_hash($definitions_scope,{})
  )
  mass_create_resources($resources)

  # This is mostly for debugging but could be extended for a ghetto caching impl
  file { "${::puppet_vardir}/state/hiera_classifier_state-${::clientcert}.json":
    ensure  => file,
    owner   => 'root',
    mode    => '0440',
    content =>
      inline_template(
        "<%= scope.lookupvar('hiera_classifier::resources').to_json -%>"
      ),
  }
}
