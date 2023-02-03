/****************************************************************************
* Class name          :   SC_DD_DealPermissions.cls
* Author              :   Vishnu Vardhan
* Created             :   25-February-2020
* Purpose             :   To Grant Deal Desk Application access to DGRAT users
* Test Class          :   SC_DD_DealDeskTest
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
* +recalcDealDeskPermissions (for insert):   Recalculate Permission Set Assignments for SLM/SLD, SLD1, SLD2 users of UserRegion records
* +recalcDealDeskPermissions (for update):   Recalculate Permission Set Assignments for User Regions with updated SLM/SLD, SLD1, SLD2 or DGRAT
DATE             DEVELOPER     CR              DESCRIPTION
===========      =========     =======         ===========

****************************************************************************/
public with sharing class SC_DD_DealPermissions {

    public static final Id DD_USER_REGION_RT = Inv_WorkBox_Region_Mapping__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('DealDesk').getRecordTypeId();
   
    static final String SLM_SLD;
    static final String SLD1;
    static final String SLD2;
    static final String DELIM = ' ';

    // Static Initialization Block
    // Query and Store Permisiion Set IDs - SLM_SLD, SLD1, SLD2
    static
    { 
        for( PermissionSet ps: [select id, Name from permissionset where name in ('SC_DD_SLM', 'SC_DD_SLD')]) {
            if(ps.Name == 'SC_DD_SLM') {
                SLM_SLD = ps.Id;
            }
            else if(ps.Name == 'SC_DD_SLD') {
                SLD1 = ps.Id;
                SLD2 = ps.Id;
            }
        }
    }

    // Queueable Class - Permission Set Assignment is a setup object, hence async processing
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * RecalcPermissionSetAssignments     :   Update Permission Set Assignments
    ****************************************************************************/
    public class RecalcPermissionSetAssignments implements Queueable {

        List<Inv_WorkBox_Region_Mapping__c> newUserRegions;
        Map<Id, Inv_WorkBox_Region_Mapping__c> oldUserRegionMap;
        Set<Id> slmSldSet;
        Set<Id> sld1Set;
        Set<Id> sld2Set;

        public recalcPermissionSetAssignments( Set<Id> slmSldSet, Set<Id> sld1Set, Set<Id> sld2Set) {
            this.slmSldSet = slmSldSet;
            this.sld1Set = sld1Set;
            this.sld2Set = sld2Set;
        }

         /*
            Algo : For Recalculating permission set assignments on User Region Update
                1. Get the SLM, SLD1, SLD2 of the updated User Region records
                    a. Calculate Permissions Set Assignments for SLM, SLD1, SLD2 users of new/ updated/ deleted user region records
                    b. Get existing permissions for updated SLM, SLD1, SLD2 users
                2. compare calculated permission assignments and existing permission assignments
                    a. if existing permission set not in calculated permission set => delete
                    b. if calculated permission set not in existing permission set => insert
            */
        public void execute(QueueableContext context) {
            
            Set<String> calcUserPermissions = new Set<String>();
            Set<String> oldUserPermissions = new Set<String>();

            List<PermissionSetAssignment> toInsertPermAssignments = new List<PermissionSetAssignment>();
            List<PermissionSetAssignment> toDeletePermAssignments = new List<PermissionSetAssignment>();

            for(Inv_WorkBox_Region_Mapping__c ur: [select id, User__c, User__r.ManagerId, User__r.Manager.ManagerId from Inv_WorkBox_Region_Mapping__c
                                                    where   RecordTypeId = :DD_USER_REGION_RT AND Is_Old__c = false AND 
                                                            ( User__c in :slmSldSet OR User__r.ManagerId in :sld1Set OR User__r.Manager.ManagerId in :sld2Set )
                                                        ]) 
            {
                if(this.slmSldSet.contains(ur.User__c)) {
                    calcUserPermissions.add(ur.User__c + DELIM + SLM_SLD);
                }
                if(this.sld1Set.contains(ur.User__r.ManagerId)) {
                    calcUserPermissions.add(ur.User__r.ManagerId + DELIM + SLD1);
                }
                if(this.sld2Set.contains(ur.User__r.Manager.ManagerId)) {
                    calcUserPermissions.add(ur.User__r.Manager.ManagerId + DELIM + SLD2);
                }
            }

            for(PermissionSetAssignment pa: [select id, AssigneeId, PermissionSetId from PermissionSetAssignment where PermissionSetId in (:SLM_SLD, :SLD1, :SLD2) AND 
                                                                ( AssigneeId in :slmSldSet OR AssigneeId in :sld1Set OR AssigneeId in :sld2Set)]) 
            {
                String permKey = pa.AssigneeId + DELIM + pa.PermissionSetId;
                oldUserPermissions.add(permKey);

                // if(!calcUserPermissions.contains(permKey)) {
                //     toDeletePermAssignments.add(pa);
                // }
            }

            for(String calcUsrPerm: calcUserPermissions) {
                if(!oldUserPermissions.contains(calcUsrPerm)) {
                    String userId = calcUsrPerm.substringBefore(DELIM);
                    String permId = calcUsrPerm.substringAfter(DELIM);
                    toInsertPermAssignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permId));
                }
            }

            // delete toDeletePermAssignments;
            insert toInsertPermAssignments;         
        }

    }

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * +recalcDealDeskPermissions :   Recalculate Permission Set Assignments for SLM/SLD, SLD1, SLD2 users of UserRegion records
    * Where Used          : On Insert and Delete triggers
    ****************************************************************************/
    public static void recalcDealDeskPermissions(List<Inv_WorkBox_Region_Mapping__c> userRegions) {
        Set<Id> slmSldSet = new Set<Id>();
        Set<Id> sld1Set = new Set<Id>();
        Set<Id> sld2Set = new Set<Id>();

        for(Inv_WorkBox_Region_Mapping__c newUr: [select id, User__c, User__r.ManagerId, User__r.Manager.ManagerId
                                                    from Inv_WorkBox_Region_Mapping__c where RecordTypeId = :DD_USER_REGION_RT AND Is_Old__c = false AND Id in :userRegions ]) {
            slmSldSet.add(newUr.User__c);
            sld1Set.add(newUr.User__r.ManagerId);
            sld2Set.add(newUr.User__r.Manager.ManagerId);
        }
        if(slmSldSet.size() > 0 || sld1Set.size() > 0 || sld2Set.size() > 0) {
            System.enqueueJob(new RecalcPermissionSetAssignments(slmSldSet, sld1Set, sld2Set)); 
        }
    }

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * +recalcDealDeskPermissions :   Recalculate Permission Set Assignments for User Regions with updated SLM/SLD, SLD1, SLD2 or DGRAT
    * Where Used          : On Update trigger
    ****************************************************************************/
    public static void recalcDealDeskPermissions(List<Inv_WorkBox_Region_Mapping__c> newUserRegions, Map<Id, Inv_WorkBox_Region_Mapping__c> oldUserRegionMap) {
        Set<Id> slmSldSet = new Set<Id>();
        Set<Id> sld1Set = new Set<Id>();
        Set<Id> sld2Set = new Set<Id>();

        for(Inv_WorkBox_Region_Mapping__c newUr: newUserRegions) {
            
            Inv_WorkBox_Region_Mapping__c oldUr = oldUserRegionMap.get(newUr.Id);
            if(newUr.User__c != oldUr.User__c) {
                slmSldSet.add(newUr.User__c);
                slmSldSet.add(oldUr.User__c);
            }
        }

        for(User usr: [select id, ManagerId, Manager.ManagerId from User where Id in :slmSldSet]) {
            sld1Set.add(usr.ManagerId);
            sld2Set.add(usr.Manager.ManagerId);
        }

        if(slmSldSet.size() > 0 || sld1Set.size() > 0 || sld2Set.size() > 0) {
            System.enqueueJob(new RecalcPermissionSetAssignments(slmSldSet, sld1Set, sld2Set));
        }
    }
}