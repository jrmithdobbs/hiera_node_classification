module Puppet::Parser::Functions
  newfunction(:mass_create_resources, :doc => <<-'ENDHEREDOC') do |args|
    Defines resources from a hash structured like (JSON):

      {
        "fully::qualified::type": {
          "title": "fully::qualified::type3::%{::type_name_with_interpolation}"
        , "somename": { <object hash> }
        , "somename2-%{::myfact}": { "title": "somename2-%{::myfact", "hiera_delete": "true", ... }
        , "unique_lexical_name": { "title": "%{::myfact2}_something", ... }
        , "unique_lexical_names": { "title": ["%{::myfact}_something", "%{::myotherfact}_something"], ... }
        }
      , "fully::qualified::type2": { ... }
      }

    This allows defining object names using %{value} interpolation within hiera data
    sources.

    ENDHEREDOC

    Puppet::Parser::Functions.function('fail')
    Puppet::Parser::Functions.function('validate_hash')
    Puppet::Parser::Functions.function('create_resources')

    function_validate_hash(args)

    final_resources = Hash.new

    args[0].keys.each do |hiera_type|
      values = args[0][hiera_type]
      if values.has_key?('title')
        hiera_type = values['title'].dup
        values.delete('title')
      end

      function_validate_hash([values])

      values.each do |name,value|
        unless value.is_a?(Hash)
          function_fail(["Invalid value for resource definition '#{name}': '#{value.to_s}'"])
        end

        unless value.has_key?('hiera_delete')
          if value.has_key?('title')
            name = value['title']
            value.delete('title')
          end

          if not final_resources.has_key?(hiera_type)
            final_resources[hiera_type] = Hash.new
          elsif name.is_a?(String) and final_resources[hiera_type].has_key?(name)
            function_fail(["Attempt to redefine '#{hiera_type}' resource: '#{name}'"])
          elsif name.is_a?(Array) and name.all? { |n| not final_resources[hiera_type].has_key?(n) }
            function_fail(["Attempt to redefine '#{hiera_type}' resource: '#{name}'"])
          end

          if name.is_a?(String)
            final_resources[hiera_type][name] = value
          elsif name.is_a?(Array)
            name.each do |n|
              final_resources[hiera_type][name] = value
            end
          else
            fail("Error resource names mest be a string or array not: '#{name.class}'")
          end
        end
      end
    end

    final_resources.each do |hiera_type,values|
      defaults = false
      if values.has_key?('hiera_defaults')
        defaults = values['hiera_defaults']
        values.delete['hiera_defaults']
      end
      unless values.empty?
        function_create_resources([
          hiera_type, values,
          ((hiera_type != 'class') and defaults) ? defaults : {}
        ])
      end
    end

    final_resources = nil
    true
  end
end
