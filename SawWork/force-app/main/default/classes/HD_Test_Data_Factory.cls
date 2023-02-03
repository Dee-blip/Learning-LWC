/* ========================================================================
   *Template           : Apex Class
   *Version            : 1.0
   *@author            : Pranav Prashant @ Akamai Technologies Ltd.
   *Created Date       : 18th March, 2018
   *Purpose            : Part of Test Data Factory Fremwork to
                           create dummy data for HD test classes
   *Dependent Classes  : HD_ProblemTestDataFactory, HD_IncidentTestDataFactory

======================================================================== */

public abstract class HD_Test_Data_Factory {

    public static Map<String, String> statusMap;
    public static Map<String, String> urgencyMap;
    public static Map<String, String> impactMap;
    public static Map<String, String> priorityMap;
    public static Map<String, String> categoryMap;
    public static Map<String, String> actionMap;
    public static Map<String, String> categoryTypeMap;




    //CREATE ALL INCIDENT ACTIONS
    public static Map<String, String> createActions() {
        if (actionMap != null) {
            return actionMap;
        }

        Map<String, String> actionsMap = new Map<String, String> {'NOTES' => 'NOTES', 'Client Note' => 'CLIENT_NOTE', 'Internal Note' => 'INTERNAL_NOTE','Email Received' => 'Email Received','Email Sent' => 'Email Sent', 'ESCALATION_NOTE'=>'ESCALATION_NOTE'}; //action {name, BMCServiceDesk__Abbreviation__c}
        //List<String> actionsList = new List<String>{'NOTES'=>'NOTES', 'Client Note'=>'CLIENT_NOTE'};
        List<BMCServiceDesk__Action__c> actions = new List<BMCServiceDesk__Action__c>();
        for (String action : actionsMap.keySet()) {

            actions.add(new BMCServiceDesk__Action__c(name = action, BMCServiceDesk__Abbreviation__c = actionsMap.get(action)));
        }
        insert actions;
        Map<String, String> actionMap = new Map<String, String>();
        for (BMCServiceDesk__Action__c act : actions) {
            actionMap.put(act.name, act.id);
        }
        return actionMap;
    }

    //CREATE ALL STATUS
    public static Map<String, String> insertAllStatus() {
        if (statusMap != null) {
            return statusMap;
        }
        List<BMCServiceDesk__Status__c> status_list = new List<BMCServiceDesk__Status__c>();
        Set<String> status_names = new Set<String> {'UNASSIGNED', 'ASSIGNED',
                'IN PROGRESS', 'WAITING FOR RESPONSE', 'CUSTOMER RESPONDED',
                'RESOLVED', 'CLOSED', 'REASSIGNED', 'CANCELED', 'REOPENED', 'RISK ANALYSIS', 'WORKAROUND IDENTIFIED',
                 'ON HOLD', 'PENDING CMR', 'PENDING HARDWARE', 'PENDING SOFTWARE', 'PENDING USER RESPONSE',
                 'PENDING APPROVAL', 'PENDING OTHERS', 'PENDING THIRD PARTY'
                                                     };//

        for (String status_name : status_names) {
            BMCServiceDesk__Status__c new_status = new BMCServiceDesk__Status__c(Name = status_name);
            new_status.BMCServiceDesk__appliesToIncident__c = true;
            new_status.BMCServiceDesk__appliesToProblem__c = true;

            if ( status_name == 'UNASSIGNED' || status_name == 'CLOSED') {
                new_status.BMCServiceDesk__state__c = true;
                new_status.BMCServiceDesk__defaultStatus__c = true;
            }

            if (status_name == 'CLOSED') {
                new_status.BMCServiceDesk__state__c = false;
            }

            new_status.BMCServiceDesk__appliesToTask__c = true;
            new_status.BMCServiceDesk__inactive__c = false;
            status_list.add(new_status);

        }

        insert status_list;
        Map<String, String> statusMap = new Map<String, String>();
        for ( BMCServiceDesk__Status__c status : status_list) {
            statusMap.put(status.Name, status.id);

        }

        return statusMap;
    }

