# gcp-M-Processing

<H1>Processing inventory files with GCP</H1>

<H2>Obtain the files</H2>
If in a ZIP file, extract them
Remove the last underscore followed by the datestamp on each file

<H2>Use a GCP project</H2>
If creating a new project, ensure that billing is activated and that the BigQuery API is enabled

<H2>Upload files to the GCP Cloud Shell</H2>
From within the Cloud console with the desire project selected, open the Cloud Shell
Once the Cloud Shell is active, select the three dot menu and then choose to Upload file
Upload each of the following files...<br/>
arc_disk_report<br/>
arc_landscape_device_summary<br/>
arc_netstat_report<br/>
azure_storage_pricing_inv<br/>
azure_vm_pricing_inv<br/>
azure_vm_sizing_inv<br/>
device_list<br/>
msft_sqlserver_database_list<br/>
msft_sqlserver_features<br/>

<H2>Clone this repository to the Cloud Shell</H2>
git clone https://github.com/sunsetmountain/gcp-M-Processing

<H2>Move the files into the repository directory</H2>
mv *.csv ./gcp-M-Processing/
cd ./gcp-M-Processing

<H2>Enable and run the script</H2>
chmod +x bqUploadData.sh
./bqUploadData.sh

<H2>Access the BigQuery data from Sheets</H2>
From a new Google Sheet, select Data, Data Connectors and then Connect to BigQuery
Select the project, dataset and then desired tables/views. Repeat as needed. The recommended views to access in Sheets are...<br/>
VM_Full_View<br/>
Azure_Over_Provisioned<br/>
Azure_Under_Provisioned<br/>
Sever_Dependency<br/>
Server_Incoming_Connections<br/>
Server_Outgoing_Connections<br/>
DB_View<br/>
DB_Counts<br/>
