# Populate-HPE-OneView
Quickly and reliably configure an HPE OneView virtual demonstration appliance with all included hardware.

Here are the steps you need to take prior to running the script:

1)	Deploy a new OneView DCS Appliance and make sure it is assigned a valid IP address from a DHCP server on your network
2)	Take note of the DHCP-assigned IP address and the DNS hostname associated with the DHCP-assigned IP address
3)	Select a new password for the Administrator user for your appliance 

Once you have these three pieces of information, you will need to modify lines 1-3 in the script to reflect your IP/password/hostname:

```
$ip_addr  = "<DHCP IP Address assigned to DCS appliance>"
$password = "<New Administrator Password>"
$hostname = "<Hostname associated with DHCP IP Address of the DCS appliance>"
```
The IP address is only used to connect to the appliance, it is NOT set as a static address for the appliance. If you have no DNS hostname associated with the IP address, you can make one up, it just needs to be a fully qualified domain name. You will get a warning in OneView if the hostname does not resolve to the IP address, but it will not hinder any functionality.