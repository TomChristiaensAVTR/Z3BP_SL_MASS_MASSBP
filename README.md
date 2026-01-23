# Z3BP_SL_MASS_MASSBP

**Some General information**
The scope we want to achieve is to have a similiar transaction like XD99 for BP's in S4.
The implementation is done using API method cl_md_bp_maintain=>maintain".
The implementation is parallel enabled using the class cl_abap_parallel.

**Setup**
In order to setup the transaction MASS for the custom BP object the following needs to be done:

1/ STEP 1: Upload the coding in src folder.

2/ STEP 2: Transaction SM34 for MASSOBJECTS

<img width="1294" height="842" alt="image" src="https://github.com/user-attachments/assets/30d1ea8b-3620-4667-bcd0-c43962629571" />

2/ STEP 2: Do the setup for the BREAKOUT events

<img width="1134" height="441" alt="image" src="https://github.com/user-attachments/assets/e219995d-6bce-4104-8ae7-164dbaf08e23" />

3/ STEP 3: Do the setup for the different dimensions/tables/views that are to be updated.

<img width="1889" height="597" alt="image" src="https://github.com/user-attachments/assets/227d7d07-2549-4cb9-9e8c-e3145324c0b7" />

**Important remark related to upload of excel files with multiple worksheets (each covering a table/view/dimension)**
SAP has explicitly blocked the possibility to upload excel files with multiple worksheets. See below

Section 1 where I intervened ...
<img width="1725" height="1030" alt="image" src="https://github.com/user-attachments/assets/918a3c55-6838-4991-837e-a276a70e4eb0" />

Section 2 where I intervened ....
<img width="1399" height="692" alt="image" src="https://github.com/user-attachments/assets/0e126d3e-6bc5-400e-aebc-e4569da3b53b" />

<img width="1627" height="1014" alt="image" src="https://github.com/user-attachments/assets/e4484fd2-cf45-4df6-85ed-2a30ab9e5782" />
