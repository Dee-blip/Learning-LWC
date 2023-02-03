/*---------------------------------------------------------------------------------
 * Class Name           : SC_PassphraseController
 * Developer Name       : Pinkesh Rathore
 * Date                 : 26th Oct,2017
 * JIRA                 : ESESP-761
 * Test class           : SC_PolicyDomain_Test
 ----------------------------------------------------------------------------------
  31/05/18  Vamsee S    ESESP-1371  Restrict Pass Phrase Length to 100 Characters
  20/07/18  Sumanth Naik ESESP-1507 Added cost center to check logic and grant access
  25/07/18  Vandhana    ESESP-1505  Keep passphrase field blank for everyone, if there’s no value
  27/09/19  Pinkesh     ESESP-2689: Changing Passphrase view/edit access
 ---------------------------------------------------------------------------------*/
public class SC_PassphraseController {
    
    public Boolean hasUserAccess{get;set;}
    public String encrypted_data{get;set;}
    public String newPassphrase{get;set;}
    public String confirmPassphrase{get;set;}
    public Contact varCon;
    public String keyPrefix;
    public String contactId{get;set;}
    public Blob IV;
    public boolean isSuccess{get;set;}
    
    public SC_PassphraseController(ApexPages.StandardController controller){
        
        Schema.DescribeSObjectResult res = Contact.sObjectType.getDescribe();
        keyPrefix = res.getKeyPrefix();
        
        contactId = ApexPages.currentPage().getParameters().get('id');
        varCon = [Select id, Passphrase__c, Passphrase_Last_Updated_Date__c, encryption_key__c, AKAM_Contact_ID__c, Validation_Override__c, AccountId from Contact where id = :contactId];
        //creating Initialization Vector
        IV = Blob.valueOf((keyPrefix + varCon.AKAM_Contact_ID__c.leftPad(13,'_')).substring(0,16));
        isSuccess = false;
        //Check if user has permission to view or edit the passphrase
        if(checkUserAccess()){
            decrypt();
            hasUserAccess = True;
        }
        else 
        {
            // changes by Vandhana ESESP-1505 : Blank (not ****) if passphrase is blank
            if(String.isNotBlank(varCon.Passphrase__c))
                encrypted_data = '**********'; 
            else
                encrypted_data = '';
            hasUserAccess = False;
        }
    }
    
    //Function to encrypt the passphrase
    public PageReference encrypt(){
        PageReference contactPage;
        if(newPassphrase.equals(confirmPassphrase) && newPassphrase != '' && confirmPassphrase != '' && newPassphrase.length() <= 100 && String.isNotBlank(newPassphrase)){
            //generating and encrypting the encryption key
            Blob key = Crypto.generateAesKey(256);
            varCon.encryption_key__c = EncodingUtil.base64Encode(key);
            
            //Encrypting the passphrase
            Blob data = Blob.valueOf(newPassphrase);
            Blob encrypted = Crypto.encrypt('AES256', key, IV, data);

            varCon.Passphrase__c  = EncodingUtil.base64Encode(encrypted);
            //updating Passphrase_Last_Updated_Date__c
            varCon.Passphrase_Last_Updated_Date__c = System.now();
            varCon.Validation_Override__c = true;
            try{
                update varCon;
                isSuccess = true;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Passphrase changed successfully'));
            }
            catch(exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error: Passphrase not saved. Please try again.'));
            }
            contactPage = new PageReference('/'+ contactId);
            contactPage.setRedirect(true);            
        }
        else if(newPassphrase!=confirmPassphrase && newPassphrase != '' && confirmPassphrase != ''){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Passphrases don\'t match'));
        }
        else if(newPassphrase.length() > 100){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Maximum length of Passphrase is 100 Characters'));
        }
        else
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Enter a valid Passphrase'));
        
        return contactPage;
        
    }
    
    
    //function to decrypt the passphrase
    public void decrypt(){
        if((varCon.Passphrase__c != '' && varCon.Passphrase__c != null && varCon.encryption_key__c != '' && varCon.encryption_key__c != null)){
            
            //Decrypting Passphrase
            Blob decrypted = Crypto.decrypt('AES256', EncodingUtil.base64Decode(varCon.encryption_key__c), IV, EncodingUtil.base64Decode(varCon.Passphrase__c));
            encrypted_data = decrypted.toString();
        }
        else
            encrypted_data = '';
    }
    
    
