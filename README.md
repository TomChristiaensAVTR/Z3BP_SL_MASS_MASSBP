# Z3BP_SL_MASS_MASSBP

**Some General information**
The scope we want to achieve is to have a similiar transaction like XD99 for BP's in S4HANA.
The implementation is done using API method "cl_md_bp_maintain=>maintain".
There is no need to fiddle with the comnbination of multiple BAPI's.

The implementation is parallel enabled using the class cl_abap_parallel.

Not all the BP dimensions/tables are foreseen for the moment. Indeed, when checking the I_DATA import structure of cl_md_bp_maintain=>maintain you might understand why.
This is really really really really complex.
Therefore for the moment, from a MASS point of view there is a 1 to 1 mapping to cl_md_bp_maintain=>maintain.

<img width="1213" height="563" alt="image" src="https://github.com/user-attachments/assets/d2a99497-abc3-4409-ab35-43647ac544d7" />

Also some fields pop up in different tables. For example NAME1 can be found in KNA1, but also in BP tables.
I have foreseen these fields in the corresponding view that can be 1 to 1 mapped to the cl_md_bp_maintain=>maintain input structure.

<img width="1348" height="980" alt="image" src="https://github.com/user-attachments/assets/f448a05d-92e5-4e83-b6e4-5f3e55dff53e" />

Another important point is that CDS views are used and NOT CDS view entities. The reason is that the corresponding SQL view is used in the setup of the MASS transaction.

**Setup**
In order to setup the transaction MASS for the custom BP object the following needs to be done:

1/ STEP 1: Upload the coding in src folder.
Take into account that the views might contain references to Z fields that do not exist in your system. 
Therefore the activation could raise an error.

2/ STEP 2: Transaction SM34 for MASSOBJECTS

<img width="1294" height="842" alt="image" src="https://github.com/user-attachments/assets/30d1ea8b-3620-4667-bcd0-c43962629571" />

2/ STEP 2: Do the setup for the BREAKOUT events

<img width="1134" height="441" alt="image" src="https://github.com/user-attachments/assets/e219995d-6bce-4104-8ae7-164dbaf08e23" />

3/ STEP 3: Do the setup for the different dimensions/tables/views that are to be updated.
Please notice that I am using the SQL view of a CDS view. (I was obliged due to the fact that CDS entities are not compatible with the MASS setup)

<img width="1889" height="597" alt="image" src="https://github.com/user-attachments/assets/227d7d07-2549-4cb9-9e8c-e3145324c0b7" />

**Important remark related to upload of excel files with multiple worksheets (each covering a table/view/dimension)**
SAP has explicitly blocked the possibility to upload excel files with multiple worksheets. See below

Section 1 where I intervened ...
<img width="1725" height="1030" alt="image" src="https://github.com/user-attachments/assets/918a3c55-6838-4991-837e-a276a70e4eb0" />

Section 2 where I intervened ....
<img width="1399" height="692" alt="image" src="https://github.com/user-attachments/assets/0e126d3e-6bc5-400e-aebc-e4569da3b53b" />

<img width="1627" height="1014" alt="image" src="https://github.com/user-attachments/assets/e4484fd2-cf45-4df6-85ed-2a30ab9e5782" />
