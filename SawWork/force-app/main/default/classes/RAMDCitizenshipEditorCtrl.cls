/**
 * Created by kusharma on 14/12/17.
 */

public without sharing class RAMDCitizenshipEditorCtrl {
    public List<User> lUsersToDisplay { get; set; }
    public List<UserWrapper> lUserRecsWrapped { get {if (lUserRecsWrapped == null) lUserRecsWrapped = new List<UserWrapper>(); return lUserRecsWrapped;} set; }
    public List<UserWrapper> lSearchedUserRecsWrapped { get {if (lSearchedUserRecsWrapped == null) lSearchedUserRecsWrapped = new List<UserWrapper>(); return lSearchedUserRecsWrapped;} set; }
    public List<RAMD_Audit_Trail__c> lRAMdAuditTrail { get {if (lRAMdAuditTrail == null) lRAMdAuditTrail = new List<RAMD_Audit_Trail__c>(); return lRAMdAuditTrail;} set; }
    public String queryString { get; set; }
    Boolean searchResults = false;
    public String userIdToRemove { get; set; }
    public String userNameToRemove { get; set; }
    public String auditTrailReportId { get; set; }
    public List<SelectOption> lCitizenSupportOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', '--None--'));

            Schema.DescribeFieldResult fieldResult = User.Citizen_Support__c.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry varPicklistEntry : picklistEntries) {
                options.add(new SelectOption(varPicklistEntry.getValue(), varPicklistEntry.getLabel()));
            }
            return options;
        }
        set;
    }

    public RAMDCitizenshipEditorCtrl() {
        lUsersToDisplay = new List<User>();
        showApprovedUsers();
        showAuditTrail();
        getAuditTrailReportId();
    }

    //Get Report Id for the Audit Trail records.
    private void getAuditTrailReportId() {
        List<RAMD_Setting__mdt> lRAMDCustomMetadata = [SELECT Value__c FROM RAMD_Setting__mdt WHERE DeveloperName = 'RAMDAuditTrailReportId'];
        auditTrailReportId = lRAMDCustomMetadata.isEmpty() ? ' ' : lRAMDCustomMetadata[0].Value__c;
    }

    //Get latest 25 recs from the Audit Trail object to show on Page Layout.
    private void showAuditTrail() {
        lRAMdAuditTrail.clear();
        lRAMdAuditTrail = [
                SELECT Id, Field_Updated__c, Modified_Date__c, Updated_By__c, User_Name__c
                FROM RAMD_Audit_Trail__c
                ORDER BY CreatedDate DESC
                LIMIT 25
        ];

    }

    //List of approved users who can publish metadata on Public Sector Accounts.
    public void showApprovedUsers() {
        lSearchedUserRecsWrapped.clear();
        lUsersToDisplay.clear();
        lUserRecsWrapped.clear();
        lUsersToDisplay = [
                SELECT Id, Country, Email, Name, Citizen_Support__c, AKAM_User_ID__c, Username
                FROM User
                WHERE
                Citizen_Support__c != ''
        ];
        for (User varUser : lUsersToDisplay) {
            lUserRecsWrapped.add(new UserWrapper(true, varUser));
        }
    }

    //Update User rec in DB
    public void saveUserRec() {
        List<User> lUsersToUpdate = new List<User>();
        for (UserWrapper varUserToUpdate : lSearchedUserRecsWrapped) {
            if (varUserToUpdate.isSelected) {
                lUsersToUpdate.add(varUserToUpdate.userRec);
                varUserToUpdate.isSelected = false;
            }
        }
        if (!lUsersToUpdate.isEmpty()) {
            Database.update(lUsersToUpdate);
            createAuditTrail(lUsersToUpdate, '');
            showApprovedUsers();
            showAuditTrail();
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Records have been updated successfully'));
        }
    }

    //Create Audit Trail rec in RAMD Audit Trail object
    public void createAuditTrail(List<User> lUsersToUpdate, String userName) {
        List<RAMD_Audit_Trail__c> lRAMDAuditTrails = new List<RAMD_Audit_Trail__c>();
        for (User varUser : lUsersToUpdate) {
            String citizenSupport = varUser.Citizen_Support__c == 'USA' ? 'Verified US Citizen' : 'None';
            RAMD_Audit_Trail__c varRAMDAuditTrail = new RAMD_Audit_Trail__c();
            varRAMDAuditTrail.User_Name__c = userName == '' ? varUser.Name : userName;
            varRAMDAuditTrail.Updated_By__c = UserInfo.getName();
            varRAMDAuditTrail.Modified_Date__c = System.now();
            varRAMDAuditTrail.Field_Updated__c = 'Changed Citizen Support to ' + citizenSupport;
            lRAMDAuditTrails.add(varRAMDAuditTrail);
        }
        Database.insert(lRAMDAuditTrails, false);
    }

    //Removes Citizen Support from the User when Delete button is clicked on VF page.
    public void removeCitizenSupport() {
        system.debug('##!!! ' + userIdToRemove);
        User userToRemoveSupport = new User();
        userToRemoveSupport.Id = userIdToRemove;
        userToRemoveSupport.Citizen_Support__c = '';
        update userToRemoveSupport;
        createAuditTrail(new List<User>{
                userToRemoveSupport
        }, userNameToRemove);

        showApprovedUsers();
        showAuditTrail();
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Records have been updated successfully'));
    }

    //Search the User Rec based on the string entered on the Page.
    public void searchUserRecs() {
        Map<ID, User> approvedUserMap = new Map<ID, User>([SELECT Id, Country, Email, Name, Citizen_Support__c, AKAM_User_ID__c, Username
                FROM User
                WHERE
                Citizen_Support__c != '']);
        
        lSearchedUserRecsWrapped.clear();
        lUsersToDisplay.clear();
        lUserRecsWrapped.clear();
        searchResults = true;
        System.debug('### ' + lUserRecsWrapped);
        lUserRecsWrapped.clear();
        if (!String.isEmpty(queryString)) {
            String valuesToQuery = queryString.replaceAll(',', ' OR ').replaceAll(';', ' OR ');
            String soslQuery = 'FIND \'' + valuesToQuery + '\' IN ALL FIELDS returning User (Id,Name,AKAM_User_ID__c,Country,Email,Citizen_Support__c)';
            System.debug('##### ' + soslQuery);
            lUsersToDisplay = Search.query(soslQuery)[0];
        }
        System.debug(' #### ' + lUsersToDisplay);
        for (User varUser : lUsersToDisplay) {
            lSearchedUserRecsWrapped.add(new UserWrapper(false, varUser,approvedUserMap.get(varUser.id)));
        }
        System.debug('#### lUserRecsWrapped ' + lSearchedUserRecsWrapped);
        showAuditTrail();
    }

    //Wrapper class for Checkbox on the page and the User rec.
    public class UserWrapper {
        public Boolean isSelected { get; set; }
         public Boolean isApproved { get; set; }
        public User userRec { get; set; }
        public UserWrapper(Boolean isSelected, User userRec) {
            System.debug('#### isSelected ' + isSelected + ' @@@@ ' + userRec);
            this.isSelected = isSelected;
            this.userRec = userRec;
        }
        //constructor for searcher
        public UserWrapper(Boolean isSelected, User userRec, User approvedAlready) {
            System.debug('#### isSelected ' + isSelected + ' @@@@ ' + userRec);
            this.isSelected = isSelected;
            this.userRec = userRec;
            if (approvedAlready != null){
                isApproved = true;
            }
            else{
                isApproved = false;
            }
        }
    }
}