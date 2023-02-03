//Changes by Sharath Prasanna: for FFPSA-607. Added the logic to improve the code coverage
@isTest(SeeAllData=false)
public class PSA_RRRoutingTriggerTest
{
    public static testMethod void TestRRRoutingTrigger()
    {
     PSA_TestUtility testUtil = new PSA_TestUtility();
     pse__Region__c reg = testUtil.newRegionMaster(true);
     RR_PS_Original_Mapping__c M1 = new RR_PS_Original_Mapping__c();
     RR_PS_Original_Mapping__c M2 = new RR_PS_Original_Mapping__c();
     RR_PS_Original_Mapping__c M3 = new RR_PS_Original_Mapping__c();
     List<RR_PS_Original_Mapping__c> RRPSMappingList = new List<RR_PS_Original_Mapping__c>();
     Test.startTest();
     RRPSMappingList = [select Concatenated_Condition__c,Criteria_Order__c,Receiving_PS_Group__c from RR_PS_Original_Mapping__c order by Criteria_Order__c limit 3]; 
     if(RRPSMappingList != NULL && RRPSMappingList.size()==3)
     {
         M1 = RRPSMappingList[0];
         M2 = RRPSMappingList[1];
         M3 = RRPSMappingList[2];
     
     }
     else
     {
         {
             M1.Concatenated_Condition__c = 'a,X,c,d,e,f,*';
             M1.Criteria_Order__c = 1;
             M1.Receiving_PS_Group__c = 'X';
         }
         {
             M2.Concatenated_Condition__c = 'a,X,c,d,e,h,*';
             M2.Criteria_Order__c = 2;
             M2.Receiving_PS_Group__c = 'Y';       
         }
         {
             M3.Concatenated_Condition__c = 'a,X,c,d,e,f,g';
             M3.Criteria_Order__c = 3;
             M3.Receiving_PS_Group__c = 'Z';       
         }
         List<RR_PS_Original_Mapping__c> RRPSMappingInsertList = new List<RR_PS_Original_Mapping__c>();
         RRPSMappingInsertList.add(M1);
         RRPSMappingInsertList.add(M2);
         RRPSMappingInsertList.add(M3);
         Try
         {
             Database.insert(RRPSMappingInsertList);
         }
        Catch(exception e)
        {
            system.debug('Error in inserting RRPSMappings');
        }
     }
     String Geo_Division1,Geo_Division2,Geo_Division3 ;
     String Region1,Region2,Region3;
     String Territory1,Territory2,Territory3;
     String type1,type2,type3,Subtype1,Subtype2,Subtype3,Product1,Product2,Product3,Role3;
     
     User usr = testUtil.newUserSysAdmin(true);        
     
     Geo_Division1 = M1.Concatenated_Condition__c .split(',',0)[0] + '_' + M1.Concatenated_Condition__c .split(',',0)[1];
     Geo_Division2 = M2.Concatenated_Condition__c .split(',',0)[0] + '_' + M2.Concatenated_Condition__c .split(',',0)[1];
     Geo_Division3 = M3.Concatenated_Condition__c .split(',',0)[0] + '_' + M3.Concatenated_Condition__c .split(',',0)[1];
     Region1 = M1.Concatenated_Condition__c .split(',',0)[1];
     Region2 = M2.Concatenated_Condition__c .split(',',0)[1];
     Region3 = M3.Concatenated_Condition__c .split(',',0)[1];
     Territory1 = (M1.Concatenated_Condition__c .split(',',0)[2]);
     if(Territory1.length()>30)
     {
     Territory1 = (M1.Concatenated_Condition__c .split(',',0)[2]).substring(1,20);
     }
     Territory2 = (M2.Concatenated_Condition__c .split(',',0)[2]);
     if(Territory2.length()>30) 
     {
     Territory2 = (M2.Concatenated_Condition__c .split(',',0)[2]).substring(1,20);
     }
     Territory3 = (M3.Concatenated_Condition__c .split(',',0)[2]); 
     if(Territory3.length()>30)
     {
     Territory3 = (M3.Concatenated_Condition__c .split(',',0)[2]).substring(1,20);
     }
     type1 = M1.Concatenated_Condition__c .split(',',0)[3];
     type2 = M2.Concatenated_Condition__c .split(',',0)[3];
     type3 = M3.Concatenated_Condition__c .split(',',0)[3];
     Subtype1 = M1.Concatenated_Condition__c .split(',',0)[4];
     Subtype2 = M2.Concatenated_Condition__c .split(',',0)[4];
     Subtype3 = M3.Concatenated_Condition__c .split(',',0)[4];
     Product1 = M1.Concatenated_Condition__c .split(',',0)[5];
     Product2 = M2.Concatenated_Condition__c .split(',',0)[5];
     Product3 = M3.Concatenated_Condition__c .split(',',0)[5];
     Role3 = M3.Concatenated_Condition__c .split(',',0)[6];
     Account acct1 = testUtil.newAccountForRR(true,'1',Geo_Division1,Region1,Territory1);  
     Account acct2 = testUtil.newAccountForRR(true,'2',Geo_Division2,Region2,Territory2);    
     Account acct3 = testUtil.newAccountForRR(true,'3',Geo_Division3,Region3,Territory3);  
     Contact resource = testUtil.newResource(true, acct1.Id, usr.Id);
     pse__Permission_Control__c pcontrol = testUtil.newPermissionControl(true,usr.Id,reg.Id);
     pse__Practice__c pract = testUtil.newPracticeMaster(true);
        Id practId = pract.ID;
        //pse__Proj__c templateProj = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);   
        //templateProj.pse__Is_Template__c = true;
        //insert templateProj;  
     pse__Proj__c templateProj1 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct1.Id); 
     pse__Proj__c templateProj2 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct2.Id); 
     pse__Proj__c templateProj3 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct3.Id); 
     List<pse__Proj__c> projects = new List<pse__Proj__c>();
     //Changes by sharath: merged the 3 inserts into 1 statement
     projects.add(templateProj1);
     projects.add(templateProj2);
     projects.add(templateProj3);
       insert projects;
     system.runAs(usr)
     {
     pse__Resource_Request__c rec1 = new pse__Resource_Request__c();
     pse__Resource_Request__c rec2= new pse__Resource_Request__c();
     rec1 = testUtil.newResourceRequestforRR(true, acct1.Id, resource.id, System.today(), System.today().addDays(15), templateProj1.Id, null,reg.Id,type1,subtype1,product1,null); 
     rec2 = testUtil.newResourceRequestforRR(true, acct2.Id, resource.id, System.today(), System.today().addDays(15), templateProj2.Id, null,reg.Id,type2,subtype2,product2,null); 
     pse__Resource_Request__c rec3 = [select Account_Geography__c ,Account_Area__c ,Account_Territory__c ,pse__Request_Priority__c ,Resource_Request_Sub_Type__c ,Product__c ,pse__Resource_Role__c ,Receiving_PS_Group__c from pse__Resource_Request__c where pse__Project__c = :templateProj1.Id order by CreatedDate limit 1][0];
     system.assertequals(rec3.Receiving_PS_Group__c,M1.Receiving_PS_Group__c);
     pse__Resource_Request__c rec4 = [select Account_Geography__c ,Account_Area__c ,Account_Territory__c ,pse__Request_Priority__c ,Resource_Request_Sub_Type__c ,Product__c ,pse__Resource_Role__c ,Receiving_PS_Group__c from pse__Resource_Request__c where pse__Project__c = :templateProj2.Id order by CreatedDate limit 1][0];
     system.assertequals(rec4.Receiving_PS_Group__c,M2.Receiving_PS_Group__c );
     //Changes by Sharath:
     //Set the resource ID and changed the status to Assigned
     rec4.pse__Staffer_Resource__c = resource.id;
     rec4.pse__Status__c = 'Assigned';
     update rec4;
     
    }
    Test.stopTest();
}

}