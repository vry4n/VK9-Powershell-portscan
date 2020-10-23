# Author: Bryan Alfaro (Vry4n)
# Date: 10/10/20
# Site: https://vk9-sec.com
# Github account: https://github.com/vry4n
# Description: A basic port scan tool for powershell
# Before using the script install Subnet module "install-Module Subnet -Scope CurrentUser"
# Usage: ./vk9-bash-portscan.ps1 {port} {IP}/{mask}
# example 1: ./vk9-Powershell-portscan.ps1 any 192.168.0.0/24 tcp
# example 2: ./vk9-Powershell-portscan.ps1 22,23 192.168.0.1 any

function Get-banner {
  Write-Host "__     ___  _____    ____                       _ _         "
  Write-Host "\ \   / / |/ / _ \  / ___|  ___  ___ _   _ _ __(_) |_ _   _ "
  Write-Host " \ \ / /| ' / (_) | \___ \ / _ \/ __| | | | '__| | __| | | |"
  Write-Host "  \ V / | . \\__, |  ___) |  __/ (__| |_| | |  | | |_| |_| |"
  Write-Host "   \_/  |_|\_\ /_/  |____/ \___|\___|\__,_|_|  |_|\__|\__, |"
  Write-Host "                        By Vry4n                      |___/ "
  Write-Host "               ==========================                   "
}

$PORT = $args[0]
$IP = $args[1]

#This function will set an array with each port listed. Depending on the input the case switch will execute
function Get-VK9PORTS {
  switch -Wildcard ($PORT) {
    "any" {
      $array_var = 1..65535
    }
    '[0-9]*[0-9]*' {
      $array_var = $PORT
    }
  }
return $array_var
}

# Separates the IP and the mask into an array from 192.168.0.0/24 to 192.168.0.0 24 (array)
function Get-VK9IP {
  switch -Regex ($IP) {
    "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}" {
      $IP_mask = $IP.split("/")
      break
    }
    "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" {
      $IP_mask = $IP, "32"
      break
    }
  }
return $IP_mask
}

# This function will return the address space based on the mask (Start - End IP)
function Get-VK9NET {
  $range = Invoke-Command -ScriptBlock {Get-Subnet -Force -IP $IP[0] -MaskBits $IP[1] | Select-Object -Property Range}
  $range = $range.range.replace(" ", "")
  $range = $range.split("~")

  return $range
}

function Start-VK9ScanTCP {
  $result = ping -n 1 $target
  if ($? -eq $True) {
    Write-Host "========IP==========="
		Write-Host "| $target is UP |"
		Write-Host "=======PORTS========="
    foreach ($PRT in $PORTS) {
      $client = New-Object System.Net.Sockets.TcpClient
      $connect = $client.BeginConnect($target,$PRT,$null,$null) | Select-Object -Property IsCompleted
      $client.Close()
      if ($connect.IsCompleted -eq "True") {
        Write-Host "$PRT is open"
        Write-Host "______________________"
      }
    }
  }
}

# this function will evaluate every IP in the subnet. /8 is not allowed. /16 or above are OK
function Start-VK9tcpscan {
  if (($IP[1] -ge 24 ) -and ($IP[1] -le 32)) {
    $start = $target_ip[0].split(".")
    $last = $target_ip[1].split(".")
    foreach ($number in $start[3]..$last[3]) {
      $target = $start[0] + "." + $start[1] + "." + $start[2] + "." + $number
      Start-VK9ScanTCP
    }
  }
  elseif (($IP[1] -ge 16) -and ($IP[1] -lt 24)) {
    $start = $target_ip[0].split(".")
    $last = $target_ip[1].split(".")
    foreach ($number in $start[2]..$last[2]) {
      $target = $start[0] + "." + $start[1] + "." + $number
      foreach ($num in $start[3]..$last[3]) {
        $target = $start[0] + "." + $start[1] + "." + $number + "." + $num
        Start-VK9ScanTCP
      }
    }
  }
}

Get-banner
#runs the functions
$PORTS = Get-VK9PORTS
$IP = Get-VK9IP
$target_ip = Get-VK9NET
Start-VK9tcpscan
