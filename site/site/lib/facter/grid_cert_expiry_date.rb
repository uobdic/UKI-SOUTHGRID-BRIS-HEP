Facter.add('grid_cert_expiry_date') do
    setcode do
        cert_path = '/etc/grid-security/hostcert.pem'
        if File.exist?(cert_path)
        cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
        expiry_date = cert.not_after
        expiry_date.strftime('%Y-%m-%d')
        end
    end
end
