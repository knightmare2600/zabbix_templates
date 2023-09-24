# Auto Discovered Web Checks
Simply monitoring of sites and services within your IT estate.

Apply this template to a host within your inventory to enable checking of web pages. The template will automatically discover web pages to check based on the contents of the `sites.csv` file, look for the Required String and check the Response Code.

# Usage
1. Import the template into Zabbix.
2. Apply the template to a host within your inventory.
3. On said host, create a `sites.csv` file containing a list of URLs to check. The file should be in the format:
    ```
    "URL";"RequiredString";"ResponseCode"
    "example.com";"This domain is for use in illustrative examples";"200"
    "zabbix.com";"Zabbix LLC";"200"
    "www.zabbix.com/download";"Download and install Zabbix";"200"
    ```
4. On said host, update the `{$SITES_FILE}` macro to the path of the `sites.csv` file. Ensure `zabbix` user has read access to the file.

# Coverage
## Items
All items are of the format: `site.availability.component.[{$url}]`  
- HTTP/S Response Code (Check they match the expected response code)
- Git Repo Exposure (Look for expose git respositiores)
- Required String Search (Look for a string within the response body)
- Web Performance (Check the response time of the web page)

## Triggers
| Trigger | Severity | Description |
|---------|----------|-------------|
|Site `{#URL}` Failed to Check Loading Time|Information|Web Performance Check Failed. Is the url valid?|
|Site `{#URL}` Slow Loading Times (`{ITEM.LASTVALUE1}`)|Average|Web Performance Check is taking longer than expected. Adjust `{$LOADING_TIME_WARN}` to tune |
|Site `{#URL}` Very Slow Loading Times (`{ITEM.LASTVALUE1}`)|Disaster|Web Performance Check is taking longer than expected. Adjust `{$LOADING_TIME_CRIT}` to tune |
|`{#URL}` May Have Exposed Git Repo|High|Git Repo Exposed. Check the web page for a `.git` folder|
|`{#URL}` Required Text "`{#REQUIRED_STRING}`" not found|High|Required String not found, did the page change?|
|`{#URL}` Unexpected HTTP Response Code (Expecting `{#RESPONSE_CODE}` or 301)|High|Unexpected `HTTP` Response Code. Check for Errors. 301 permitted for perm. redirects|
|`{#URL}` Unexpected HTTPS Response Code (Expecting `{#RESPONSE_CODE}`)|High|Unexpected `HTTPS` Response Code. Check for Errors.|

## Tags
| Tag | Value |
|-----|-------------|
|Application|Site Avaialbility|
|Site|`{#URL}`|

## Macros
| Macro | Default Value | Description |
|-------|---------------|-------------|
|`{$LOADING_TIME_CRIT}`|`5`|Critical threshold for web performance check|
|`{$LOADING_TIME_WARN}`|`1`|Warning threshold for web performance check|
|`{$SITES_FILE}`|`/tmp/sites.csv`|Path to the `sites.csv` file|

# Further Development
- Your `sites.csv` file may be static or dynamically generated. For example, if you have a dynamic list of URLs to check, you could use a cron job to generate the `sites.csv`
- SSL Certificate Validity Check (See [ssl_check](../ssl_check/info.txt) or the newer [zabbix method](https://www.zabbix.com/integrations/ssl))
- Domain Validity Check (See [domain_expiry](../domain_expiry/))

# Notes
- Auto Discovery will remove any web checks that are no longer in the `sites.csv` file after `1 hour`. You can change this within the `Site Availability` Discovery Rule to suit your needs.

# Copyright
Author: [Callum Inglis](https://www.calluminglis.com) on behalf of [4oh4 Ltd](https://www.4oh4.co.uk)