# frozen_string_literal: true

require 'ipaddr'

Puppet::Functions.create_function(:'profile::collapse_ipset_entries') do
  dispatch :collapse_entries do
    param 'Array[String]', :entries
    return_type 'Array[String]'
  end

  def collapse_entries(entries)
    nets = entries.map do |s|
      begin
        IPAddr.new(s).to_string + "/" + s.split("/")[1]
      rescue StandardError
        s
      end
    end.uniq

    parsed = nets.map do |s|
      ip, prefix = s.split("/", 2)
      {
        original: s,
        ipaddr: IPAddr.new(ip),
        prefix: Integer(prefix),
      }
    end

    # sort broader networks first
    parsed.sort_by! do |n|
      [n[:ipaddr].ipv4? ? 4 : 6, n[:ipaddr].to_i, n[:prefix]]
    end

    kept = []

    parsed.each do |candidate|
      covered = kept.any? do |existing|
        next false unless existing[:ipaddr].ipv4? == candidate[:ipaddr].ipv4?

        mask_bits = existing[:ipaddr].ipv4? ? 32 : 128
        next false if existing[:prefix] > candidate[:prefix]

        existing_net = IPAddr.new("#{existing[:ipaddr].to_string}/#{existing[:prefix]}")
        candidate_net = IPAddr.new("#{candidate[:ipaddr].to_string}/#{candidate[:prefix]}")

        existing_net.include?(candidate_net.to_range.begin) &&
          existing_net.include?(candidate_net.to_range.end)
      end

      kept << candidate unless covered
    end

    kept.map { |n| "#{n[:ipaddr].to_string}/#{n[:prefix]}" }
  end
end