    //CREATE DEFAULT ACCOUNT
    public static void util() {
        //Account acc = new Account(name = 'Akamai Helpdesk');
        HD_Default_Custom_Setting__c accSetting = new HD_Default_Custom_Setting__c(name = 'DEFAULT VALUES',
                Default_Account__c = 'Akamai Helpdesk',
                Default_Impact__c = 'LOW');
        insert accSetting;
    }

    //CRAETE URGENCY
    public static Map<String, String> createUrgency(List<String> UrgencyName) {
        if (urgencyMap != null) {
            return urgencyMap;
        }
        List<ID> UrgencyinsertedIdList = new List<ID>();
        List<BMCServiceDesk__Urgency__c> UrgInsertList = new List<BMCServiceDesk__Urgency__c>();
        Map<String, String> urgencyMap = new Map<String, String>();

        if (UrgencyName.size() > 0 ) {
            for (String urg : UrgencyName) {
                BMCServiceDesk__Urgency__c urgency = new BMCServiceDesk__Urgency__c();
                urgency.Name = urg;
                urgency.BMCServiceDesk__inactive__c = false;
                UrgInsertList.add(urgency);

            }
        }


        if (UrgInsertList.size() > 0 ) {
            Database.SaveResult[] UrgSaveList = Database.insert(UrgInsertList, false);
            for (Database.SaveResult sr : UrgSaveList) {
                if (sr.isSuccess()) {
                    UrgencyinsertedIdList.add(sr.getId());
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                    break;
                }
            }
        }

        //Now checking against the inserted element
        if (UrgencyName.size() == UrgencyinsertedIdList.size()) {
            for ( Integer i = 0 ; i < UrgencyinsertedIdList.size(); i++ ) {
                urgencyMap.put(UrgencyName[i], UrgencyinsertedIdList[i]);
            }
        }//if(UrgencyName.size() == UrgencyinsertedIdList)
        else {
            urgencyMap.clear();
        }//else

        return urgencyMap;
    }

    //CREATE IMPACT RECORDS
    public static Map<String, String> createImpact(List<String> ImpactNames) {
        if (impactMap != null) {
            return impactMap;
        }
        //List of impact which need to be inserted
        List<BMCServiceDesk__Impact__c> impactList = new List<BMCServiceDesk__Impact__c>();
        //Stores Inserted Id
        List<ID> InsertedImpactId = new List<ID>();

        //Output Map File
        Map<String, String> impactMap = new Map<String, String>();

        if (ImpactNames.size() > 0 ) {
            for (String impname : ImpactNames) {
                BMCServiceDesk__Impact__c imp  = new BMCServiceDesk__Impact__c();
                imp.Name = impname;
                imp.SI_Applies_to_Service_Incident__c = false;
                imp.BMCServiceDesk__inactive__c = false;

                //Adding it to insert List
                impactList.add(imp);
            }//for(String impname: ImpactNames)

        }//if(ImpactNames.size() > 0 )

        //lets insert the Impact now
        if ( impactList.size() > 0 ) {
            Database.SaveResult[] impactSR = Database.insert(impactList, false);
            for ( Database.SaveResult sr : impactSR) {
                if (sr.isSuccess()) {
                    InsertedImpactId.add(sr.getId());
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                }//if
                else {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }//for(Database.Error err : sr.getErrors())
                    break;
                }//else

            }//for( Database.SaveResult sr:impactSR)

        }//if( impactList.size() > 0 )

        if ( ImpactNames.size() == InsertedImpactId.size()) {
            for ( Integer i = 0 ; i < InsertedImpactId.size(); i++ ) {
                impactMap.put(ImpactNames[i], InsertedImpactId[i]);
            }//for( Integer i = 0 ; i < UrgencyinsertedIdList.size();i++ )
        }//if( ImpactNames.size() == InsertedImpactId)
        else {
            impactMap.clear();
        }//else

