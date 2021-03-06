test_name 'Windows ACL Module - Change Owner to Local Unicode Group'

confine(:to, :platform => 'windows')

#Globals
file_content = 'I thought things on a Saturday night.'

parent_name = 'temp'
prefix = SecureRandom.uuid.to_s
target_name = "#{prefix}.txt"

target_parent = "c:/#{parent_name}"
target = "#{target_parent}/#{target_name}"
user_id = 'bob'

raw_owner_id = '\u4388\u542B\u3D3C\u7F4D\uF961\u4381\u53F4\u79C0\u3AB2\u8EDE'
owner_id =     "\u4388\u542B\u3D3C\u7F4D\uF961\u4381\u53F4\u79C0\u3AB2\u8EDE" # 䎈含㴼罍率䎁叴秀㪲軞

verify_owner_command = "(Get-ACL '#{target}' | Where-Object { $_.Owner -match ('.*\\\\' + [regex]::Unescape(\"#{raw_owner_id}\")) } | Measure-Object).Count"

#Manifests
acl_manifest = <<-MANIFEST
file { "#{target_parent}":
  ensure => directory
}

file { "#{target}":
  ensure  => file,
  content => '#{file_content}',
  require => File['#{target_parent}']
}

group { "#{owner_id}":
  ensure     => present
}

user { "#{user_id}":
  ensure     => present,
  groups     => 'Users',
  managehome => true,
  password   => "L0v3Pupp3t!"
}

acl { "#{target}":
  permissions  => [
    { identity => '#{user_id}',
      rights   => ['modify']
    },
  ],
  owner        => '#{owner_id}'
}
MANIFEST

#Tests
agents.each do |agent|
  step "Execute ACL Manifest"
  apply_manifest_on(agent, acl_manifest, {:debug => true}) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step "Verify that ACL Rights are Correct"
  on(agent, powershell(verify_owner_command, {'EncodedCommand' => true})) do |result|
    assert_match(/^1$/, result.stdout, 'Expected ACL was not present!')
  end
end