//checking if user has access to view to the passphrase
    public Boolean checkUserAccess(){
        
        //Fetching profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt for SOCC and Sys Admins
        List<SC_SOC_Passphrase_Access__mdt> lPassPhraseAccessForSOCC = [Select Id, Profile_ID_Text__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName LIKE 'Passphrase_Access_For_SOCC_n_Admin%'];
        String lProfileIdForSOCC = '';
        for(SC_SOC_Passphrase_Access__mdt eachrec : lPassPhraseAccessForSOCC){
            lProfileIdForSOCC += eachrec.Profile_ID_Text__c + ',';
        }

        //Fetching profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt for PS profiles
        List<SC_SOC_Passphrase_Access__mdt> lPassPhraseAccessForPS = [Select Id, Profile_ID_Text__c, Account_Team_Role__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName LIKE 'Passphrase_Access_For_PS%'];
        String lProfileIdForPS = '';
        Set<String> sAccountTeamRoleForPS = new Set<String>();
        for(SC_SOC_Passphrase_Access__mdt eachrec : lPassPhraseAccessForPS){
            lProfileIdForPS += eachrec.Profile_ID_Text__c + ',';
            if(String.isNotBlank(eachrec.Account_Team_Role__c))
                sAccountTeamRoleForPS.addAll(eachrec.Account_Team_Role__c.split(','));
        }

        //Fetching profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt for AMG profiles
        List<SC_SOC_Passphrase_Access__mdt> lPassPhraseAccessForAMG = [Select Id, Profile_ID_Text__c, Account_Team_Role__c, User_Title_text__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName LIKE 'Passphrase_Access_For_AMG%'];
        String lProfileIdForAMG = '';
        Set<String> sAccountTeamRoleForAMG = new Set<String>();
        Set<String> sUserTitleForAMG = new Set<String>();
        for(SC_SOC_Passphrase_Access__mdt eachrec : lPassPhraseAccessForAMG){
            lProfileIdForAMG += eachrec.Profile_ID_Text__c + ',';
            if(String.isNotBlank(eachrec.Account_Team_Role__c))
                sAccountTeamRoleForAMG.addAll(eachrec.Account_Team_Role__c.split(','));
            if(String.isNotBlank(eachrec.User_Title_text__c))
                sUserTitleForAMG.addAll(eachrec.User_Title_text__c.split(','));
        }


        //Checking permissions for SOCC n Admin
        if(lProfileIdForSOCC.contains(Userinfo.getProfileId()))
            return true;
        
        //Fetching account team members based on Account ID and User ID
        list<AccountTeamMember> accTeamMem = new list<AccountTeamMember>([SELECT Id, UserId, User.Title, TeamMemberRole, Title FROM AccountTeamMember where AccountID =: varCon.AccountId and UserId = :UserInfo.getUserId() limit 1]);
        
        if(accTeamMem.size() > 0){
            //Checking permissions for PS profile
            if(lProfileIdForPS.contains(Userinfo.getProfileId()) && sAccountTeamRoleForPS.contains(accTeamMem[0].TeamMemberRole))
                return true;

            //Checking permissions for AMG profile
            if(lProfileIdForAMG.contains(Userinfo.getProfileId()) && sAccountTeamRoleForAMG.contains(accTeamMem[0].TeamMemberRole) && sUserTitleForAMG.contains(accTeamMem[0].User.Title))
                return true;

        }
        
        return false;
    }
}