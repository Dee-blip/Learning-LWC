//SFDC-1672 
public class MigrateOpptyPageController {

    PageReference pageRef;
    public Id opportunityId { get; set; }
    public List<Opportunity> OpptysWithContactRole;
    public Opportunity currentExistingOppty{ get; set; }
    public String currentExistingOpptyJSON{ get; set; }
    public Map<Id, List<opportunitycontactrole>> OpptysNameWithContactRole{ get; set; }
    public static String fromButton, opptyName;
    public Boolean showMessage{ get; set; }
    public Id targetOppty{ get; set; }
    public Set<String> sourceOppty{ get; set; }
    public Boolean isMigrateToExistingOpptys{get; set;}

    public String getJSStart() {
        return '<script>document.write(' ;
    }

    public String getJSEnd() {
        return ')</script>' ;
    }

    public PageReference init(){

        showMessage= false;
        opportunityId = ApexPages.currentPage().getParameters().get('recordId');
        fromButton = ApexPages.currentPage().getParameters().get('fromButton');
        opptyName = ApexPages.currentPage().getParameters().get('recordName');
        if(opptyName != null && !String.isBlank(opptyName)) {
            opptyName = String.escapeSingleQuotes(opptyName.escapeHtml4());
        }        
        if(!String.isBlank(fromButton))
        {
            if(fromButton == 'Migrateoppty')
            {
                isMigrateToExistingOpptys = false;
                searchOppty();
                return pageRef;
            }
            else if(fromButton == 'MigrateOpptyExisting')
            {
                isMigrateToExistingOpptys = true;
                searchOpptyExistingAndAqls();
                return pageRef;
            }
        }
        return null;
    }

    /* added as part of SFDC-1938 */
    public void searchOpptyExistingAndAqls()
    {
        OpptysWithContactRole = new List<Opportunity>();
        currentExistingOppty = getCurrentOpportunity(opportunityId);
        currentExistingOpptyJSON = JSON.serialize(currentExistingOppty);
        OpptysWithContactRole = getAccountAQLOpptysWithContactRole(currentExistingOppty.AccountId);
        processSearchOppty(OpptysWithContactRole);
    }


    /* end of SFDC-1938 */

    /* Refactoring to support MOB-362 */

    public Opportunity getCurrentOpportunity(Id opportunityId)
    {
        return [Select id, name,RecordType.Name, AccountId , StageName,AKAM_Opportunity_ID__c, Merged_Opportunity__c, QFA_Accept_Reject__c ,(Select id,opportunity.AKAM_Opportunity_ID__c,opportunity.name, opportunityid, contactid, contact.name, role from opportunitycontactroles where role='lead' ) from opportunity where id =: opportunityId];
    }

    public List<Opportunity> getAccountAQLOpptysWithContactRole(Id accountId)
    {
        return [Select id, name, RecordType.Name, AKAM_Opportunity_ID__c, StageName, Merged_Opportunity__c, QFA_Accept_Reject__c ,(Select id,opportunity.AKAM_Opportunity_ID__c,opportunity.name, opportunityid, contactid, contact.name, role from opportunitycontactroles where role='lead' ) from opportunity where Isclosed = false and RecordType.Name = 'AWE Opportunities' and AccountId =: accountId];

    }

    public List<Opportunity> getDuplicateAQLOpptysWithContactRole(String opptyName)
    {
        return [Select id, name, RecordType.Name, AKAM_Opportunity_ID__c, StageName, Merged_Opportunity__c, QFA_Accept_Reject__c ,(Select id,opportunity.AKAM_Opportunity_ID__c,opportunity.name, opportunityid, contactid, contact.name, role from opportunitycontactroles where role='lead' ) from opportunity where name =: opptyName and Isclosed = false and RecordType.Name = 'AWE Opportunities'];
    }

    /* End Refactoring to support MOB-362 */



    public void searchOppty()
    {
        OpptysWithContactRole = new List<Opportunity>();
        OpptysWithContactRole = getDuplicateAQLOpptysWithContactRole(opptyName);
        processSearchOppty(OpptysWithContactRole);
    }

