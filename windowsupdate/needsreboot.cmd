:: Script needsreboot.cmd
@ECHO OFF

::============================================================================::
:: c.f: https://share.zabbix.com/operating-systems/windows/template-rdp-users ::
::                                                                            ::
:: Created: 01 Jan 2015  http://www.catonrug.net   Initial Version            ::
:: Updated: 15 Aug 2017  Robert McLay              Update for Zabbix 3.0      ::
:: Updated: 15 Aug 2017  Robert McLay              fix echo output            ::
::                                                                            ::
:: User parameter in zabbix_agentd.conf:                                      ::
:: UserParameter=needsreboot,"c:\zabbix\needsreboot.cmd"                      ::
::============================================================================::

@echo off

SETLOCAL EnableDelayedExpansion
REG QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" > nul 2>&1
if !errorlevel!==0 (
echo reboot required
) else echo no reboot required
endlocal