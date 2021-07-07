# gcp-M-Processing

<H1>Processing inventory files with GCP</H1>

<H2>Use a GCP project</H2>
If creating a new project, ensure that billing is activated and that the BigQuery API is enabled

<H2>Upload files to the GCP Cloud Shell</H2>
From within the Cloud console with the desire project selected, open the Cloud Shell

Once the Cloud Shell is active, select the three dot menu and then choose to Upload file

If you have a ZIP file, upload it and then extract it…

    unzip filename.zip

If you have individual files, upload them one at a time

Once the files are uploaded, rename them to remove the final underscore and datestamp which comes right before the .csv. If you uploaded and extracted a ZIP file, you’ll need to “cd” into the extracted directory first. For example, if all the files end with _20210102.csv, then the command would be...

    rename ‘s/_20210102//’ *

If rename doesn't work, it may need to be installed first and then the rename command can be attempted again...

    sudo apt install rename


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
