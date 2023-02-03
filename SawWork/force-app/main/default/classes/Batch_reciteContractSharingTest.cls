/**
 * This is to test Batch class Batch_reciteContractSharingTest which is a clean up class used to give sharing to the Account Owner  in Case  if 
 * AccountOwner is not having an access  over the Contracts related to the Account.
 * History:
 * =========================
 * Developer        Date        Description
 * Rahul Gaira     25/07/2014   Created Class(CR-2697069)
 * --------------------------------------------------------------------------------------------------
 **/
@isTest
public class Batch_reciteContractSharingTest{
    static {
        utilTestClass.createCustomSettings();
    }
    
  
  //Use Case When a Single Record  needs to be given Sharing 
    static testmethod void ContractSharing(){
        User u = utilTestClass.testUserCreation('Sales Operations' ,'tmuser1' , 'testuser' ,'stdusr1@akamai.com' , 'user1name@akmai.com.sfdev');
        Id accid = utilTestClass.AccountCreation(u.id ,'testBatchAcc' ,'www.akamai.com');
        //Inserting the Contract
        Merge_Contract_Header__c mchObj = new Merge_Contract_Header__c(Name = 'TestContract' , Account_Name__c = accid);  
        insert mchObj;
        Test.StartTest();
            Batch_reciteContractSharing reciteContractSharing = new Batch_reciteContractSharing();
            ID batchprocessid = Database.executeBatch(reciteContractSharing,200);
        Test.StopTest();
    } 
    
    //Use Case When There is NO Sharing is  there that need to be given to account owner
    static testmethod void AvoidSharingIfpresent(){
        User u = utilTestClass.testUserCreation('Sales Operations' ,'tmuser1' , 'testuser' ,'stdusr1@akamai.com' , 'user1name@akmai.com.sfdev');
        Id accid = utilTestClass.AccountCreation(u.id ,'testBatchAcc' ,'www.akamai.com');
        //Inserting the Contract
        Merge_Contract_Header__c mchObj = new Merge_Contract_Header__c(Name = 'TestContract' , Account_Name__c = accid);  
        insert mchObj;
        //Creating the new User
        User updatedUser = utilTestClass.testUserCreation('Sales Operations' ,'tmuser2' , 'testuser2' ,'stdusr2@akamai.com' , 'user2name@akmai.com.sfdev');
        Account accUpdated = [Select name , Id , OwnerID From Account WHERE Id =: accid ];   
        accUpdated.Ownerid = updatedUser.Id ;
        update accUpdated;
        Test.StartTest();
            Batch_reciteContractSharing reciteContractSharing = new Batch_reciteContractSharing();
            ID batchprocessid = Database.executeBatch(reciteContractSharing,200);
        Test.StopTest();
    } 
    
    //UseCase When The Sharing exception is there
    static testmethod void ContractSharingException(){
        //Creating the User
        User u = utilTestClass.testUserCreation('Sales Operations' ,'tmuser1' , 'testuser' ,'stdusr1@akamai.com' , 'user1name@akmai.com.sfdev');
        Id accid = utilTestClass.AccountCreation(u.id ,'testBatchAcc' ,'www.akamai.com');
        //Inserting the Contract
        Merge_Contract_Header__c mchObj = new Merge_Contract_Header__c(Name = 'TestContract' , Account_Name__c = accid);  
        insert mchObj;
        User standarduser = utilTestClass.testUserCreation('Read Only' ,'Stduser' , 'testStandarduser' ,'standardusr1@akamai.com' , 'user2name@akmai.com.sfdev');
        Test.StartTest();
        System.runAs(standarduser){
            Batch_reciteContractSharing reciteContractSharing = new Batch_reciteContractSharing();
            ID batchprocessid = Database.executeBatch(reciteContractSharing,200);
           } 
        Test.StopTest();
    }
    
    //UseCase When Multiple Contract to single Account
    static testmethod void MultipleContractSharing(){
        User u = utilTestClass.testUserCreation('Sales Operations' ,'tmuser1' , 'testuser' ,'stdusr1@akamai.com' , 'user1name@akmai.com.sfdev');
        Id accid = utilTestClass.AccountCreation(u.id ,'testBatchAcc' ,'www.akamai.com');
        //Inserting the multilpleContract
        utilTestClass.multipleContractCreation(100, accid);
        Test.StartTest();
            Batch_reciteContractSharing reciteContractSharing = new Batch_reciteContractSharing();
            ID batchprocessid = Database.executeBatch(reciteContractSharing,200);
        Test.StopTest();
    } 
}