    public void processSearchOppty(List<Opportunity> OpptysWithContactRole)
    {

        OpptysNameWithContactRole = new Map<Id, List<opportunitycontactrole>>();
        for(Opportunity opp: OpptysWithContactRole){
            if(!opp.opportunitycontactroles.isEmpty()){
                List<opportunitycontactrole> ocObj = OpptysNameWithContactRole.get(opp.Id);
                if(ocObj == null)
                {
                    ocObj= new List<opportunitycontactrole>();
                }
                for(opportunitycontactrole oc : opp.opportunitycontactroles)
                {
                    ocObj.add(oc);
                }
                OpptysNameWithContactRole.put(opp.Id, ocObj);
            }
        }
        System.debug('xyz::'+OpptysNameWithContactRole);
        if((OpptysNameWithContactRole.size() < 2 && !isMigrateToExistingOpptys) || (OpptysNameWithContactRole.size() < 1 && isMigrateToExistingOpptys)){
            showMessage= true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.getGSMSettingValue('No_Duplicate_Opportunity')));
        }
    }


    public PageReference updateOppty(){

        updateOppty(Apexpages.currentPage().getParameters().get('SourceOppty'), targetOppty, OpptysWithContactRole);
        return new PageReference('/'+targetOppty);
    }
    // Adding overriding method updateOppty to support MOB-362
    public void updateOppty(String sourceOpptyString, String targetOppty, List<Opportunity> OpptysWithContactRole){
        sourceOppty = new Set<String>();
        sourceOppty = ( Set<String> )JSON.deserialize( sourceOpptyString, Set<String>.class ) ;

        System.debug(' ===> list of opptys from where contact roles will be copied to target oppty,sourceOppty :'+sourceOppty);
        System.debug(' ===> list of opptys from where contact roles will be copied to target oppty,sourceOppty size :'+sourceOppty.size());

        List<opportunity> updateSourceOppty = new List<opportunity>();
        Set<Opportunitycontactrole> insertTargetOpptyWithContactRoleSet = new Set<Opportunitycontactrole>();
        List<Opportunitycontactrole> insertTargetOpptyWithContactRoleList = new List<Opportunitycontactrole>();

        List<Opportunitycontactrole> TargetOpptyContactRoleList = [Select id, opportunityid, ContactId, Role from Opportunitycontactrole where opportunityid =:(Id)targetOppty];

        System.debug(' ===> target oppty  :'+(Id)targetOppty);
        System.debug(' ===> contact roles from target oppty , TargetOpptyContactRoleList :'+TargetOpptyContactRoleList);
        System.debug(' ===> contact roles from target oppty , TargetOpptyContactRoleList size:'+TargetOpptyContactRoleList.size());

        /* for merge opportunity action on existing oppty , this list may have size 0 */
        /* converting TargetOpptyWithContactRole list to TargetOpptyWithContactRole set */
        for(Opportunitycontactrole OCR : TargetOpptyContactRoleList){
            Opportunitycontactrole OCR1 = new Opportunitycontactrole();
            OCR1.opportunityid = OCR.opportunityid;
            OCR1.ContactId = OCR.contactid;
            OCR1.role = OCR.role;
            insertTargetOpptyWithContactRoleSet.add(OCR1);
        }

        System.debug(' ===> contact roles to be inserted in  target oppty before , insertTargetOpptyWithContactRoleList :'+insertTargetOpptyWithContactRoleList);
        System.debug(' ===> contact roles to be inserted in  target oppty before , insertTargetOpptyWithContactRoleList size:'+insertTargetOpptyWithContactRoleList.size());


        Delete TargetOpptyContactRoleList;

        /* OpptysWithContactRole : list of opptys containing AQL opptys , this should contain target oppty as well in case of merge happening from AQL itself */
        /* sourceOppty : list of opptys from where contact roles will be copied to target oppty */

        for(opportunity opp: OpptysWithContactRole){

            Integer noOfContacts = opp.opportunitycontactroles.size();


            /* update source opptys other than target oppty with reject reasons */
            if(sourceOppty.contains(opp.Id)){
                opp.StageName = GsmUtilClass.getGSMSettingValue('Merged_Opportunity_Stage_Name');
                opp.Merged_Opportunity__c = (Id)targetOppty;
                opp.QFA_Accept_Reject__c = GsmUtilClass.getGSMSettingValue('Marketing_Oppty_Reject_Reason_For_Merge');
                opp.Validation_Override__c = true;

                /* list with source opptys */
                updateSourceOppty.add(opp);

                /* copying contactRoles from sourceOppty List to map them to the target oppty ,
                    new contactRoles are being created */
                for(Integer index =0;index<noOfContacts;index++)
                {
                    Opportunitycontactrole OCR = new Opportunitycontactrole();
                    OCR.opportunityid = (Id)targetOppty;
                    OCR.ContactId = opp.opportunitycontactroles[index].contactid;
                    OCR.Role = opp.opportunitycontactroles[index].role;
                    insertTargetOpptyWithContactRoleSet.add(OCR);
                }

            }


        }



        /* converting insertTargetOpptyWithContactRoleSet set to insertTargetOpptyWithContactRoleList list */
        insertTargetOpptyWithContactRoleList.addAll(insertTargetOpptyWithContactRoleSet);

        System.debug(' ===> contact roles to be inserted in  target oppty after , insertTargetOpptyWithContactRoleList :'+insertTargetOpptyWithContactRoleList);
        System.debug(' ===> contact roles to be inserted in  target oppty after , insertTargetOpptyWithContactRoleList size:'+insertTargetOpptyWithContactRoleList.size());


        try{

            /* inserting new opportunitycontactroles mapped to target oppty */
            insert insertTargetOpptyWithContactRoleList;

            /* list with source opptys ,updating fields */
            update updateSourceOppty;
        }
        catch(DMLException e){
            System.debug('DML Exception::' + e.getMessage());
        }

        
    }

}