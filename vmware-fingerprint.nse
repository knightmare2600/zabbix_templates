local http = require "http"
local shortport = require "shortport"
local stdnse = require "stdnse"

description = [[
Uses an HTTP PUT request to VMware's SOAP API in order to elicit a server response that contains ESX version information.
]]

---
--@usage
--nmap -p443 --script vmware-fingerprint.nse <ip>
--
--@output
-- 443/tcp open  ssl/http VMware ESXi Server httpd
-- |_vmware-fingerprint: VMware ESXi 5.0.0 build-469512
--

--
-- Version 0.1
-- Created 05/16/2013 - v0.1 - created by Mark Baseggio <mark@baseggio.ca>
--

author = "Mark Baseggio"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {"version", "safe"}

portrule = shortport.port_or_service( 443, "https", "tcp", "open" )

action = function( host, port )

    local path = "/sdk"
    local pattern = "<fullName>(.*)</fullName>"
   
    options = {header={}, no_cache = true}
    options['header']['User-Agent'] = "VMware VI Client/4.0.0"
    options['header']['SOAPAction'] = "urn:vim25/4.0"

    -- Credit for the SOAP request goes to theLightCosine
    local postdata = [[
    <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <env:Body>
    <RetrieveServiceContent xmlns="urn:vim25">
        <_this type="ServiceInstance">ServiceInstance</_this>
    </RetrieveServiceContent>
    </env:Body>
    </env:Envelope>
    ]]
    
    -- Send the request using an HTTP PUT
    local response = http.post(host, port, path, options, nil, postdata)

    stdnse.print_debug("HTTP response status: " .. string.gsub(response["status-line"], "\n", ""))

    if ( response.status == 200 ) then
        stdnse.print_debug("HTTP response body: ")
        stdnse.print_debug(response.body)
        return response.body:match(pattern)
    end

    if ( nmap.verbosity() > 1 ) then
        return "VMware version detection was unsuccessful (try using -d for verbose output)."
    else
        return nil
    end

end