#!/bin/bash

# Create a dataset
bq --location=US mk --dataset movereDataset

# Create tables and upload the CSV files into an autocreated schema
# Be certain to remove the datestamp from the CSV filename ahead of time so the CSV filesnames below match
bq load --autodetect --source_format=CSV movereDataset.arc_disk_report arc_disk_report.csv
bq load --autodetect --source_format=CSV movereDataset.arc_landscape_device_summary arc_landscape_device_summary.csv
bq load --autodetect --source_format=CSV movereDataset.arc_netstat_report arc_netstat_report.csv
bq load --autodetect --source_format=CSV movereDataset.azure_storage_pricing azure_storage_pricing_inv.csv
bq load --autodetect --source_format=CSV movereDataset.azure_vm_pricing azure_vm_pricing_inv.csv
bq load --autodetect --source_format=CSV movereDataset.azure_vm_sizing azure_vm_sizing_inv.csv
bq load --autodetect --source_format=CSV movereDataset.device_list device_list.csv
bq load --autodetect --source_format=CSV movereDataset.msft_sqlserver_database_list msft_sqlserver_database_list.csv
bq load --autodetect --source_format=CSV movereDataset.msft_sqlserver_features msft_sqlserver_features.csv

# Create Views that will make the data more useful
# DB_View
bq mk \
--use_legacy_sql=false \
--view \
'SELECT List.Device_Name, List.Database_Name, List.Instance, List.Size_MB_, Features.Edition, Features.Version, Features.Service_Pack 
FROM `movereDataset.msft_sqlserver_database_list` AS List LEFT JOIN `movereDataset.msft_sqlserver_features` AS Features 
ON List.Device_Name = Features.Device_Name AND List.Instance = Features.Instance_Name' \
movereDataset.DB_View

# DB_Counts
bq mk \
--use_legacy_sql=false \
--view \
'SELECT Device_Name, COUNT(Database_Name) AS NumDBs, SUM(Size_MB_) AS SizeDBsInMBs 
FROM `movereDataset.msft_sqlserver_database_list` 
GROUP BY Device_Name' \
movereDataset.DB_Counts

# VM_Full_View
bq mk \
--use_legacy_sql=false \
--view \
'SELECT 
    VM.Device_Name, 
    VM.Operating_System, 
    VM.Processor_Model, 
    VM.Core_Count,
    VM.Total_RAM__GB_,
    VM.Azure_VM_vCPU AS Recommended_vCPU,
    VM.Azure_VM_RAM__GB_ AS Recommended_vRAM,
    (VM.Azure_VM_vCPU - VM.Core_Count) AS CPU_Change,
    (VM.Azure_VM_RAM__GB_ - VM.Total_RAM__GB_) AS RAM_Change,
    VM.Azure_Readiness,
    DS.Avg_CPU, DS.Max_CPU,
    DS.Avg_RAM,
    DS.Max_RAM,
    DS._95_CPU,
    DS._95_RAM,
    DS._99_Disk_IOPS,
    DS._99_Disk_Throughput__MB_sec_,
    DS.Avg_Received_Network__MB_day_,
    DS.Avg_Sent_Network__MB_day_, 
    VM.Software_Tags AS Tags,
    COUNT(Storage.Drive_Letter) AS Drives,
    DB.NumDBs AS SQL_Databases,
    DB.SizeDBsInMBs AS DB_Size_MB
FROM (`movereDataset.azure_vm_sizing` AS VM 
    LEFT OUTER JOIN `movereDataset.azure_storage_pricing` AS Storage ON VM.Device_Name = Storage.Device_Name) 
    LEFT OUTER JOIN `movereDataset.DB_Counts` AS DB ON VM.Device_Name = DB.Device_Name 
    LEFT OUTER JOIN `movereDataset.arc_landscape_device_summary` AS DS ON VM.Device_Name = DS.Device_Name
GROUP BY 
    VM.Device_Name,
    VM.Operating_System,
    VM.Processor_Model,
    VM.Core_Count, VM.Total_RAM__GB_,
    Recommended_vCPU,
    Recommended_vRAM,
    VM.Azure_Readiness,
    DS.Avg_CPU,
    DS.Max_CPU,
    DS.Avg_RAM,
    DS.Max_RAM,
    DS._95_CPU,
    DS._95_RAM,
    DS._99_Disk_IOPS,
    DS._99_Disk_Throughput__MB_sec_,
    DS.Avg_Received_Network__MB_day_,
    DS.Avg_Sent_Network__MB_day_,
    Tags,
    SQL_Databases, DB_Size_MB' \
movereDataset.VM_Full_View

# Azure_Provisioning
bq mk \
--use_legacy_sql=false \
--view \
'SELECT Device_Name, Azure_Profile, (Azure_VM_vCPU - Core_Count) AS CPU_Change, (Azure_VM_RAM__GB_ - Total_RAM__GB_) AS RAM_Change
FROM `movereDataset.azure_vm_sizing`' \
movereDataset.Azure_Provisioning

# Azure_Over_Provisioned
bq mk \
--use_legacy_sql=false \
--view \
'SELECT *
FROM `movereDataset.Azure_Provisioning`
WHERE CPU_Change > 0
ORDER BY CPU_Change DESC' \
movereDataset.Azure_Over_Provisioned

# Azure_Under_Provisioned
bq mk \
--use_legacy_sql=false \
--view \
'SELECT *
FROM `movereDataset.Azure_Provisioning`
WHERE CPU_Change < 0
ORDER BY CPU_Change ASC' \
movereDataset.Azure_Under_Provisioned

# Server_Dependency
bq mk \
--use_legacy_sql=false \
--view \
'SELECT DISTINCT Device_Name, Foreign_Device 
FROM `movereDataset.arc_netstat_report` 
WHERE Foreign_Device <> "Unresolved"' \
movereDataset.Server_Dependency

# Server_Incoming_Connections
bq mk \
--use_legacy_sql=false \
--view \
'SELECT Foreign_Device, Count(Foreign_Device) AS Connections 
FROM `movereDataset.arc_netstat_report` 
WHERE Foreign_Device <> "Unresolved"
GROUP BY Foreign_Device
ORDER BY Connections DESC' \
movereDataset.Server_Incoming_Connections

# Server_Outgoing_Connections
bq mk \
--use_legacy_sql=false \
--view \
'SELECT Device_Name, Count(Device_Name) AS Connections 
FROM `movereDataset.arc_netstat_report` 
WHERE Foreign_Device <> "Unresolved"
GROUP BY Device_Name
ORDER BY Connections DESC' \
movereDataset.Server_Outgoing_Connections

# Azure_VM_Comparison
bq mk \
--use_legacy_sql=false \
--view \
'select 
    DS.Device_name,
    DS.Avg_CPU,
    DS.Avg_RAM,
    SI.CPU_Headroom,
    SI.RAM_Headroom,
    SI.processor_model,
    SI.Core_count,
    SI.Total_RAM__GB_,
    SI.Azure_Profile as AzureVMName,
    SI.Azure_VM_vCPU as AzureVMCPUs,
    SI.Azure_VM_RAM__GB_ as AzureVMRam,
    PI._Cost_Month__Pay_As_You_Go__No_Contract_ as AzureVMCost
from movereDataset.arc_landscape_device_summary DS
    inner join movereDataset.azure_vm_sizing SI on SI.Device_Name = DS.Device_Name
    inner join movereDataset.azure_vm_pricing PI on PI.Device_name = SI.Device_Name
Order by AzureVMCost Desc' \
movereDataset.Azure_VM_Comparison
