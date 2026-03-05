# frozen_string_literal: true

Puppet::Functions.create_function(:'profile::firewalld_ipset_candidate') do
  # Decide whether a rule is eligible for ipset handling:
  # - Must be a Hash
  # - Must have a non-empty 'source'
  # - family defaults to 'ipv4' and must be ipv4/ipv6
  # - Must not include additional match keys like port/service/protocol/etc.
  #
  # @param rule [Hash] The rule hash from Hiera
  # @return [Boolean] true if it is "source-only" and can go into ipsets
  dispatch :firewalld_ipset_candidate do
    param 'Hash', :rule
    return_type 'Boolean'
  end

  def firewalld_ipset_candidate(rule)
    family = rule.key?('family') && rule['family'] ? rule['family'].to_s : 'ipv4'
    return false unless %w[ipv4 ipv6].include?(family)

    source = rule['source']
    return false if source.nil? || source.to_s.strip.empty?

    extra_keys = %w[
      port service protocol icmp_block masquerade forward_port log audit limit
    ]

    has_extras = extra_keys.any? { |k| !rule[k].nil? }
    !has_extras
  end
end
