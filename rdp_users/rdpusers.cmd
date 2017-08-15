:: Script RDPUsers.cmd
@ECHO OFF

::============================================================================::
:: c.f: https://share.zabbix.com/operating-systems/windows/template-rdp-users ::
::                                                                            ::
:: Created: 07 Jun 2016  Alois Zadrazil            Initial Version            ::
:: Updated: 18 May 2017  Robert McLay              Update to print location   ::
:: Updated: 18 May 2017  Robert McLay              Tidy up output             ::
::                                                                            ::
:: User parameter in zabbix_agentd.conf:                                      ::
:: UserParameter=RDPUsers,"c:\zabbix\RDPUsers.cmd"                            ::
::============================================================================::

for /F "usebackq tokens=1,2,3,4,5*" %%i in (`qwinsta ^| find "Active"`) do (

:: If users are active then output a status
if "%%l" == "Active" echo "%%j %%l on %%i"

:end
SET count=0
)
