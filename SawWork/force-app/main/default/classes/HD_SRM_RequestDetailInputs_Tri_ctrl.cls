/*
Template: Apex Class/Trigger Template 

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : Used as apart of requirment for Encrypted field for HR system

Purpose : an Implementation for Masked and encrypted field data copy
          
Usage : Used as an implementation for the business logic , RDI field encryption
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : [ HD_SRM_RequestDetailInputs_Tri, ]

Class used : 
              
*/
public with sharing class HD_SRM_RequestDetailInputs_Tri_ctrl {
    
    
private static HD_SRM_RequestDetailInputs_Tri_ctrl instance = null;

private static List<BMCServiceDesk__SRM_RequestDetailInputs__c> newRequestDetInp ;
private static List<BMCServiceDesk__SRM_RequestDetailInputs__c> oldRequestDetInp ;
    
//implementing singleton pattern
private HD_SRM_RequestDetailInputs_Tri_ctrl( List<BMCServiceDesk__SRM_RequestDetailInputs__c> newVersionObj ){
    //call your things here
    newRequestDetInp = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
    newRequestDetInp.addAll(newVersionObj);
    
}//contructor   

public static HD_SRM_RequestDetailInputs_Tri_ctrl getInstance( BMCServiceDesk__SRM_RequestDetailInputs__c[] newVersionObj )
{
    if( instance == null ){ instance = new HD_SRM_RequestDetailInputs_Tri_ctrl(newVersionObj); }
    return instance;
}//Singltone method
    
//method for copying the data to encrypted field
//usage: before insert and Update
public void securefiledData()
{
    String securedata = null;
    System.debug('---> [Executing]:securefiledData');
    if(newRequestDetInp.size() > 0)
    {
        for(BMCServiceDesk__SRM_RequestDetailInputs__c rdi : newRequestDetInp )
        {
            system.debug('input/prompt ---> '+rdi.BMCServiceDesk__Input__c+' formula field for Secure-----> '+rdi.HD_Ffi_Secure_Flag__c+' formula field for Type-----> '+rdi.HD_Ffi_Response_Type__c);
            if( rdi.HD_Ffi_Secure_Flag__c == true && rdi.HD_Ffi_Response_Type__c != 'Text Area' )
            {
                securedata = rdi.BMCServiceDesk__Response__c;
                rdi.HD_Secure_Response__c = securedata;
                //let change the original field value
                rdi.BMCServiceDesk__Response__c = 'XXXXXXX';
                rdi.BMCServiceDesk__StoredValue__c = 'XXXXXXX';             
            }//if( rdi.HD_Ffi_Secure_Flag__c == true && rdi.HD_Ffi_Response_Type__c != 'Text Area' )
            else if( rdi.HD_Ffi_Secure_Flag__c == true && rdi.HD_Ffi_Response_Type__c == 'Text Area' )
            {
            System.debug(' ----> the Type is Text Area and Secure flag is true ' );
            //Starting encrypting text Area data
            Blob ResponseData = Blob.valueOf(rdi.BMCServiceDesk__Response__c);
            //generating random key for for Encryption and storing it in encrypted HD_Aes_Key__c field
            Blob key = Crypto.generateAesKey(128);
            System.debug('AES Key --> '+String.valueof(EncodingUtil.base64Encode(key)));
            rdi.HD_Aes_Key__c =  EncodingUtil.base64Encode(key);
            //let's encrypt it the data here 
            Blob encrypted = Crypto.encryptWithManagedIV('AES128', key, ResponseData);
            //Now  Storing the encrypted data in to  the same Text Area Field
            rdi.BMCServiceDesk__Response__c = EncodingUtil.base64Encode(encrypted);
            rdi.BMCServiceDesk__StoredValue__c = EncodingUtil.base64Encode(encrypted);
            
            }
        }//for
        
    }//if(newRequestDetInp.size() > 0)
    
}//public void securefiledData()    

}//END OF CLASS