        return impactMap;
    }

    //CREATE PRIORITY OBJECTS
    //will create priorrity 1, 2, 3, 4 and 5 with urgency sev 1, sev 2, sev 3 , sev 4 and sev 5
    public static Map<String, String> createPriority() {

        if (priorityMap != null) {
            return priorityMap;
        }

        List<HD_Ticket_Priority__c> priorityCustomSetting = new List<HD_Ticket_Priority__c>();
        List<BMCServiceDesk__Priority__c>  priorityList = new List<BMCServiceDesk__Priority__c>();

        for (String urg : urgencyMap.keySet()) {

            //create a new priority
            BMCServiceDesk__Priority__c p = new BMCServiceDesk__Priority__c(
                BMCServiceDesk__FkUrgency__c = urgencyMap.get(urg),
                BMCServiceDesk__FkImpact__c = impactMap.get('LOW'),
                name = urg.split(' ')[1],
                BMCServiceDesk__description__c = 'test desc'
            );
            priorityList.add(p);
        }

        insert priorityList;

        for (BMCServiceDesk__Priority__c p : priorityList) {
            HD_Ticket_Priority__c prioritySetting = new HD_Ticket_Priority__c(
                name = p.name,
                priority_id__c = p.id,
                priority_name__c = p.name,
                urgency_id__c = p.BMCServiceDesk__FkUrgency__c,
                urgency_name__c = 'Severity ' + p.name
            );
            priorityCustomSetting.add(prioritySetting);
        }
        insert priorityCustomSetting;


        Map<String, String> priorityMap = new Map<String, String>();
        for (BMCServiceDesk__Priority__c p : priorityList) {
            priorityMap.put(p.name, p.id);
        }
        return priorityMap;
    }

    //CREATE CATEGORIES
    public static Map<String, String> createCategories() {

        if (categoryMap != null) {
            return categoryMap;
        }
        //create category type
        List<String> cattypeNames = new List<String> {'Q_EAE_OPS', 'Q_Helpdesk_Hardware', 'Q_ORACLE_APPS', 'Q_DataCenter_Access', 'Q_SI_OPS', 'Q_DBA','Q_HR', 'Q_Infosec'};
        List<BMCServiceDesk__CategoryTypes__c> catTypes = new List<BMCServiceDesk__CategoryTypes__c>();
        for (String ctype : cattypeNames) {
            catTypes.add(new BMCServiceDesk__CategoryTypes__c(name = ctype));
        }
        insert catTypes;

        categoryTypeMap = new Map<String, String>();
        for (BMCServiceDesk__CategoryTypes__c ctype : catTypes) {
            categoryTypeMap.put(ctype.name, ctype.id);
        }

        List<BMCServiceDesk__Category__c> categoryList = new List<BMCServiceDesk__Category__c>();
        Map<String, Id> rootCategoryMap = new Map<String, Id>();


        BMCServiceDesk__Category__c opsRootCategory = new BMCServiceDesk__Category__c(
            name = 'Enterprise Applications', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_EAE_OPS'));
        BMCServiceDesk__Category__c restrictedAccessRootCategory = new BMCServiceDesk__Category__c(
            name = 'Restricted Area Access Parent', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_DataCenter_Access'));
        BMCServiceDesk__Category__c corpITRootCategory = new BMCServiceDesk__Category__c(
            name = 'Corporate IT', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_Helpdesk_Hardware'));
        BMCServiceDesk__Category__c genericRootCategory = new BMCServiceDesk__Category__c(
            name = 'P2R Team', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_DBA'));
        BMCServiceDesk__Category__c hrRootCategory = new BMCServiceDesk__Category__c(
            name = 'HR Questions', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_HR'));
		BMCServiceDesk__Category__c otaRootCategory = new BMCServiceDesk__Category__c(
            name = 'OTA', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_Helpdesk_Hardware'));
        
        BMCServiceDesk__Category__c infosecCategory = new BMCServiceDesk__Category__c(
            name = 'Infosec', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_Infosec'));

        categoryList.add(opsRootCategory);
        categoryList.add(corpITRootCategory);
        categoryList.add(genericRootCategory);
        categoryList.add(restrictedAccessRootCategory);
        categoryList.add(otaRootCategory);
        categoryList.add(infosecCategory);

        insert categoryList;
        for (BMCServiceDesk__Category__c cat : categoryList) {
            rootCategoryMap.put(cat.name, cat.id);
        }



        BMCServiceDesk__Category__c opsChildCategory = new BMCServiceDesk__Category__c(
            name = 'Access', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_EAE_OPS'),
            BMCServiceDesk__FKParentCategory__c = (ID)rootCategoryMap.get('Enterprise Applications'));
        BMCServiceDesk__Category__c corpITChildCategory = new BMCServiceDesk__Category__c(
            name = 'Hardware', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__AvailableForServiceCatalog__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_Helpdesk_Hardware'),
            BMCServiceDesk__FKParentCategory__c = (ID)rootCategoryMap.get('Corporate IT'),
        	BMCServiceDesk__parentTree__c  = 'Corporate IT');

        BMCServiceDesk__Category__c hrChildCategory = new BMCServiceDesk__Category__c(
            name = 'Compensation', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_HR'),
            BMCServiceDesk__FKParentCategory__c = (ID)rootCategoryMap.get('HR Questions'));
        BMCServiceDesk__Category__c genericChildCategory = new BMCServiceDesk__Category__c(
            name = 'P2R', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_DBA'),
            BMCServiceDesk__FKParentCategory__c = (ID)rootCategoryMap.get('P2R Parent'));
        BMCServiceDesk__Category__c restrictedAccessChildCategory = new BMCServiceDesk__Category__c(
            name = 'Restricted Area Access', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_DataCenter_Access'),
            BMCServiceDesk__FKParentCategory__c = (ID)rootCategoryMap.get('Restricted Area Access Parent'));
        BMCServiceDesk__Category__c otaChildCategory = new BMCServiceDesk__Category__c(
            name = 'OTA Child', BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__AvailableForServiceCatalog__c = true,
            BMCServiceDesk__FKCategoryType__c = (ID)categoryTypeMap.get('Q_Helpdesk_Hardware'),
            BMCServiceDesk__FKParentCategory__c = (ID)rootCategoryMap.get('OTA'));

        categoryList.clear();
        categoryList.add(opsChildCategory);
        categoryList.add(corpITChildCategory);
        categoryList.add(genericChildCategory);
        categoryList.add(restrictedAccessChildCategory);
        categoryList.add(hrChildCategory);
        categoryList.add(otaChildCategory);

        insert categoryList;

        for (BMCServiceDesk__Category__c cat : categoryList) {
            rootCategoryMap.put(cat.name, cat.id);
        }

        return rootCategoryMap;

    }

    public static void  createPriorityCustomSettings(){

       if( HD_Ticket_Priority__c.getAll().size() > 0){
        return;
       }
       List<HD_Ticket_Priority__c> ticket_priorities = new List<HD_Ticket_Priority__c>();
       String[] priorities = new List<String> {'1', '2', '3','4','5'};
       for(String s : priorities){
        HD_Ticket_Priority__c c = new HD_Ticket_Priority__c();
        c.Urgency_Id__c = urgencyMap.get('Sev '+s);
        c.priority_id__c =  priorityMap.get(s);
        c.Name =  s;
        ticket_priorities.add(c);

       }

       insert ticket_priorities;

    }

    public static void init() {
        statusMap = insertAllStatus();
        impactMap = createImpact(new List<String> {'LOW'});
        urgencyMap = createUrgency(new List<String> {'Severity 1', 'Severity 2', 'Severity 3', 'Severity 4', 'Severity 5'});
        priorityMap = createPriority();
        categoryMap = createCategories();
        actionMap = createActions();
        createPriorityCustomSettings();
        util();
    }






    public HD_Test_Data_Factory() {
        init();
    }
}